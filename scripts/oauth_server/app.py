"""
PHI Chief AI - AskPhi OAuth Server
Secure server-side authorization code flow with PKCE
"""

from flask import Flask, request, jsonify, redirect, session, render_template_string
from flask_cors import CORS
import secrets
import hashlib
import base64
import requests
import os
from datetime import datetime, timedelta
import jwt

app = Flask(__name__)
CORS(app)

# Configuration
app.secret_key = os.environ.get('SECRET_KEY', 'phi-sovereign-key-2026')
GITHUB_CLIENT_ID = os.environ.get('GITHUB_CLIENT_ID', 'your-github-client-id')
GITHUB_CLIENT_SECRET = os.environ.get('GITHUB_CLIENT_SECRET', 'your-github-client-secret')
JWT_SECRET = os.environ.get('JWT_SECRET', 'phi-jwt-secret-2026')

# GitHub OAuth URLs
GITHUB_AUTH_URL = 'https://github.com/login/oauth/authorize'
GITHUB_TOKEN_URL = 'https://github.com/login/oauth/access_token'
GITHUB_USER_URL = 'https://api.github.com/user'

@app.route('/')
def home():
    return jsonify({
        'status': 'PHI OAuth Server Active',
        'sovereignty_level': '9/9',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/auth/github')
def github_auth():
    """Initiate GitHub OAuth flow with PKCE"""
    # Generate PKCE code verifier and challenge
    code_verifier = secrets.token_urlsafe(32)
    code_challenge = base64.urlsafe_b64encode(
        hashlib.sha256(code_verifier.encode()).digest()
    ).decode().rstrip('=')

    # Store in session
    session['code_verifier'] = code_verifier
    session['state'] = secrets.token_urlsafe(16)

    # GitHub OAuth parameters
    params = {
        'client_id': GITHUB_CLIENT_ID,
        'redirect_uri': request.host_url.rstrip('/') + '/auth/callback',
        'scope': 'read:user user:email',
        'state': session['state'],
        'code_challenge': code_challenge,
        'code_challenge_method': 'S256'
    }

    auth_url = GITHUB_AUTH_URL + '?' + '&'.join([f'{k}={v}' for k, v in params.items()])
    return redirect(auth_url)

@app.route('/auth/callback')
def github_callback():
    """Handle GitHub OAuth callback"""
    code = request.args.get('code')
    state = request.args.get('state')
    error = request.args.get('error')

    if error:
        return jsonify({'error': error, 'message': 'OAuth authentication failed'}), 400

    if not code or state != session.get('state'):
        return jsonify({'error': 'invalid_request', 'message': 'Invalid OAuth callback'}), 400

    # Exchange code for access token
    token_data = {
        'client_id': GITHUB_CLIENT_ID,
        'client_secret': GITHUB_CLIENT_SECRET,
        'code': code,
        'redirect_uri': request.host_url.rstrip('/') + '/auth/callback',
        'code_verifier': session.get('code_verifier')
    }

    try:
        token_response = requests.post(GITHUB_TOKEN_URL, data=token_data, headers={
            'Accept': 'application/json'
        })

        if token_response.status_code != 200:
            return jsonify({'error': 'token_exchange_failed', 'message': 'Failed to exchange code for token'}), 500

        token_json = token_response.json()
        access_token = token_json.get('access_token')

        if not access_token:
            return jsonify({'error': 'no_access_token', 'message': 'No access token received'}), 500

        # Get user info
        user_response = requests.get(GITHUB_USER_URL, headers={
            'Authorization': f'token {access_token}',
            'Accept': 'application/json'
        })

        if user_response.status_code != 200:
            return jsonify({'error': 'user_info_failed', 'message': 'Failed to get user information'}), 500

        user_data = user_response.json()

        # Create JWT token
        jwt_payload = {
            'user_id': user_data['id'],
            'login': user_data['login'],
            'name': user_data.get('name'),
            'email': user_data.get('email'),
            'avatar_url': user_data.get('avatar_url'),
            'sovereignty_level': '9/9',
            'exp': datetime.utcnow() + timedelta(hours=24),
            'iat': datetime.utcnow(),
            'iss': 'phi-oauth-server'
        }

        jwt_token = jwt.encode(jwt_payload, JWT_SECRET, algorithm='HS256')

        # Clear session
        session.clear()

        # Redirect to AskPhi widget with token
        redirect_url = os.environ.get('ASKPHI_WIDGET_URL', 'https://phi-askphi-widget-reduwyf2ra-uc.a.run.app')
        return redirect(f'{redirect_url}/?token={jwt_token}')

    except Exception as e:
        return jsonify({'error': 'server_error', 'message': str(e)}), 500

@app.route('/verify')
def verify_token():
    """Verify JWT token"""
    token = request.args.get('token')
    if not token:
        return jsonify({'valid': False, 'error': 'No token provided'}), 400

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return jsonify({
            'valid': True,
            'user': {
                'id': payload['user_id'],
                'login': payload['login'],
                'name': payload.get('name'),
                'sovereignty_level': payload.get('sovereignty_level', '1/9')
            }
        })
    except jwt.ExpiredSignatureError:
        return jsonify({'valid': False, 'error': 'Token expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'valid': False, 'error': 'Invalid token'}), 401

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'sovereignty_level': '9/9'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)