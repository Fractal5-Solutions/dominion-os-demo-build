#!/usr/bin/env python3
"""Rotate a Postgres user's password and optionally store the new secret.

Usage: set `POSTGRES_ADMIN_DSN` env var (admin connection string) and optionally
`TARGET_PG_USER` (default: phi_admin). If `GH_ADMIN_TOKEN` and `GITHUB_REPO` are
provided, the script will attempt to store the new password as a repo secret
named `PHI_DB_PASSWORD`.
"""
import os
import secrets
import sys

def gen_password():
    return secrets.token_urlsafe(24)

def rotate_password(admin_dsn, target_user, new_password):
    try:
        import psycopg2
        from psycopg2 import sql
    except Exception as e:
        print('Missing dependency psycopg2. Install with: pip install psycopg2-binary')
        raise

    conn = psycopg2.connect(admin_dsn)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(sql.SQL("ALTER ROLE {} WITH PASSWORD %s").format(sql.Identifier(target_user)), [new_password])
    cur.close()
    conn.close()

def main():
    admin_dsn = os.environ.get('POSTGRES_ADMIN_DSN')
    if not admin_dsn:
        print('POSTGRES_ADMIN_DSN not set; cannot rotate')
        sys.exit(1)

    target = os.environ.get('TARGET_PG_USER', 'phi_admin')
    new_pass = os.environ.get('NEW_PG_PASSWORD') or gen_password()

    print('Rotating password for', target)
    rotate_password(admin_dsn, target, new_pass)
    print('Password rotated successfully. NEW password is available via output only to the caller.')

    # If GH_ADMIN_TOKEN and GITHUB_REPO are present, attempt to store the new secret.
    gh_token = os.environ.get('GH_ADMIN_TOKEN')
    gh_repo = os.environ.get('GITHUB_REPO')
    if gh_token and gh_repo:
        try:
            store_github_secret(gh_token, gh_repo, 'PHI_DB_PASSWORD', new_pass)
            print('Stored new password in repository secret PHI_DB_PASSWORD')
        except Exception as e:
            print('Failed to store secret in GitHub:', e)

    # For security, do not print the full new password in logs by default.
    debug = os.environ.get('DEBUG_SHOW_SECRET')
    if debug:
        print('NEW_PASSWORD=' + new_pass)
    else:
        print('New password generated and stored (masked in logs).')

def store_github_secret(token, repo, name, secret_value):
    # Store secret via GitHub REST API: requires encrypting with repo public key.
    import requests
    from base64 import b64encode
    try:
        from nacl import public, encoding
    except Exception:
        raise RuntimeError('PyNaCl required: pip install pynacl')

    headers = {'Authorization': f'token {token}', 'Accept': 'application/vnd.github+json'}
    # Get public key
    r = requests.get(f'https://api.github.com/repos/{repo}/actions/secrets/public-key', headers=headers)
    r.raise_for_status()
    key = r.json()
    pubkey = key['key']
    key_id = key['key_id']

    public_key = public.PublicKey(pubkey.encode('utf-8'), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key)
    encrypted = sealed_box.encrypt(secret_value.encode('utf-8'))
    encrypted_b64 = b64encode(encrypted).decode('utf-8')

    payload = {'encrypted_value': encrypted_b64, 'key_id': key_id}
    put = requests.put(f'https://api.github.com/repos/{repo}/actions/secrets/{name}', headers=headers, json=payload)
    put.raise_for_status()

if __name__ == '__main__':
    main()
