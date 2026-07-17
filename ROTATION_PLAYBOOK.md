Rotation Playbook — Automated remediation steps

This document describes automated and manual steps to rotate leaked credentials and update deployment secrets.

Overview
- Rotate database passwords (Postgres).
- Revoke and replace API keys (GitHub PATs, Stripe keys, third-party APIs).
- Update runtime secret stores (GitHub Actions Secrets, Vault, Secret Manager).
- Notify maintainers and rotate any consumer credentials.

Automatic runner
- A GitHub Actions workflow (`.github/workflows/rotate-secrets.yml`) is included and can be triggered manually.
- The workflow expects admin-level secrets to be present in the repository or organization (see below).

Required secrets for automated rotation
- `GH_ADMIN_TOKEN`: a GitHub token with `repo` and `actions:write` scopes (to update repo secrets). Optional for storing rotated values.
- `POSTGRES_ADMIN_DSN`: a Postgres DSN that can ALTER users, e.g. `postgresql://admin:adminpass@db-host:5432/postgres`.
- `STRIPE_MANAGEMENT_KEY`: (optional) Stripe secret key to revoke/create API keys if your Stripe plan and API support it.

Postgres rotation (manual)
1. Back up database configuration and ensure you have an alternate connection.
2. Generate a new strong password: `python -c "import secrets; print(secrets.token_urlsafe(24))"`.
3. Run as a DB admin:
   psql "host=<host> port=<port> dbname=<db> user=<admin> password=<adminpass>" -c "ALTER ROLE phi_admin WITH PASSWORD '<newpass>';"
4. Update runtime secrets (GitHub Actions secrets, environment, secret manager) with the new password.
5. Redeploy services using the new secret.

GitHub PAT rotation (manual)
1. Revoke any exposed personal access token via GitHub web UI: Settings → Developer settings → Personal access tokens.
2. If the repo uses a machine user or bot token, revoke and recreate the token in the organization's account.
3. Update repository/organization secrets with the new token.
4. Re-run CI and deployments.

Stripe key rotation (manual)
1. In Stripe dashboard, revoke the compromised key and create a new key.
2. Update runtime secret stores with the new key.
3. Confirm webhook signing secret and update webhook configuration.

Automated workflow usage
1. Add the admin secrets (`GH_ADMIN_TOKEN`, `POSTGRES_ADMIN_DSN`, etc.) to repository secrets.
2. From Actions → Workflows → "Rotate leaked secrets" → Run workflow (manual dispatch).
3. The workflow will rotate the Postgres user password and attempt to store the new value in the repository secrets (if `GH_ADMIN_TOKEN` is provided).

Notes
- For irreversible history rewrite we already prepared and force-pushed a cleaned mirror for the primary branches. All contributors must re-clone the repository after history rewrite.
- Do NOT reuse leaked tokens. Rotate and revoke immediately.
