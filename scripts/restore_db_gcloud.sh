#!/usr/bin/env bash
# Restore Cloud SQL instance from backup (scaffold)
set -euo pipefail

INSTANCE=${1:-}
BACKUP_ID=${2:-}

if [ -z "$INSTANCE" ] || [ -z "$BACKUP_ID" ]; then
  echo "Usage: $0 <cloud-sql-instance> <backup-id>"
  exit 1
fi

echo "Restoring $INSTANCE from backup $BACKUP_ID"
# For Cloud SQL, point-in-time restore or import commands may be used. This is a scaffold.
gcloud sql backups restore $BACKUP_ID --instance="$INSTANCE" --async
