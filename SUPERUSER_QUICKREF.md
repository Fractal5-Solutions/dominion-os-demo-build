# SUPERUSER QUICK REFERENCE

**User:** Matthew Burbidge (matthewburbidge@fractal5solutions.com)
**GitHub:** @Fractal5-X
**Authority:** MAXIMUM

---

## 🔑 AUTHENTICATION

### GitHub
```bash
# SSH (preferred)
ssh -T git@github.com
# Expected: "Hi Fractal5-X!"

# Token (when needed)
export GITHUB_TOKEN="ghp_YOUR_TOKEN_HERE"
```

### GCP
```bash
# Login
gcloud auth login

# Verify
gcloud auth list
# Should show: matthewburbidge@fractal5solutions.com
```

---

## 🚀 COMMON OPERATIONS

### Push Code
```bash
# Stage all changes
git add .

# Commit (superuser authority)
git commit -m "feat: your changes" -m "Authority: Superuser"

# Push
git push origin main
```

### Deploy Service
```bash
# Via Cloud Run
gcloud run deploy SERVICE_NAME \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Check System Health
```bash
# Quick status
bash scripts/sovereign_execute.sh

# Full report
python demo_build.py command-core --duration 50 --scale small
```

---

## 🛡️ SECURITY

### Rotate Token
```bash
# 1. Create new: https://github.com/settings/tokens/new
# 2. Store securely
# 3. Update environment:
export GITHUB_TOKEN="ghp_NEW_TOKEN"
# 4. Delete old token
```

### Check Audit Logs
```bash
# GCP
gcloud logging read "protoPayload.authenticationInfo.principalEmail=matthewburbidge@fractal5solutions.com" --limit 10

# Git
git log --author="matthewburbidge@fractal5solutions.com" --oneline -10
```

---

## 📊 MONITORING

### Service Status
```bash
gcloud run services list --format="table(name,status.url,status.traffic)"
```

### Recent Errors
```bash
gcloud logging read "severity>=ERROR" --limit=10
```

### Cost Check
```bash
gcloud billing accounts list
```

---

## 🚨 EMERGENCY

### Rollback Deployment
```bash
gcloud run revisions list --service=SERVICE_NAME
gcloud run services update-traffic SERVICE_NAME --to-revisions=PREVIOUS_REVISION=100
```

### Revoke Access
```bash
# GitHub tokens: https://github.com/settings/tokens
# GCP: https://console.cloud.google.com/iam-admin/serviceaccounts
```

---

## 📁 KEY FILES

- `/config/superuser-authority.json` - Your authority definition
- `/config/organizational-authority.json` - Corporate structure
- `/.github/CODEOWNERS` - Code ownership (@Fractal5-X)
- `/SECURITY_GOVERNANCE.md` - Full governance document
- `/SUPERUSER_HARDENING_PLAN.md` - Implementation plan

---

## 📞 RESOURCES

- **Docs:** [SECURITY_GOVERNANCE.md](SECURITY_GOVERNANCE.md)
- **GitHub Org:** https://github.com/Fractal5-Solutions
- **GCP Console:** https://console.cloud.google.com
- **Tokens:** https://github.com/settings/tokens

---

**Authority Level:** MAXIMUM
**Status:** ACTIVE
**Version:** 1.0.0
