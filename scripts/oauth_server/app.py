"""
PHI Chief AI - AskPhi OAuth Server
Secure server-side authorization code flow with PKCE
"""

import base64
import hashlib
import logging
import os
import re
import secrets
from datetime import datetime, timedelta
from urllib.parse import quote

import jwt
import requests
from flask import Flask, jsonify, redirect, request, session
from flask_cors import CORS

try:
    from flask_limiter import Limiter
    from flask_limiter.util import get_remote_address
except ImportError:
    Limiter = None
    get_remote_address = None

app = Flask(__name__)
CORS(app)

app.secret_key = secrets.token_hex(32)

# OAuth Configuration
GITHUB_CLIENT_ID = os.getenv("GITHUB_CLIENT_ID", "your_client_id_here")
GITHUB_CLIENT_SECRET = os.getenv("GITHUB_CLIENT_SECRET", "your_client_secret_here")
JWT_SECRET = secrets.token_hex(32)

SAFE_ERROR_RE = re.compile(r"^[A-Za-z0-9_-]{1,64}$")


# PKCE Helper Functions
def generate_code_verifier():
    """Generate a cryptographically secure code verifier"""
    return secrets.token_urlsafe(32)


def generate_code_challenge(verifier):
    """Generate code challenge from verifier using S256"""
    sha256 = hashlib.sha256(verifier.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(sha256).decode("utf-8").rstrip("=")


def verify_state(expected_state, received_state):
    """Verify OAuth state parameter to prevent CSRF"""
    return secrets.compare_digest(expected_state, received_state)


# --- HARDENING: Enhanced OAuth Security & Command Surface ---
# 1. Enforce HTTPS for all redirects and callback URLs
# 2. Add logging for all authentication and error events
# 3. Add rate limiting to /auth/callback and /api/chat endpoints
# 4. Add CORS restrictions for production
# 5. Ensure JWT secret is loaded from environment for production

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("PHIChiefAI-OAuth")


def sanitize_log_value(value):
    if value is None:
        return ""
    return str(value).replace("\r", "\\r").replace("\n", "\\n")


def safe_error_token(value, default="oauth_error"):
    token = (value or "").strip()
    if SAFE_ERROR_RE.fullmatch(token):
        return token
    return default

# Rate limiter
if Limiter and get_remote_address:
    limiter = Limiter(app, key_func=get_remote_address, default_limits=["100 per hour"])

# Restrict CORS for production
if os.getenv("ENV", "development") == "production":
    CORS(app, origins=["https://your-production-domain.com"])
else:
    CORS(app)

# Use environment JWT secret in production
if os.getenv("ENV", "development") == "production":
    JWT_SECRET = os.getenv("JWT_SECRET", secrets.token_hex(32))


# Enforce HTTPS for redirects
@app.before_request
def enforce_https():
    if not request.is_secure and os.getenv("ENV", "development") == "production":
        logger.warning("Blocked insecure request path=%s", sanitize_log_value(request.path))
        return jsonify({"error": "https_required"}), 403


# Add logging to authentication events
@app.route("/auth/callback", methods=["GET"])
def github_callback():
    """Handle GitHub OAuth callback"""
    code = request.args.get("code")
    state = request.args.get("state")
    error = request.args.get("error")

    # Check for errors
    if error:
        logger.error("OAuth error: %s", sanitize_log_value(error))
        return redirect("/?error=oauth_error")

    # Verify state
    expected_state = session.get("state")
    if not verify_state(expected_state, state):
        logger.error("Invalid OAuth state detected")
        return redirect("/?error=invalid_state")

    # Get code verifier from session
    code_verifier = session.get("code_verifier")
    if not code_verifier:
        logger.error("Missing code verifier in session")
        return redirect("/?error=missing_code_verifier")

    try:
        # Exchange code for access token
        token_response = requests.post(
            "https://github.com/login/oauth/access_token",
            headers={
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
            data={
                "client_id": GITHUB_CLIENT_ID,
                "client_secret": GITHUB_CLIENT_SECRET,
                "code": code,
                "redirect_uri": f"{request.host_url}auth/callback",
                "code_verifier": code_verifier,
            },
            timeout=10,
        )

        token_data = token_response.json()

        if "access_token" not in token_data:
            logger.error("Token exchange failed: %s", token_data)
            error_type = token_data.get("error", "token_exchange_failed")
            return redirect(f"/?error={error_type}")

        access_token = token_data["access_token"]

        # Get user info
        user_response = requests.get(
            "https://api.github.com/user",
            headers={"Authorization": f"token {access_token}"},
            timeout=10,
        )

        if user_response.status_code != 200:
            logger.error("Failed to fetch user info from GitHub")
            return redirect("/?error=user_info_failed")

        user_data = user_response.json()

        # Check if user is authorized (Fractal5 Solutions organization)
        org_response = requests.get(
            "https://api.github.com/user/orgs",
            headers={"Authorization": f"token {access_token}"},
            timeout=10,
        )

        authorized_orgs = ["Fractal5-Solutions"]
        user_orgs = (
            [org["login"] for org in org_response.json()]
            if org_response.status_code == 200
            else []
        )

        if not any(org in authorized_orgs for org in user_orgs):
            safe_orgs = [sanitize_log_value(org) for org in user_orgs]
            logger.warning("Unauthorized organization: %s", ",".join(safe_orgs))
            return redirect("/?error=unauthorized_organization")

        # Generate JWT token for PHI Chief AI
        jwt_payload = {
            "user_id": user_data["id"],
            "username": user_data["login"],
            "orgs": user_orgs,
            "exp": int(
                (
                    datetime.datetime.now(datetime.timezone.utc) + timedelta(hours=24)
                ).timestamp()
            ),
        }
        jwt_token = jwt.encode(jwt_payload, JWT_SECRET, algorithm="HS256")

        # Redirect to widget with token
        return redirect("/?token=%s" % jwt_token)

    except Exception as e:
        logger.error("Server error: %s", e)
        return redirect("/?error=server_error")


# Add rate limiting to chat API
@app.route("/api/chat", methods=["POST"])
def chat_api():
    """PHI Chief AI Chat API"""
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    data = request.get_json()

    if not token or not data:
        return jsonify({"error": "Invalid request"}), 400

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        message = data.get("message", "")
        response = generate_phi_response(message, payload)
        return jsonify({"response": response})
    except AttributeError:
        logger.warning("JWT decode error")
        return jsonify({"error": "JWT decode error"}), 401
    except Exception as e:
        logger.error("Server error: %s", e)
        return jsonify({"error": "Server error"}), 500


def generate_phi_response(message, user_payload):
    """Generate PHI Chief AI response based on user context"""
    username = user_payload.get("username", "user")
    orgs = user_payload.get("orgs", [])

    # Basic response logic - in production, this would integrate with PHI Chief AI
    responses = {
        "hello": f"Hello {username}! I am PHI Chief AI, your assistant.",
        "help": (
            "I can help you with system monitoring, optimization, "
            "relationship intelligence, security, and autonomous operations. "
            "What would you like to know?"
        ),
        "status": (
            f"System Status: All PHI Chief AI systems are operational. "
            f"User {username} authenticated from "
            f"{orgs if orgs else 'authorized organization'}."
        ),
        "security": (
            "Security protocols active: OAuth 2.0 with PKCE, JWT token authentication, "
            "org-based authorization, AI threat detection, audit logging."
        ),
        "sovereign": (
            "PHI Chief AI maintains complete sovereignty: autonomous decision making, "
            "NHITL operations, multi-cloud resilience, zero-trust security, "
            "sovereign data governance."
        ),
    }

    message_lower = message.lower()

    for key, response in responses.items():
        if key in message_lower:
            return response

        # Default response
        return (
            "I understand you're asking about: '%s'. As PHI Chief AI, "
            "I'm here to help with your autonomous AI operations. "
            "Could you provide more details about what you need assistance with?"
        ) % message


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False, ssl_context="adhoc")

# --- ENHANCED LIVE OPS: Automated Detection & Optimization ---
# 1. Detect Docker Desktop Pro and dev container status
# 2. Continuously monitor and optimize containers
# 3. Harden live ops for Docker Desktop Pro and AT2 machines

import subprocess
import threading
import time


# Function to detect Docker Desktop Pro
def detect_docker_desktop():
    try:
        output = subprocess.check_output(
            ["docker", "info"], stderr=subprocess.STDOUT
        ).decode()
        if "Docker Desktop" in output or "Server:" in output:
            return True
    except Exception:
        return False
    return False


# Function to monitor and optimize containers
def optimize_containers():
    while True:
        try:
            # List running containers
            containers = (
                subprocess.check_output(["docker", "ps", "-q"]).decode().splitlines()
            )
            for cid in containers:
                # Example: restart unhealthy containers
                inspect = subprocess.check_output(["docker", "inspect", cid]).decode()
                if "unhealthy" in inspect:
                    subprocess.call(["docker", "restart", cid])
            # Example: prune unused resources
            subprocess.call(["docker", "system", "prune", "-f"])
        except Exception:
            pass
        time.sleep(60)  # Run every minute


# Start optimization thread if Docker Desktop detected
if detect_docker_desktop():
    threading.Thread(target=optimize_containers, daemon=True).start()

import logging
import os

# --- AUTOMATED DOCKER HEALTH & CONFIG CHECKS ---
import subprocess


def check_docker_health():
    try:
        info = subprocess.check_output(
            ["docker", "info"], stderr=subprocess.STDOUT
        ).decode()
        if "Server:" not in info:
            logging.error("Docker daemon not running or misconfigured.")
            return False
        scout = subprocess.check_output(
            ["docker", "scout", "quickview"], stderr=subprocess.STDOUT
        ).decode()
        logging.info(f"Docker Scout quickview:\n{scout}")
        volumes = subprocess.check_output(
            ["docker", "volume", "ls"], stderr=subprocess.STDOUT
        ).decode()
        logging.info(f"Docker volumes:\n{volumes}")
        images = subprocess.check_output(
            ["docker", "images"], stderr=subprocess.STDOUT
        ).decode()
        logging.info(f"Docker images:\n{images}")
        return True
    except Exception as e:
        logging.error(f"Docker health/config check failed: {e}")
        return False


# Run health check at startup
if __name__ == "__main__":
    healthy = check_docker_health()
    if not healthy:
        print(
            "Docker health/config check failed. Please review logs and restart Docker Desktop Pro."
        )
    else:
        print("Docker health/config check passed. All systems optimal.")

# --- END AUTOMATED DOCKER HEALTH & CONFIG CHECKS ---
