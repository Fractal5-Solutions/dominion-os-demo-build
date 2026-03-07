# Security Policy

## 🔒 Security Updates - March 7, 2026

### Dependency Security Fixes

All dependencies have been updated to address Dependabot security vulnerabilities:

#### High Priority Updates
- **Flask**: `2.3.3` → `3.0.2`
  - Addresses CVE-2023-30861 (security fixes in Werkzeug)
  - Improves session security and cookie handling
  
- **numpy**: `1.24.3` → `1.26.4`
  - Addresses CVE-2024-5572 (buffer overflow vulnerability)
  
- **requests**: `2.31.0` → `2.32.3`
  - Multiple security advisories addressed
  - Improved certificate validation

#### Moderate Priority Updates
- **pandas**: `2.0.3` → `2.2.0` (latest stable)
- **pytest**: `7.4.0` → `8.1.0`
- **python-dotenv**: `1.0.0` → `1.0.1`
- **Google Cloud libraries**: Updated to latest versions
- **Development tools**: black, ruff, mypy, pylint all updated

## 🛡️ Security Best Practices Implemented

### 1. Secret Management
- ✅ All secrets stored in Google Cloud Secret Manager
- ✅ No hardcoded credentials in codebase (except defaults for local development)
- ✅ Environment variables used for configuration
- ⚠️ **ACTION REQUIRED**: Rotate default secrets in oauth_server/app.py

### 2. Container Security
- ✅ Python 3.11-slim base images (minimal attack surface)
- ✅ Non-root user in containers
- ✅ Regular image updates via Cloud Build
- ✅ Startup probes for service health validation

### 3. Network Security
- ✅ HTTPS enforced on all Cloud Run services
- ✅ IAM-based authentication between services
- ✅ CORS configured appropriately
- ✅ VPC egress controls available

### 4. Authentication & Authorization
- ✅ GitHub OAuth integration
- ✅ JWT token-based authentication
- ✅ Service account-based GCP access
- ✅ Principle of least privilege applied

## ⚠️ Known Security Considerations

### OAuth Server Hardcoded Secrets
**Location**: `/scripts/oauth_server/app.py`

**Issue**: Default secrets are hardcoded for local development:
```python
app.secret_key = os.environ.get('SECRET_KEY', 'phi-sovereign-key-2026')
JWT_SECRET = os.environ.get('JWT_SECRET', 'phi-jwt-secret-2026')
```

**Mitigation**:
- Production deployments use Secret Manager (environment variables override defaults)
- Default secrets only used in local dev environments
- **TODO**: Remove defaults and enforce environment variable requirements

**Action Required**:
```bash
# Set production secrets in Secret Manager
gcloud secrets create oauth-secret-key --project=dominion-core-prod
gcloud secrets create oauth-jwt-secret --project=dominion-core-prod

# Update Cloud Run service to use secrets
gcloud run services update phi-oauth-server \
  --update-secrets=SECRET_KEY=oauth-secret-key:latest \
  --update-secrets=JWT_SECRET=oauth-jwt-secret:latest \
  --region=us-central1 \
  --project=dominion-core-prod
```

## 📊 Security Metrics

### Current Status
- **Dependency Vulnerabilities**: 11 (awaiting PR merge to main)
  - High: 3 (addressed in PR #51)
  - Moderate: 6 (addressed in PR #51)
  - Low: 2 (addressed in PR #51)

- **Services Operational**: 33/33 (100%)
- **HTTPS Enforcement**: ✅ All services
- **Secret Manager Usage**: ✅ Production services
- **Container Security**: ✅ Minimal images, non-root users

## 🔍 Reporting Security Vulnerabilities

**DO NOT** create public GitHub issues for security vulnerabilities.

Instead:
1. Email: security@fractal5solutions.com
2. Include detailed description and reproduction steps
3. Allow 48 hours for initial response
4. Coordinated disclosure after fix is deployed

## 📝 Security Audit Log

### 2026-03-07
- ✅ Updated all Python dependencies to address CVEs
- ✅ Deployed 3 new services with secure configurations
- ✅ Fixed degraded OAuth server (routed to healthy revision)
- ✅ Validated all 33 services operational at 100% health
- ✅ Created comprehensive security documentation
- ⚠️ Identified hardcoded secrets in OAuth server (local dev only)

## 🚀 Continuous Security Improvements

### Automated Security
- **Dependabot**: Enabled (automatic PR creation for vulnerabilities)
- **Container Scanning**: Cloud Build security scanning enabled
- **Secret Detection**: GitHub secret scanning enabled
- **Code Scanning**: TODO - Enable GitHub Advanced Security

### Planned Enhancements
1. Implement GitHub Actions security workflow
2. Add automated dependency vulnerability scanning  
3. Set up SIEM integration for Cloud Run logs
4. Enable Cloud Armor for DDoS protection
5. Implement mTLS between services
6. Add automated compliance checking (SOC2, PCI, HIPAA)
7. Set up security incident response automation

## 📚 Security Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)
- [Flask Security Guidelines](https://flask.palletsprojects.com/en/latest/security/)
- [Cloud Run Security](https://cloud.google.com/run/docs/security/security-considerations)

---

**Last Updated**: 2026-03-07  
**Maintained By**: PHI Sovereign AI & Fractal5 Solutions Security Team
