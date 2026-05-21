#!/usr/bin/env bash
# Usage: ./set_github_secrets.sh <repo_owner> <repo_name> <secrets_file>
# secrets_file: simple KEY=VALUE lines file

set -euo pipefail

REPO_OWNER=${1:-}
REPO_NAME=${2:-}
SECRETS_FILE=${3:-}

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" || -z "$SECRETS_FILE" ]]; then
  echo "Usage: $0 <repo_owner> <repo_name> <secrets_file>"
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install from https://github.com/cli/cli" >&2
  exit 3
fi

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "Secrets file not found: $SECRETS_FILE" >&2
  exit 4
fi

while IFS='=' read -r key value; do
  if [[ -z "$key" || "$key" = \#* ]]; then
    continue
  fi
  echo "Setting secret $key for $REPO_OWNER/$REPO_NAME"
  gh secret set "$key" -R "$REPO_OWNER/$REPO_NAME" -b"$value"
done < "$SECRETS_FILE"

echo "All secrets set."
#!/usr/bin/env bash
set -euo pipefail

# Simple helper to bulk-set GitHub Actions secrets using gh CLI.
# Usage: GITHUB_REPO=owner/repo ./set_github_secrets.sh path/to/secrets.env
# The secrets.env file should contain lines like: KEY=value

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install from https://cli.github.com/"
  exit 2
fi

REPO=${GITHUB_REPO:-}
if [ -z "$REPO" ]; then
  echo "Please set GITHUB_REPO env var (example: owner/repo)" >&2
  echo "Example: GITHUB_REPO=Fajar1180/Project-Aplikasi-Tukang-Dekat ./set_github_secrets.sh secrets.env"
  exit 2
fi

SECRETS_FILE=${1:-}
if [ -z "$SECRETS_FILE" ] || [ ! -f "$SECRETS_FILE" ]; then
  echo "Provide a secrets file path as first argument (KEY=value per line)." >&2
  exit 2
fi

echo "Uploading secrets from $SECRETS_FILE to $REPO"

while IFS= read -r line || [ -n "$line" ]; do
  # skip comments/empty lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$(echo "$line" | tr -d '[:space:]')" ]] && continue

  key=$(echo "$line" | sed 's/=.*//')
  value=$(echo "$line" | sed 's/^[^=]*=//')

  if [ -z "$key" ]; then
    continue
  fi

  echo "Setting secret: $key"
  gh secret set "$key" -b"$value" --repo "$REPO"
done < "$SECRETS_FILE"

echo "Done. Verify secrets in GitHub repository settings."
