#!/usr/bin/env bash
# =============================================================
#  TukangDekat – PM_UAS GitHub Board Sync
#  Tujuan:
#  - Memasukkan issue yang sudah ada di repo ke GitHub Project board
#  - Menghindari duplikasi data
#  - Tidak mengubah assignee issue yang sudah ada
#
#  Cara pakai:
#  1. gh auth login
#  2. Pastikan token punya scope: project, read:project, repo
#  3. Jalankan: bash Setup_tukangdekat_github_pm_uas_sync.sh
# =============================================================

set -euo pipefail

REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"
PROJECT_OWNER="${REPO%%/*}"
PROJECT_TITLE="PM_UAS_rekayasa_Sistem_Informasi"
PROJECT_NUMBER=""
SYNC_SCOPE="${SYNC_SCOPE:-all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}$*${NC}"; }
ok() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }
fail() { echo -e "${RED}$*${NC}"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "✗ Perintah '$1' tidak ditemukan."
    exit 1
  fi
}

detect_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD=(python3)
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    PYTHON_CMD=(python)
    return 0
  fi

  if command -v py >/dev/null 2>&1; then
    PYTHON_CMD=(py -3)
    return 0
  fi

  fail "✗ Python tidak ditemukan."
  exit 1
}

ensure_gh_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    fail "✗ GitHub CLI belum login. Jalankan: gh auth login"
    exit 1
  fi
}

project_number_from_list() {
  local json_output="$1"
  PROJECT_JSON="$json_output" PROJECT_TITLE="$PROJECT_TITLE" "${PYTHON_CMD[@]}" - <<'PY'
import json, os, sys
raw = os.environ.get('PROJECT_JSON', '').strip()
title = os.environ.get('PROJECT_TITLE', '')
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

items = []
if isinstance(data, list):
    items = data
elif isinstance(data, dict):
    for key in ('projects', 'data', 'items'):
        value = data.get(key)
        if isinstance(value, list):
            items = value
            break
    else:
        items = [data]

for item in items:
    if isinstance(item, dict) and item.get('title') == title:
        print(item.get('number') or item.get('id') or '')
        sys.exit(0)
PY
}

ensure_project_board() {
  local list_output create_output project_number

  list_output="$(gh project list --owner "$PROJECT_OWNER" --format json 2>/dev/null || true)"
  project_number="$(project_number_from_list "$list_output" || true)"
  if [[ -n "$project_number" ]]; then
    ok "✓ Project board sudah ada: #$project_number"
    printf '%s' "$project_number"
    return 0
  fi

  create_output="$(gh project create --owner "$PROJECT_OWNER" --title "$PROJECT_TITLE" --format json 2>&1 || true)"
  if printf '%s' "$create_output" | grep -qi "missing required scopes"; then
    warn "⚠ Scope project belum ada. Jalankan: gh auth refresh -s project,read:project"
    return 0
  fi

  project_number="$(printf '%s' "$create_output" | "${PYTHON_CMD[@]}" - <<'PY'
import json, sys
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
if isinstance(data, dict):
    print(data.get('number', '') or data.get('id', ''))
PY
)"

  if [[ -n "$project_number" ]]; then
    ok "✓ Project board dibuat: #$project_number"
    printf '%s' "$project_number"
  else
    warn "⚠ Project board tidak ditemukan / belum bisa dibuat"
  fi
}

issue_url_by_title() {
  local title="$1"
  gh issue list --repo "$REPO" --state all --limit 200 --json title,url --jq '.[] | [.title, .url] | @tsv' 2>/dev/null \
    | awk -F'\t' -v wanted="$title" '$1 == wanted {print $2; exit}'
}

project_item_id_by_url() {
  local issue_url="$1"
  [[ -z "$PROJECT_NUMBER" ]] && return 0
  gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    --jq '.items[] | select((.content.url // .url) == "'"$issue_url"'") | .id' 2>/dev/null | head -1
}

add_issue_to_project_if_missing() {
  local issue_url="$1"
  [[ -z "$PROJECT_NUMBER" || -z "$issue_url" ]] && return 0
  if [[ -n "$(project_item_id_by_url "$issue_url")" ]]; then
    return 0
  fi
  gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$issue_url" >/dev/null 2>&1 || true
}

sync_repo_issues_to_project() {
  local added=0
  local skipped=0
  local failed=0

  info "[1/2] Ambil issue yang sudah ada di repo..."
  local issue_lines
  issue_lines="$(gh issue list --repo "$REPO" --state all --limit 200 --json title,url --jq '.[] | [.title, .url] | @tsv' 2>/dev/null || true)"

  if [[ -z "$issue_lines" ]]; then
    warn "  Tidak ada issue yang bisa dibaca dari repo."
    return 0
  fi

  info "[2/2] Sinkronkan ke Project board..."
  while IFS=$'\t' read -r issue_title issue_url; do
    [[ -z "$issue_url" ]] && continue

    if [[ -n "$(project_item_id_by_url "$issue_url")" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    if gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$issue_url" >/dev/null 2>&1; then
      added=$((added + 1))
    else
      failed=$((failed + 1))
    fi
  done <<< "$issue_lines"

  echo
  ok "✓ Selesai sinkronisasi untuk repo ini"
  echo "  Repo            : $REPO"
  echo "  Project         : $PROJECT_TITLE"
  echo "  Issue ditambah  : $added"
  echo "  Issue dilewati  : $skipped"
  echo "  Gagal tambah    : $failed"
}

main() {
  require_cmd gh
  detect_python
  ensure_gh_auth

  info "╔══════════════════════════════════════════════════════╗"
  info "║  TukangDekat – PM_UAS GitHub Board Sync              ║"
  info "╚══════════════════════════════════════════════════════╝"
  echo "Repo        : $REPO"
  echo "Project     : $PROJECT_TITLE"
  echo "Sync scope  : $SYNC_SCOPE"
  echo

  PROJECT_NUMBER="1"
  if [[ -z "$PROJECT_NUMBER" ]]; then
    warn "Project board belum siap. Proses dihentikan."
    exit 0
  fi

  sync_repo_issues_to_project
}

main "$@"
