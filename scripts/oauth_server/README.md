# PHI OAuth Server

Secure OAuth 2.0 authentication server for PHI and Dominion OS ecosystem.

## Features

- GitHub OAuth integration
- Secure token management
- Token refresh and revocation
- Rate limiting and DDoS protection
- Comprehensive security headers
- Health monitoring endpoints

## Deployment

### Google Cloud Run

```bash
gcloud run deploy phi-oauth-server \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ENVIRONMENT=production
```

### Environment Variables

Required:
- `GITHUB_CLIENT_ID` - GitHub OAuth App Client ID
- `GITHUB_CLIENT_SECRET` - GitHub OAuth App Client Secret
- `JWT_SECRET_KEY` - Secret key for JWT signing
- `ALLOWED_ORIGINS` - Comma-separated list of allowed CORS origins

Optional:
- `ENVIRONMENT` - Environment name (default: development)
- `LOG_LEVEL` - Logging level (default: INFO)
- `REDIS_URL` - Redis connection URL for session storage

## Security

- All tokens are stored securely using Secret Manager
- Rate limiting prevents abuse
- CORS configured for trusted origins only
- Security headers protect against common attacks
- Comprehensive logging for audit trails

## API Endpoints

### Authentication
- `GET /auth/github` - Initiate GitHub OAuth flow
- `GET /auth/callback` - OAuth callback handler
- `POST /auth/refresh` - Refresh access token
- `POST /auth/revoke` - Revoke token

### Health & Monitoring
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python app.py
```

## Architecture

```
┌──────────┐      ┌────────────────┐      ┌─────────┐
│  Client  │─────▶│  OAuth Server  │─────▶│ GitHub  │
└──────────┘      └────────────────┘      └─────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │Secret Manager│
                  └──────────────┘
```

## License

Proprietary - Fractal5 Solutions
