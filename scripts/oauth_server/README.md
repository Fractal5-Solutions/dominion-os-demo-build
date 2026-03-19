# PHI Chief AI - AskPhi OAuth Server

Secure OAuth 2.0 implementation for the AskPhi widget with PKCE (Proof Key for Code Exchange).

## Setup

1. **Create GitHub OAuth App:**
   - Go to: <https://github.com/settings/applications/new>
   - Application name: "PHI Chief AI - AskPhi"
   - Homepage URL: `https://your-domain.com`
   - Authorization callback URL: `https://your-domain.com/auth/callback`
   - Copy Client ID and Client Secret

2. **Configure Environment:**

   ```bash
   cp .env.example .env
   # Edit .env with your GitHub OAuth credentials
   ```

3. **Install Dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Run Server:**

   ```bash
   python app.py
   ```

## Security Features

- OAuth 2.0 Authorization Code Flow with PKCE
- JWT token authentication
- Organization-based authorization
- CSRF protection with state parameter
- Secure session management
- HTTPS enforcement in production

## API Endpoints

- `GET /` - AskPhi widget interface
- `GET /auth/github` - Initiate GitHub OAuth
- `GET /auth/callback` - OAuth callback handler
- `GET /chat` - PHI Chief AI chat interface
- `POST /api/chat` - PHI Chief AI chat API

## Live Ops Optimization

- Rate limiting enabled via Flask-Limiter for all critical endpoints
- Logging for authentication, errors, and chat events
- CORS restricted for production environments
- JWT secret loaded securely from environment in production
- HTTPS enforced for all redirects in production

## Production Deployment

- Use a WSGI server (e.g., gunicorn, eventlet, uvicorn) for optimal performance
- Example:

  ```bash
  gunicorn -w 4 -b 0.0.0.0:5000 app:app
  ```

- Set ENV=production and configure JWT_SECRET in environment

## Testing

- Test OAuth flow with GitHub and ensure organization-based access
- Test chat API for rate limiting and error handling
- Review logs for authentication and chat events

## Cloud Integration

- Compatible with GCloud Run, Azure Container Apps, and Docker Desktop Pro
- Ensure environment variables are set for each platform
