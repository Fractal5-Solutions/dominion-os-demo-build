#!/usr/bin/env python3
"""Rotate a Postgres password and fail unless the repository secret is updated."""
from __future__ import annotations

import os
import secrets
import sys
from base64 import b64encode


def required(name: str) -> str:
    value = os.environ.get(name, '').strip()
    if not value:
        raise RuntimeError(f'{name} is required')
    return value


def generate_password() -> str:
    return secrets.token_urlsafe(32)


def store_github_secret(token: str, repo: str, name: str, secret_value: str) -> None:
    import requests
    from nacl import encoding, public

    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    }
    key_response = requests.get(
        f'https://api.github.com/repos/{repo}/actions/secrets/public-key',
        headers=headers,
        timeout=20,
    )
    key_response.raise_for_status()
    key = key_response.json()
    public_key = public.PublicKey(key['key'].encode('utf-8'), encoding.Base64Encoder())
    encrypted = public.SealedBox(public_key).encrypt(secret_value.encode('utf-8'))
    response = requests.put(
        f'https://api.github.com/repos/{repo}/actions/secrets/{name}',
        headers=headers,
        json={'encrypted_value': b64encode(encrypted).decode('utf-8'), 'key_id': key['key_id']},
        timeout=20,
    )
    response.raise_for_status()


def rotate_password(admin_dsn: str, target_user: str, new_password: str) -> None:
    import psycopg2
    from psycopg2 import sql

    with psycopg2.connect(admin_dsn) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql.SQL('ALTER ROLE {} WITH PASSWORD %s').format(sql.Identifier(target_user)),
                [new_password],
            )


def main() -> int:
    try:
        admin_dsn = required('POSTGRES_ADMIN_DSN')
        token = required('GH_ADMIN_TOKEN')
        repo = required('GITHUB_REPO')
        target_user = os.environ.get('TARGET_PG_USER', 'phi_admin').strip() or 'phi_admin'
        secret_name = os.environ.get('TARGET_REPO_SECRET', 'POSTGRES_PASSWORD').strip() or 'POSTGRES_PASSWORD'
        new_password = generate_password()

        rotate_password(admin_dsn, target_user, new_password)
        store_github_secret(token, repo, secret_name, new_password)
        print('Rotation completed and repository secret update was confirmed.')
        return 0
    except Exception as exc:
        print(f'Rotation failed: {type(exc).__name__}. No secret value was logged.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
