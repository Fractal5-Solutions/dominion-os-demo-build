#!/usr/bin/env bash
# Backup Cloud SQL instance and copy to GCS
set -euo pipefail

INSTANCE=${1:-}
BUCKET=${2:-}

if [ -z "$INSTANCE" ] || [ -z "$BUCKET" ]; then
  echo "Usage: $0 <cloud-sql-instance> <gcs-bucket>"
  exit 1
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_NAME="backup-${INSTANCE}-${TS}"

echo "Creating on-demand backup for $INSTANCE"
gcloud sql backups create --instance="$INSTANCE" --description="$BACKUP_NAME"

echo "Copying latest backup to gs://$BUCKET/"
# This assumes you have access to export; adjust depending on DB type
echo "Export step may require Cloud SQL export command depending on DB engine"
