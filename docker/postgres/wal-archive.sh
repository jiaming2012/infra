#!/bin/bash
# =============================================================================
# WAL Archive Script — Ships WAL segments to Hetzner Object Storage (S3)
# =============================================================================
# Called by PostgreSQL via archive_command = '/usr/local/bin/wal-archive.sh %p %f'
#   %p = full path to the WAL file
#   %f = WAL file name only
#
# Prerequisites inside the Postgres container:
#   apt-get install -y awscli   (or use a Postgres image with awscli baked in)
#   OR mount the aws binary from the host
# =============================================================================

set -euo pipefail

WAL_PATH="$1"
WAL_NAME="$2"

# These come from container environment variables (set in .env / docker-compose)
: "${S3_ENDPOINT:?S3_ENDPOINT not set}"
: "${S3_ACCESS_KEY:?S3_ACCESS_KEY not set}"
: "${S3_SECRET_KEY:?S3_SECRET_KEY not set}"
: "${S3_BUCKET:?S3_BUCKET not set}"

export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"

# Upload WAL segment, fail loudly if it doesn't work (Postgres will retry)
aws s3 cp \
  --endpoint-url "$S3_ENDPOINT" \
  "$WAL_PATH" \
  "s3://${S3_BUCKET}/wal/${WAL_NAME}" \
  --only-show-errors

echo "$(date -Iseconds) Archived WAL segment: ${WAL_NAME}" >> /var/log/postgresql/wal-archive.log
