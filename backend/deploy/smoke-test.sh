#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

API_BASE_URL="${SMOKE_API_BASE_URL:-http://127.0.0.1}"
HEALTH_URL="$API_BASE_URL/api/catalog/categories"

echo "[smoke-test] Starting deploy smoke test in $ROOT_DIR"

echo "[smoke-test] Checking laravel-queue service status..."
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet laravel-queue; then
    echo "[smoke-test] laravel-queue service is active"
  else
    echo "[smoke-test] ERROR: laravel-queue service is not active"
    systemctl status laravel-queue --no-pager || true
    exit 1
  fi
else
  echo "[smoke-test] systemctl not available; skipping service status check"
fi

echo "[smoke-test] Checking application HTTP health endpoint: $HEALTH_URL"
if command -v curl >/dev/null 2>&1; then
  if curl -fsS "$HEALTH_URL" >/dev/null; then
    echo "[smoke-test] HTTP health check passed"
  else
    echo "[smoke-test] ERROR: HTTP health check failed"
    exit 1
  fi
else
  echo "[smoke-test] curl not installed; skipping HTTP health check"
fi

echo "[smoke-test] Running deploy smoke command"
php artisan deploy:smoke --url="$API_BASE_URL"

echo "[smoke-test] Deploy smoke test completed successfully"
