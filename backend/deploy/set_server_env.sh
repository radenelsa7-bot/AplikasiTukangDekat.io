#!/usr/bin/env bash
# Usage: ./set_server_env.sh <ssh_user>@<host> <remote_env_path> <local_secrets_file>
# This script copies a local KEY=VALUE file to remote .env (overwrites).

set -euo pipefail

TARGET=${1:-}
REMOTE_PATH=${2:-}
SECRETS_FILE=${3:-}

if [[ -z "$TARGET" || -z "$REMOTE_PATH" || -z "$SECRETS_FILE" ]]; then
  echo "Usage: $0 <ssh_user>@<host> <remote_env_path> <local_secrets_file>"
  exit 2
fi

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "Secrets file not found: $SECRETS_FILE" >&2
  exit 3
fi

echo "Copying $SECRETS_FILE to $TARGET:$REMOTE_PATH"
scp "$SECRETS_FILE" "$TARGET:$REMOTE_PATH"
echo "Done. Ensure file permissions are correct on remote server."
