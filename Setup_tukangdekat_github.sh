#!/usr/bin/env bash
# =============================================================
# TukangDekat - GitHub Issue/Label/Project Sync Script
# Idempotent: aman dijalankan berulang kali.
#
# Fitur:
# - Cek repo terlebih dahulu: label, milestone, issue, project
# - Buat yang belum ada, skip yang sudah ada
# - Pakai username GitHub yang Anda berikan
# =============================================================

set -euo pipefail

REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"
PROJECT_NAME="TukangDekat - Sprint Board"
PROJECT_OWNER="${REPO%%/*}"

PM="radenelsa7-bot"
BE1="Fajar1180"
BE2="nabilah-asana"
BE3="fatin-asyifa"
FE1="tetep-safarudin"
FE2="fazna-alaisal"
FE3="nabil-ramadhan"
QA="aldy-ramadani"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}$*${NC}" >&2; }
ok() { echo -e "${GREEN}$*${NC}" >&2; }
warn() { echo -e "${YELLOW}$*${NC}" >&2; }
fail() { echo -e "${RED}$*${NC}" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "✗ Perintah '$1' tidak ditemukan."
    exit 1
  fi
}

require_cmd gh
require_cmd python3

if ! gh auth status >/dev/null 2>&1; then
  fail "✗ GitHub CLI belum login. Jalankan: gh auth login"
  exit 1
fi

info "╔══════════════════════════════════════════════════════╗"
info "║      TukangDekat - GitHub Sync Script                ║"
info "╚══════════════════════════════════════════════════════╝"
info "Target repo : $REPO"
info "Project name : $PROJECT_NAME"

print_repo_snapshot() {
  info "\n[0] Cek isi repo terlebih dahulu..."

  local label_names milestone_titles issue_titles
  label_names=$(gh label list --repo "$REPO" --limit 200 --json name --jq '.[] | .name' 2>/dev/null || true)
  milestone_titles=$(gh api "repos/$REPO/milestones" --paginate --jq '.[] | .title' 2>/dev/null || true)
  issue_titles=$(gh issue list --repo "$REPO" --state all --limit 200 --json title --jq '.[] | .title' 2>/dev/null || true)

  echo "  Label yang sudah ada:"
  if [[ -n "$label_names" ]]; then
    printf '%s\n' "$label_names" | sed 's/^/    - /'
  else
    echo "    (belum ada / tidak bisa dibaca)"
  fi

  echo "  Milestone yang sudah ada:"
  if [[ -n "$milestone_titles" ]]; then
    printf '%s\n' "$milestone_titles" | sed 's/^/    - /'
  else
    echo "    (belum ada / tidak bisa dibaca)"
  fi

  echo "  Issue yang sudah ada:"
  if [[ -n "$issue_titles" ]]; then
    printf '%s\n' "$issue_titles" | sed 's/^/    - /'
  else
    echo "    (belum ada / tidak bisa dibaca)"
  fi
}

label_exists() {
  local label="$1"
  gh label list --repo "$REPO" --limit 200 --json name --jq '.[] | .name' 2>/dev/null | grep -Fxq "$label"
}

ensure_label() {
  local name="$1" color="$2" desc="$3"
  if label_exists "$name"; then
    warn "  ⚠ Label sudah ada: $name"
    return 0
  fi

  if gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" >/dev/null 2>&1; then
    ok "  ✓ Label dibuat: $name"
  else
    warn "  ⚠ Gagal membuat label: $name"
  fi
}

milestone_exists() {
  local title="$1"
  gh api "repos/$REPO/milestones" --paginate --jq '.[] | .title' 2>/dev/null | grep -Fxq "$title"
}

ensure_milestone() {
  local title="$1" due_on="$2" desc="$3"
  if milestone_exists "$title"; then
    warn "  ⚠ Milestone sudah ada: $title"
    return 0
  fi

  if gh api "repos/$REPO/milestones" --method POST --field title="$title" --field due_on="${due_on}T23:59:59Z" --field description="$desc" >/dev/null 2>&1; then
    ok "  ✓ Milestone dibuat: $title"
  else
    warn "  ⚠ Gagal membuat milestone: $title"
  fi
}

existing_issue_url() {
  local title="$1"
  gh issue list --repo "$REPO" --state all --limit 200 --json title,url --jq '.[] | [.title,.url] | @tsv' 2>/dev/null \
    | awk -F'\t' -v wanted="$title" '$1 == wanted {print $2; exit}'
}

create_or_get_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local assignees="$4"
  local milestone_title="$5"

  local url
  url="$(existing_issue_url "$title" || true)"
  if [[ -n "$url" ]]; then
    warn "  ⚠ Issue sudah ada: $title"
    echo "$url"
    return 0
  fi

  local body_file
  body_file="$(mktemp)"
  printf '%s\n' "$body" > "$body_file"

  local cmd=(gh issue create --repo "$REPO" --title "$title" --body-file "$body_file")

  IFS=',' read -ra label_array <<< "$labels"
  for label in "${label_array[@]}"; do
    label="${label//[[:space:]]/}"
    [[ -n "$label" ]] && cmd+=(--label "$label")
  done

  if [[ -n "$assignees" ]]; then
    IFS=',' read -ra assignee_array <<< "$assignees"
    for assignee in "${assignee_array[@]}"; do
      assignee="${assignee//[[:space:]]/}"
      [[ -n "$assignee" ]] && cmd+=(--assignee "$assignee")
    done
  fi

  if [[ -n "$milestone_title" ]]; then
    cmd+=(--milestone "$milestone_title")
  fi

  if url="$(${cmd[@]} 2>/dev/null || true)"; then
    :
  fi
  rm -f "$body_file"

  if [[ -n "$url" ]]; then
    ok "  ✓ Issue dibuat: $title"
    echo "$url"
    return 0
  fi

  warn "  ⚠ Gagal membuat issue: $title"
  return 1
}

project_number_from_list() {
  local json_output="$1"
  PROJECT_JSON="$json_output" PROJECT_TITLE="$PROJECT_NAME" python3 - <<'PY'
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
if isinstance(data, dict):
    for key in ('projects', 'data', 'items'):
        value = data.get(key)
        if isinstance(value, list):
            items = value
            break
    else:
        items = [data]
elif isinstance(data, list):
    items = data

for item in items:
    if isinstance(item, dict) and item.get('title') == title:
        number = item.get('number') or item.get('id') or ''
        print(number)
        sys.exit(0)
PY
}

ensure_project_board() {
  info "\n[Project] Cek GitHub Project Board..."

  local list_output project_number create_output
  list_output="$(gh project list --owner "$PROJECT_OWNER" --format json 2>/dev/null || true)"
  project_number="$(project_number_from_list "$list_output" || true)"

  if [[ -n "$project_number" ]]; then
    ok "  ✓ Project sudah ada: #$project_number"
    echo "$project_number"
    return 0
  fi

  create_output="$(gh project create --owner "$PROJECT_OWNER" --title "$PROJECT_NAME" --format json 2>&1 || true)"
  if [[ "$create_output" == *"missing required scopes"* ]]; then
    warn "  ⚠ Scope project belum ada. Jalankan: gh auth refresh -s project,read:project"
    echo ""
    return 0
  fi

  project_number="$(printf '%s' "$create_output" | python3 - <<'PY'
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
    ok "  ✓ Project dibuat: #$project_number"
    echo "$project_number"
  else
    warn "  ⚠ Project board skip - bisa dibuat manual nanti"
    echo ""
  fi
}

add_issue_to_project() {
  local project_number="$1" issue_url="$2"
  [[ -z "$project_number" || -z "$issue_url" ]] && return 0
  gh project item-add "$project_number" --owner "$PROJECT_OWNER" --url "$issue_url" >/dev/null 2>&1 || true
}

# -------------------------------------------------------------
# Repository snapshot
# -------------------------------------------------------------
print_repo_snapshot

# -------------------------------------------------------------
# Labels
# -------------------------------------------------------------
info "\n[1/4] Membuat labels..."
ensure_label "role: PM" "0075ca" "Project Manager"
ensure_label "role: Backend" "e4e669" "Backend Developer"
ensure_label "role: Frontend" "d93f0b" "Frontend Developer"
ensure_label "role: Testing" "0e8a16" "QA / Testing"
ensure_label "week-1 (11-17 Mei)" "bfd4f2" "Minggu 1"
ensure_label "week-2 (18-24 Mei)" "bfd4f2" "Minggu 2"
ensure_label "week-3 (25-31 Mei)" "bfd4f2" "Minggu 3"
ensure_label "week-4 (1-7 Jun)" "bfd4f2" "Minggu 4"
ensure_label "week-5 (8-14 Jun)" "bfd4f2" "Minggu 5"
ensure_label "week-6 (15-18 Jun)" "bfd4f2" "Minggu 6"
ensure_label "priority: high" "b60205" "High priority"
ensure_label "priority: medium" "fbca04" "Medium priority"
ensure_label "priority: low" "c2e0c6" "Low priority"
ensure_label "status: blocked" "e11d48" "Tertahan / ada hambatan"
ensure_label "status: review" "8b5cf6" "Perlu review"
ensure_label "module: auth" "c5def5" ""
ensure_label "module: order" "c5def5" ""
ensure_label "module: payment" "c5def5" ""
ensure_label "module: provider" "c5def5" ""
ensure_label "module: notification" "c5def5" ""
ensure_label "module: review" "c5def5" ""
ensure_label "module: admin" "c5def5" ""
ensure_label "module: UI/UX" "c5def5" ""
ensure_label "documentation" "0052cc" ""
ensure_label "testing" "0e8a16" ""

# -------------------------------------------------------------
# Milestones
# -------------------------------------------------------------
info "\n[2/4] Membuat milestones..."
ensure_milestone "Backend - Integration & Reliability" "2026-05-31" "Integration test untuk network failures dan backoff"
ensure_milestone "Backend - Deploy & Monitoring" "2026-06-07" "CI staging, smoke test post-deploy, monitoring/alerting"
ensure_milestone "Frontend - Alerts, Tests & Notes" "2026-06-14" "Payout-alerts UI, frontend tests, API notes"
ensure_milestone "Project - Board Sync & Tracking" "2026-06-18" "Sinkronisasi issue, progress, dan project board"

backend_integration_ms="Backend - Integration & Reliability"
backend_deploy_ms="Backend - Deploy & Monitoring"
frontend_ms="Frontend - Alerts, Tests & Notes"
project_ms="Project - Board Sync & Tracking"

# -------------------------------------------------------------
# Project board
# -------------------------------------------------------------
project_number="$(ensure_project_board || true)"

# -------------------------------------------------------------
# Issues from current PROGRESS_TRACKING pending items
# -------------------------------------------------------------
info "\n[3/4] Membuat issues..."

issue_url="$(create_or_get_issue \
  "[Backend] Integration test untuk network failures dan backoff" \
  "$(cat <<'EOF'
## Deskripsi
Tambahkan integration test lengkap untuk kegagalan jaringan dan retry/backoff pada payout pipeline.

## Tasks
- [ ] Uji skenario timeout dan koneksi putus
- [ ] Uji retry/backoff pada gateway call
- [ ] Uji logging dan fallback response saat provider down
- [ ] Pastikan test berjalan stabil di pipeline CI

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/backend-121-integration-backoff
EOF
)" \
  "role: Backend,testing,priority: high,module: payment" \
  "$BE1" \
  "$backend_integration_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Backend] CI job integration/staging gate by secrets" \
  "$(cat <<'EOF'
## Deskripsi
Buat job CI untuk integration/staging yang hanya aktif bila secrets tersedia.

## Tasks
- [ ] Tambahkan job khusus integration/staging
- [ ] Gate job memakai secrets yang aman
- [ ] Pastikan job tidak gagal saat secrets belum disetel
- [ ] Dokumentasikan cara menjalankan job di environment staging

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/backend-122-ci-staging
EOF
)" \
  "role: Backend,priority: high,documentation" \
  "$BE2" \
  "$backend_deploy_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Backend] Migrasi staging, queue worker, dan smoke test post-deploy" \
  "$(cat <<'EOF'
## Deskripsi
Siapkan migrasi staging, aktifkan queue worker, lalu jalankan smoke test setelah deploy.

## Tasks
- [ ] Jalankan migrasi di staging
- [ ] Aktifkan queue worker di staging/production
- [ ] Tambahkan smoke test pasca deploy
- [ ] Catat hasil verifikasi deployment

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/backend-123-deploy-smoke
EOF
)" \
  "role: Backend,priority: high,testing,module: notification" \
  "$BE3" \
  "$backend_deploy_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Backend] Monitoring/metrics produksi dan alerting" \
  "$(cat <<'EOF'
## Deskripsi
Tambahkan monitoring produksi dan alerting untuk payout pipeline.

## Tasks
- [ ] Evaluasi Sentry/Prometheus untuk produksi
- [ ] Tambahkan alert untuk kegagalan payout
- [ ] Pastikan event penting terekam di log/metric
- [ ] Dokumentasikan cara memantau error produksi

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/backend-124-monitoring-alerts
EOF
)" \
  "role: Backend,priority: medium,module: notification" \
  "$BE1,$BE2" \
  "$backend_deploy_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Frontend] Payout-alerts UI untuk admin atau treasurer" \
  "$(cat <<'EOF'
## Deskripsi
Bangun UI notifikasi payout untuk admin atau treasurer.

## Tasks
- [ ] Tampilkan daftar alert payout
- [ ] Tambahkan state empty/error/loading
- [ ] Sinkronkan dengan alur notifikasi backend
- [ ] Pastikan tampilan cocok di mobile

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/frontend-125-alert-ui
EOF
)" \
  "role: Frontend,priority: high,module: notification,module: UI/UX" \
  "$FE1" \
  "$frontend_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Frontend] Build dan jalankan frontend tests" \
  "$(cat <<'EOF'
## Deskripsi
Jalankan dan rapikan test frontend yang mencakup build, style, dan basic UI flow.

## Tasks
- [ ] Jalankan build frontend
- [ ] Jalankan test terkait vite, tailwind, dan js
- [ ] Perbaiki test yang gagal
- [ ] Simpan hasil validasi di dokumen tracking

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/frontend-126-tests
EOF
)" \
  "role: Frontend,testing,priority: high" \
  "$FE2" \
  "$frontend_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

issue_url="$(create_or_get_issue \
  "[Frontend] Update API docs dan frontend integration notes" \
  "$(cat <<'EOF'
## Deskripsi
Perbarui dokumentasi integrasi API untuk frontend agar selaras dengan backend terakhir.

## Tasks
- [ ] Update endpoint yang berubah
- [ ] Tambahkan catatan integrasi untuk screen penting
- [ ] Sesuaikan contoh request/response
- [ ] Pastikan dokumentasi mudah dipakai saat handoff

## Referensi
- PROGRESS_TRACKING.md
- Branch: feature/frontend-127-api-notes
EOF
)" \
  "role: Frontend,documentation,priority: medium" \
  "$FE3" \
  "$frontend_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

# Optional project sync issue
issue_url="$(create_or_get_issue \
  "[PM] Sinkronkan project tracking dan issue repo" \
  "$(cat <<'EOF'
## Deskripsi
Selaraskan GitHub Issues, labels, milestone, dan project board dengan PROGRESS_TRACKING.md.

## Tasks
- [ ] Pastikan issue yang selesai tidak masuk backlog aktif
- [ ] Pastikan issue yang masih pending ada di milestone yang benar
- [ ] Periksa kembali project board dan status tracking

## Referensi
- PROGRESS_TRACKING.md
EOF
)" \
  "role: PM,documentation,priority: high" \
  "$PM" \
  "$project_ms" )" || true
add_issue_to_project "$project_number" "$issue_url"

# -------------------------------------------------------------
# Final summary
# -------------------------------------------------------------
info "\n[4/4] Ringkasan..."
ok "Selesai melakukan sinkronisasi idempotent untuk repo $REPO"
echo "  PM  = $PM"
echo "  BE1 = $BE1"
echo "  BE2 = $BE2"
echo "  BE3 = $BE3"
echo "  FE1 = $FE1"
echo "  FE2 = $FE2"
echo "  FE3 = $FE3"
echo "  QA  = $QA"

echo
info "Lihat Issues : https://github.com/${REPO}/issues"
info "Lihat Milestones : https://github.com/${REPO}/milestones"
if [[ -n "$project_number" ]]; then
  info "Lihat Project : https://github.com/${PROJECT_OWNER}/projects/${project_number}"
else
  warn "Project board belum bisa diakses atau belum dibuat; silakan jalankan ulang setelah token punya scope project."
fi
