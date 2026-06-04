#!/usr/bin/env bash
# =============================================================
#  TukangDekat – GitHub Project Setup Script
#  Dibuat oleh: R.Elsa Balqis (Project Manager)
#  Timeline: 11 Mei – 18 Juni 2026
#
#  CARA PAKAI:
#  1. Install GitHub CLI  : https://cli.github.com/
#  2. Login               : gh auth login
#  3. Isi variabel REPO di bawah (format: owner/repo-name)
#  4. Jalankan            : bash setup_tukangdekat_github.sh
# =============================================================

# ─── KONFIGURASI — SESUAIKAN INI ─────────────────────────────
REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"          # Ganti dengan username/repo kamu
PROJECT_NAME="TukangDekat – Sprint Board"
# ─────────────────────────────────────────────────────────────

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║      TukangDekat – GitHub Project Setup              ║"
echo "║      Timeline: 11 Mei – 18 Juni 2026                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Cek gh CLI tersedia
if ! command -v gh &> /dev/null; then
  echo -e "${RED}✗ GitHub CLI (gh) tidak ditemukan.${NC}"
  echo "  Install di: https://cli.github.com/"
  exit 1
fi

# Cek auth
if ! gh auth status &> /dev/null; then
  echo -e "${RED}✗ Belum login. Jalankan: gh auth login${NC}"
  exit 1
fi

echo -e "${GREEN}✓ GitHub CLI terdeteksi & sudah login${NC}"
echo -e "${YELLOW}→ Target repo: ${REPO}${NC}\n"

# =============================================================
# STEP 1 – LABELS
# =============================================================
echo -e "${CYAN}[1/4] Membuat labels...${NC}"

create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" --force 2>/dev/null \
    && echo -e "  ${GREEN}✓${NC} Label: $name" \
    || echo -e "  ${YELLOW}⚠${NC} Label sudah ada: $name"
}

# Role labels
create_label "role: PM"         "0075ca" "Project Manager"
create_label "role: Backend"    "e4e669" "Backend Developer"
create_label "role: Frontend"   "d93f0b" "Frontend Developer"
create_label "role: Testing"    "0e8a16" "QA / Testing"

# Week labels
create_label "week-1 (11-17 Mei)"   "bfd4f2" "Minggu 1"
create_label "week-2 (18-24 Mei)"   "bfd4f2" "Minggu 2"
create_label "week-3 (25-31 Mei)"   "bfd4f2" "Minggu 3"
create_label "week-4 (1-7 Jun)"     "bfd4f2" "Minggu 4"
create_label "week-5 (8-14 Jun)"    "bfd4f2" "Minggu 5"
create_label "week-6 (15-18 Jun)"   "bfd4f2" "Minggu 6 (Final)"

# Status labels
create_label "priority: high"   "b60205" "High priority"
create_label "priority: medium" "fbca04" "Medium priority"
create_label "priority: low"    "c2e0c6" "Low priority"
create_label "status: blocked"  "e11d48" "Tertahan / ada hambatan"
create_label "status: review"   "8b5cf6" "Perlu review"

# Module labels
create_label "module: auth"         "c5def5" ""
create_label "module: order"        "c5def5" ""
create_label "module: payment"      "c5def5" ""
create_label "module: provider"     "c5def5" ""
create_label "module: notification" "c5def5" ""
create_label "module: review"       "c5def5" ""
create_label "module: admin"        "c5def5" ""
create_label "module: UI/UX"        "c5def5" ""
create_label "documentation"        "0052cc" ""
create_label "testing"              "0e8a16" ""

# =============================================================
# STEP 2 – MILESTONES
# =============================================================
echo -e "\n${CYAN}[2/4] Membuat milestones backlog...${NC}"

create_milestone() {
  local title="$1" due="$2" desc="$3"
  gh api repos/${REPO}/milestones \
    --method POST \
    --field title="$title" \
    --field due_on="${due}T23:59:59Z" \
    --field description="$desc" \
    > /dev/null 2>&1 \
    && echo -e "  ${GREEN}✓${NC} Milestone: $title" \
    || echo -e "  ${YELLOW}⚠${NC} Milestone mungkin sudah ada: $title"
}

create_milestone "Backend – Integration & Reliability" "2026-05-31" "Integration test untuk network failures dan backoff"
create_milestone "Backend – Deploy & Monitoring" "2026-06-07" "CI staging, smoke test post-deploy, monitoring/alerting"
create_milestone "Frontend – Alerts, Tests & Notes" "2026-06-14" "Payout-alerts UI, frontend tests, API notes"
create_milestone "Project – Board Sync & Tracking" "2026-06-18" "Sinkronisasi issue, progress, dan project board"

# Helper: get milestone title by title keyword
get_milestone() {
  gh api repos/${REPO}/milestones --jq ".[] | select(.title | contains(\"$1\")) | .title" 2>/dev/null | head -1
}

# =============================================================
# STEP 3 – Create GitHub Project Board (early)
# =============================================================
echo -e "\n${CYAN}[3/4] Membuat GitHub Project Board...${NC}"

PROJECT_OWNER=$(echo $REPO | cut -d'/' -f1)
PROJECT_OUTPUT=$(gh project create \
  --owner "$PROJECT_OWNER" \
  --title "$PROJECT_NAME" \
  --format json 2>&1)

PROJECT_NUMBER=$(printf '%s' "$PROJECT_OUTPUT" | python3 -c "import sys,json; data=sys.stdin.read().strip(); print(json.loads(data).get('number','') if data and '{' in data else '')" 2>/dev/null || true)

if [[ -n "$PROJECT_NUMBER" ]]; then
  echo -e "  ${GREEN}✓${NC} Project Board dibuat: #$PROJECT_NUMBER"
else
  if printf '%s' "$PROJECT_OUTPUT" | grep -qi "missing required scopes"; then
    echo -e "  ${YELLOW}⚠${NC} Scope project belum ada. Jalankan:"
    echo -e "  ${YELLOW}→ gh auth refresh -s project,read:project${NC}"
    PROJECT_NUMBER=""
  else
    echo -e "  ${YELLOW}⚠${NC} Project board skip — akan manual add issues nanti"
    PROJECT_NUMBER=""
  fi
fi

# =============================================================
# STEP 4 – ISSUES
# =============================================================
echo -e "\n${CYAN}[4/5] Membuat issues...${NC}"

create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local assignees="$4"
  local milestone_keyword="$5"

  local ms_title=$(get_milestone "$milestone_keyword")
  
  # Create temporary file for body (to handle complex text with newlines)
  local body_file=$(mktemp)
  printf '%b' "$body" > "$body_file"

  # Build gh command
  local cmd=(gh issue create --repo "$REPO" --title "$title" --body-file "$body_file" --label "$labels")
  
  # Add assignees if provided
  if [[ -n "$assignees" ]]; then
    IFS=',' read -ra ASSIGNEE_ARRAY <<< "$assignees"
    for assignee in "${ASSIGNEE_ARRAY[@]}"; do
      assignee="${assignee//[[:space:]]/}"
      [[ -n "$assignee" ]] && cmd+=(--assignee "$assignee")
    done
  fi
  
  # Add milestone if found
  [[ -n "$ms_title" ]] && cmd+=(--milestone "$ms_title")

  # Execute and handle result
  if "${cmd[@]}" > /dev/null 2>&1; then
    if [[ -n "$assignees" ]]; then
      echo -e "  ${GREEN}✓${NC} $title"
    else
      echo -e "  ${GREEN}✓${NC} $title"
    fi
  else
    echo -e "  ${YELLOW}⚠${NC} Gagal: $title"
  fi
  
  rm -f "$body_file"
}

# Backlog aktif yang diselaraskan dengan PROGRESS_TRACKING.md.
# Isi username GitHub asli sebelum menjalankan script.
PM="${raradenelsa7-bot:-}"           # R.Elsa Balqis (PM)
BE1="${NabilahAsana:-}"         # Backend 1
BE2="${Fajar1180:-}"         # Backend 2
BE3="${Fatinasy7:-}"         # Backend 3
FE1="${tetepsafarudin:-}"         # Frontend 1
FE2="${faznalaisal44:-}"         # Frontend 2
FE3="${nabilramadhan05:-}"         # Frontend 3
QA="${aldyrmdny-lab:-}"           # QA

echo -e "\n  ${YELLOW}── BACKEND: backlog yang masih pending ──${NC}"

create_issue \
  "[PM] Sinkronkan tracking board dan status repo" \
  "## Deskripsi\nSesuaikan project board dan daftar issue agar selaras dengan PROGRESS_TRACKING.md.\n\n## Tasks\n- [ ] Pastikan issue yang sudah selesai tidak muncul sebagai backlog aktif\n- [ ] Pindahkan task yang pending ke milestone yang tepat\n- [ ] Update status issue di project board\n- [ ] Review draft PR tracking yang masih terbuka\n\n## Referensi\n- PROGRESS_TRACKING.md" \
  "role: PM,documentation,priority: high" \
  "$PM" "Project – Board Sync & Tracking"

create_issue \
  "[Backend] Integration test untuk network failures dan backoff" \
  "## Deskripsi\nTambahkan integration test lengkap untuk kegagalan jaringan dan retry/backoff pada payout pipeline.\n\n## Tasks\n- [ ] Uji skenario timeout dan koneksi putus\n- [ ] Uji retry/backoff pada gateway call\n- [ ] Uji logging dan fallback response saat provider down\n- [ ] Pastikan test berjalan stabil di pipeline CI\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/backend-121-integration-backoff" \
  "role: Backend,testing,priority: high,module: payment" \
  "$BE1" "Backend – Integration & Reliability"

create_issue \
  "[Backend] CI job integration/staging gate by secrets" \
  "## Deskripsi\nBuat job CI untuk integration/staging yang hanya aktif bila secrets tersedia.\n\n## Tasks\n- [ ] Tambahkan job khusus integration/staging\n- [ ] Gate job memakai secrets yang aman\n- [ ] Pastikan job tidak gagal saat secrets belum disetel\n- [ ] Dokumentasikan cara menjalankan job di environment staging\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/backend-122-ci-staging" \
  "role: Backend,priority: high,documentation" \
  "$BE2" "Backend – Deploy & Monitoring"

create_issue \
  "[Backend] Migrasi staging, queue worker, dan smoke test post-deploy" \
  "## Deskripsi\nSiapkan migrasi staging, aktifkan queue worker, lalu jalankan smoke test setelah deploy.\n\n## Tasks\n- [ ] Jalankan migrasi di staging\n- [ ] Aktifkan queue worker di staging/production\n- [ ] Tambahkan smoke test pasca deploy\n- [ ] Catat hasil verifikasi deployment\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/backend-123-deploy-smoke" \
  "role: Backend,priority: high,testing,module: notification" \
  "$BE3" "Backend – Deploy & Monitoring"

create_issue \
  "[Backend] Monitoring/metrics produksi dan alerting" \
  "## Deskripsi\nTambahkan monitoring produksi dan alerting untuk payout pipeline.\n\n## Tasks\n- [ ] Evaluasi Sentry/Prometheus untuk produksi\n- [ ] Tambahkan alert untuk kegagalan payout\n- [ ] Pastikan event penting terekam di log/metric\n- [ ] Dokumentasikan cara memantau error produksi\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/backend-124-monitoring-alerts" \
  "role: Backend,priority: medium,module: notification" \
  "$BE1,$BE2" "Backend – Deploy & Monitoring"

echo -e "\n  ${YELLOW}── FRONTEND: backlog yang masih pending ──${NC}"

create_issue \
  "[Frontend] Payout-alerts UI untuk admin atau treasurer" \
  "## Deskripsi\nBangun UI notifikasi payout untuk admin atau treasurer.\n\n## Tasks\n- [ ] Tampilkan daftar alert payout\n- [ ] Tambahkan state empty/error/loading\n- [ ] Sinkronkan dengan alur notifikasi backend\n- [ ] Pastikan tampilan cocok di mobile\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/frontend-125-alert-ui" \
  "role: Frontend,priority: high,module: notification,module: UI/UX" \
  "$FE1" "Frontend – Alerts, Tests & Notes"

create_issue \
  "[Frontend] Build dan jalankan frontend tests" \
  "## Deskripsi\nJalankan dan rapikan test frontend yang mencakup build, style, dan basic UI flow.\n\n## Tasks\n- [ ] Jalankan build frontend\n- [ ] Jalankan test terkait vite, tailwind, dan js\n- [ ] Perbaiki test yang gagal\n- [ ] Simpan hasil validasi di dokumen tracking\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/frontend-126-tests" \
  "role: Frontend,testing,priority: high" \
  "$FE2" "Frontend – Alerts, Tests & Notes"

create_issue \
  "[Frontend] Update API docs dan frontend integration notes" \
  "## Deskripsi\nPerbarui dokumentasi integrasi API untuk frontend agar selaras dengan backend terakhir.\n\n## Tasks\n- [ ] Update endpoint yang berubah\n- [ ] Tambahkan catatan integrasi untuk screen penting\n- [ ] Sesuaikan contoh request/response\n- [ ] Pastikan dokumentasi mudah dipakai saat handoff\n\n## Referensi\n- PROGRESS_TRACKING.md\n- Branch: feature/frontend-127-api-notes" \
  "role: Frontend,documentation,priority: medium" \
  "$FE3" "Frontend – Alerts, Tests & Notes"

if false; then

create_issue \
  "[PM] Finalisasi SRS & distribusi dokumen ke tim" \
  "## Deskripsi\nReview SRS v1.1, pastikan semua anggota tim memahami scope sistem.\n\n## Tasks\n- [ ] Review dan finalisasi SRS_TukangDekat_v1.1.md\n- [ ] Distribusikan dokumen ke semua anggota\n- [ ] Buat GitHub repo & project board\n- [ ] Setup branch strategy (main, develop, feature/*)\n- [ ] Buat dokumen CONTRIBUTING.md\n\n## Referensi\n- docs/srs/SRS_TukangDekat_v1.1.md" \
  "role: PM,week-1 (11-17 Mei),priority: high,documentation" \
  "$PM" "Week 1"

create_issue \
  "[PM] Setup GitHub Project Board & milestone tracking" \
  "## Deskripsi\nSetup GitHub Project (Kanban board) dengan kolom: Backlog, In Progress, Review, Done.\n\n## Tasks\n- [ ] Buat GitHub Project board\n- [ ] Konfigurasi kolom Kanban\n- [ ] Assign semua issues ke milestone yang sesuai\n- [ ] Sosialisasi cara penggunaan board ke tim\n- [ ] Buat template issue dan PR" \
  "role: PM,week-1 (11-17 Mei),priority: high" \
  "$PM" "Week 1"

create_issue \
  "[PM] Buat WBS & jadwal detail per anggota" \
  "## Deskripsi\nSusun Work Breakdown Structure dan jadwal mingguan yang jelas untuk setiap anggota.\n\n## Tasks\n- [ ] Susun WBS berdasarkan SRS feature list\n- [ ] Bagi task per role (Backend/Frontend/Testing)\n- [ ] Set deadline per task di GitHub Issues\n- [ ] Buat tabel RACI (Responsible, Accountable, Consulted, Informed)\n\n## Output\nFile docs/management/WBS_TukangDekat.md" \
  "role: PM,week-1 (11-17 Mei),priority: high,documentation" \
  "$PM" "Week 1"

create_issue \
  "[Backend] Setup Laravel project & Docker environment" \
  "## Deskripsi\nInisialisasi project Laravel dengan Docker Compose sesuai Deployment Diagram.\n\n## Tasks\n- [ ] Init Laravel 11 project\n- [ ] Buat docker-compose.yml (nginx, laravel-api, db, n8n)\n- [ ] Setup .env template\n- [ ] Konfigurasi database connection\n- [ ] Test docker-compose up berjalan\n- [ ] Push ke branch develop\n\n## Referensi\n- docs/srs/DEPLOYMENT_DIAGRAM_TukangDekat_v1.0.md" \
  "role: Backend,week-1 (11-17 Mei),priority: high" \
  "$BE1" "Week 1"

create_issue \
  "[Backend] Database migration sesuai schema MySQL" \
  "## Deskripsi\nBuat semua Laravel migration berdasarkan schema_mysql_tukangdekat.sql.\n\n## Tasks\n- [ ] Migration: users\n- [ ] Migration: provider_profiles\n- [ ] Migration: service_categories\n- [ ] Migration: provider_services\n- [ ] Migration: orders\n- [ ] Migration: payments\n- [ ] Migration: order_attachments\n- [ ] Migration: reviews\n- [ ] Migration: notification_logs\n- [ ] Buat seeders untuk data dummy kategori\n\n## Referensi\n- docs/database/schema_mysql_tukangdekat.sql" \
  "role: Backend,week-1 (11-17 Mei),priority: high,module: auth" \
  "$BE2" "Week 1"

create_issue \
  "[Frontend] Setup Flutter project & struktur folder" \
  "## Deskripsi\nInisialisasi project Flutter dan setup arsitektur folder.\n\n## Tasks\n- [ ] Init Flutter project\n- [ ] Setup dependency: dio, provider/riverpod, go_router\n- [ ] Buat struktur folder (features, core, shared)\n- [ ] Setup base API service (base URL, auth interceptor)\n- [ ] Setup theme & color scheme\n- [ ] Push ke branch develop\n\n## Referensi\n- docs/srs/COMPONENT_DIAGRAM_TukangDekat_v1.0.md" \
  "role: Frontend,week-1 (11-17 Mei),priority: high" \
  "$FE1" "Week 1"

create_issue \
  "[Frontend] Desain wireframe & UI kit (Figma)" \
  "## Deskripsi\nBuat wireframe untuk semua layar utama aplikasi.\n\n## Tasks\n- [ ] Wireframe: Login & Register\n- [ ] Wireframe: Home + Kategori\n- [ ] Wireframe: Daftar Provider & Detail\n- [ ] Wireframe: Form Buat Order\n- [ ] Wireframe: Detail Order & Status\n- [ ] Wireframe: Halaman Pembayaran (QR)\n- [ ] Wireframe: Rating & Review\n- [ ] Wireframe: Dashboard Admin/Treasurer\n\n## Referensi\n- SRS 3.1 User Interfaces" \
  "role: Frontend,week-1 (11-17 Mei),priority: high,module: UI/UX" \
  "$FE2,$FE3" "Week 1"

create_issue \
  "[Testing] Buat Test Plan dokumen" \
  "## Deskripsi\nSusun rencana pengujian mencakup semua fitur dari SRS.\n\n## Tasks\n- [ ] Identifikasi semua FR yang perlu diuji (FR-01 s/d FR-26)\n- [ ] Buat test case untuk happy path & edge case tiap fitur\n- [ ] Tentukan tools pengujian (Postman, Flutter test, dll)\n- [ ] Buat template bug report\n- [ ] Setup Postman Collection untuk API testing\n\n## Output\ndocs/testing/TEST_PLAN_TukangDekat.md" \
  "role: Testing,week-1 (11-17 Mei),priority: high,documentation,testing" \
  "$QA" "Week 1"

echo -e "\n  ${YELLOW}── WEEK 2: Auth & Fondasi API (18–24 Mei) ──${NC}"

create_issue \
  "[Backend] API Auth: Register, Login, Logout (FR-01, FR-02, FR-03)" \
  "## Deskripsi\nImplementasi endpoint autentikasi sesuai API Documentation section 5.1.\n\n## Tasks\n- [ ] POST /api/auth/register (customer & provider)\n- [ ] POST /api/auth/login (return token)\n- [ ] POST /api/auth/logout\n- [ ] Middleware role-based access (FR-04)\n- [ ] Password hashing (NFR-05)\n- [ ] Unit test auth endpoints\n\n## Acceptance Criteria\n- Register mengembalikan user_id & role\n- Login mengembalikan token valid\n- Endpoint protected menolak request tanpa token (401)\n\n## Referensi\n- API Doc 5.1\n- SRS FR-01 s/d FR-04" \
  "role: Backend,week-2 (18-24 Mei),priority: high,module: auth" \
  "$BE1" "Week 2"

create_issue \
  "[Backend] API Service Catalog: Categories & Provider List (FR-08, FR-09, FR-10)" \
  "## Deskripsi\nImplementasi endpoint katalog jasa dan pencarian provider.\n\n## Tasks\n- [ ] GET /api/categories\n- [ ] GET /api/providers (dengan filter category_id, q, is_verified)\n- [ ] GET /api/providers/{provider_user_id}\n- [ ] POST /api/provider/profile (role: PROVIDER)\n- [ ] POST /api/provider/services\n- [ ] PATCH /api/provider/services/{id}\n- [ ] Seeder 5 kategori default\n\n## Referensi\n- API Doc 5.2\n- SRS FR-05, FR-08, FR-09, FR-10" \
  "role: Backend,week-2 (18-24 Mei),priority: high,module: provider" \
  "$BE2" "Week 2"

create_issue \
  "[Backend] Model & Eloquent Relationships" \
  "## Deskripsi\nBuat semua Eloquent model dengan relasi sesuai Class Diagram.\n\n## Tasks\n- [ ] Model User (dengan role enum)\n- [ ] Model ProviderProfile (belongsTo User)\n- [ ] Model ServiceCategory\n- [ ] Model ProviderService\n- [ ] Model Order (belongsTo Customer, Provider, Service)\n- [ ] Model Payment (hasMany Order)\n- [ ] Model Review\n- [ ] Model NotificationLog\n- [ ] Factory & Faker untuk semua model\n\n## Referensi\n- docs/srs/CLASS_DIAGRAM_SPEC_TukangDekat_v1.0.md" \
  "role: Backend,week-2 (18-24 Mei),priority: high" \
  "$BE3" "Week 2"

create_issue \
  "[Frontend] Screen: Login & Register" \
  "## Deskripsi\nImplementasi UI dan integrasi API untuk Login & Register.\n\n## Tasks\n- [ ] UI Screen Login (email, password, tombol login)\n- [ ] UI Screen Register (name, email, phone, password, role selector)\n- [ ] Integrasi POST /api/auth/login\n- [ ] Integrasi POST /api/auth/register\n- [ ] Simpan token ke secure storage\n- [ ] Navigasi ke dashboard sesuai role\n- [ ] Handle error 401/422\n\n## Referensi\n- SRS 3.1, API Doc 5.1" \
  "role: Frontend,week-2 (18-24 Mei),priority: high,module: auth" \
  "$FE1" "Week 2"

create_issue \
  "[Frontend] Screen: Home & Daftar Kategori" \
  "## Deskripsi\nImplementasi halaman home dan daftar kategori jasa.\n\n## Tasks\n- [ ] UI Home Screen (header, kategori grid, provider featured)\n- [ ] Integrasi GET /api/categories\n- [ ] UI Category List dengan icon\n- [ ] Navigasi ke daftar provider by kategori\n\n## Referensi\n- API Doc 5.2, Wireframe Week 1" \
  "role: Frontend,week-2 (18-24 Mei),priority: high,module: provider" \
  "$FE2" "Week 2"

create_issue \
  "[Frontend] Screen: Daftar Provider & Detail Provider" \
  "## Deskripsi\nImplementasi halaman daftar dan detail provider.\n\n## Tasks\n- [ ] UI Daftar Provider (list card: nama, rating, area, verified badge)\n- [ ] Fitur filter/search (category, keyword)\n- [ ] Integrasi GET /api/providers\n- [ ] UI Detail Provider (profil, layanan, rating)\n- [ ] Integrasi GET /api/providers/{id}\n- [ ] Tombol 'Pesan Sekarang'\n\n## Referensi\n- API Doc 5.2, SRS FR-09, FR-10" \
  "role: Frontend,week-2 (18-24 Mei),priority: high,module: provider" \
  "$FE3" "Week 2"

create_issue \
  "[Testing] Testing Auth & Service Catalog API (Postman)" \
  "## Deskripsi\nPengujian endpoint auth dan service catalog yang sudah selesai di Week 2.\n\n## Tasks\n- [ ] Test POST /api/auth/register (valid & invalid)\n- [ ] Test POST /api/auth/login (valid & invalid)\n- [ ] Test GET /api/categories\n- [ ] Test GET /api/providers (dengan berbagai filter)\n- [ ] Test GET /api/providers/{id}\n- [ ] Catat semua bug ke GitHub Issues\n- [ ] Verifikasi response sesuai API Doc\n\n## Referensi\n- API Doc 5.1 & 5.2" \
  "role: Testing,week-2 (18-24 Mei),priority: high,testing,module: auth,module: provider" \
  "$QA" "Week 2"

echo -e "\n  ${YELLOW}── WEEK 3: Core Feature Backend (25–31 Mei) ──${NC}"

create_issue \
  "[Backend] API Orders: CRUD & Status Lifecycle (FR-11 s/d FR-14)" \
  "## Deskripsi\nImplementasi endpoint order lengkap dengan semua transisi status.\n\n## Tasks\n- [ ] POST /api/orders (buat order + DP invoice otomatis)\n- [ ] GET /api/orders (list dengan filter)\n- [ ] GET /api/orders/{id}\n- [ ] POST /api/orders/{id}/accept (PROVIDER)\n- [ ] POST /api/orders/{id}/reject (PROVIDER)\n- [ ] POST /api/orders/{id}/start (cek DP PAID – BR-02)\n- [ ] POST /api/orders/{id}/complete (input final_price)\n- [ ] POST /api/orders/{id}/cancel\n- [ ] POST /api/orders/{id}/attachments\n- [ ] Business rule: start hanya jika DP PAID\n\n## Referensi\n- API Doc 5.3\n- SRS FR-11 s/d FR-14, BR-01 s/d BR-03\n- Business Process 3.2 s/d 3.5" \
  "role: Backend,week-3 (25-31 Mei),priority: high,module: order" \
  "$BE1" "Week 3"

create_issue \
  "[Backend] Auto-create DP Payment saat Order dibuat (BR-01)" \
  "## Deskripsi\nLogika bisnis pembuatan tagihan DP 50% otomatis saat order dibuat.\n\n## Tasks\n- [ ] Service: hitung DP = 50% dari estimated_price\n- [ ] Insert Payment record (type=DP, status=UNPAID) saat order CREATED\n- [ ] Auto-create Final Payment saat order COMPLETED\n- [ ] Hitung final_amount = final_price - dp_amount\n- [ ] Validasi: order CLOSED hanya jika Final PAID (BR-03)\n- [ ] Database transaction untuk atomicity (NFR-09)\n\n## Referensi\n- SRS BR-01, BR-02, BR-03\n- API Doc response POST /api/orders" \
  "role: Backend,week-3 (25-31 Mei),priority: high,module: payment,module: order" \
  "$BE2" "Week 3"

create_issue \
  "[Backend] API Reviews & Rating (FR-23, FR-24)" \
  "## Deskripsi\nImplementasi endpoint review dan kalkulasi rata-rata rating provider.\n\n## Tasks\n- [ ] POST /api/orders/{id}/review (role: CUSTOMER, hanya jika CLOSED)\n- [ ] GET /api/providers/{id}/reviews\n- [ ] Update avg_rating di provider_profiles setelah review\n- [ ] Validasi: 1 order maksimal 1 review\n\n## Referensi\n- API Doc 5.6\n- SRS FR-23, FR-24" \
  "role: Backend,week-3 (25-31 Mei),priority: medium,module: review" \
  "$BE3" "Week 3"

create_issue \
  "[Frontend] Screen: Form Buat Order" \
  "## Deskripsi\nImplementasi form pembuatan order oleh Customer.\n\n## Tasks\n- [ ] UI Form Order (pilih layanan, jadwal datetime picker, alamat, catatan)\n- [ ] Upload foto kerusakan (opsional)\n- [ ] Preview estimasi harga & DP yang akan dibayar\n- [ ] Integrasi POST /api/orders\n- [ ] Handle response: tampilkan order detail + tombol bayar DP\n- [ ] Validasi form client-side\n\n## Referensi\n- API Doc 5.3, SRS FR-11" \
  "role: Frontend,week-3 (25-31 Mei),priority: high,module: order" \
  "$FE1" "Week 3"

create_issue \
  "[Frontend] Screen: Detail Order & Riwayat Order" \
  "## Deskripsi\nHalaman detail order dengan status tracking dan riwayat semua order.\n\n## Tasks\n- [ ] UI Detail Order (status badge, info provider, jadwal, harga)\n- [ ] Status timeline/stepper (CREATED → ACCEPTED → IN_PROGRESS → COMPLETED → CLOSED)\n- [ ] Tombol aksi sesuai role & status (terima, tolak, mulai, selesai)\n- [ ] UI Riwayat Order (list dengan filter status)\n- [ ] Integrasi GET /api/orders & GET /api/orders/{id}\n- [ ] Pull-to-refresh\n\n## Referensi\n- API Doc 5.3, Business Process 3.2–3.5" \
  "role: Frontend,week-3 (25-31 Mei),priority: high,module: order" \
  "$FE2" "Week 3"

create_issue \
  "[Frontend] Screen: Provider – Terima/Tolak & Mulai Order" \
  "## Deskripsi\nFlow untuk Provider dalam mengelola order masuk.\n\n## Tasks\n- [ ] UI notifikasi order masuk untuk Provider\n- [ ] Tombol Terima / Tolak order\n- [ ] Integrasi POST /api/orders/{id}/accept & reject\n- [ ] Tombol Mulai Kerja (IN_PROGRESS)\n- [ ] Integrasi POST /api/orders/{id}/start\n- [ ] Handle error jika DP belum dibayar\n- [ ] Form input final_price + tombol Selesai\n- [ ] Integrasi POST /api/orders/{id}/complete\n\n## Referensi\n- API Doc 5.3, Business Process 3.4" \
  "role: Frontend,week-3 (25-31 Mei),priority: high,module: order" \
  "$FE3" "Week 3"

create_issue \
  "[Testing] Testing Order Lifecycle (Postman + Manual)" \
  "## Deskripsi\nPengujian menyeluruh alur order dari CREATED sampai CLOSED.\n\n## Tasks\n- [ ] Test POST /api/orders (valid & invalid)\n- [ ] Test accept/reject/start/complete/cancel\n- [ ] Test business rule: start tanpa DP PAID harus error\n- [ ] Test status transition yang tidak valid\n- [ ] Test review setelah CLOSED\n- [ ] Test review duplicate (harus error)\n- [ ] Catat semua bug\n\n## Referensi\n- SRS BR-01 s/d BR-03, FR-11 s/d FR-14" \
  "role: Testing,week-3 (25-31 Mei),priority: high,testing,module: order" \
  "$QA" "Week 3"

create_issue \
  "[PM] Review progress Week 2 & koordinasi Week 3" \
  "## Deskripsi\nRapat mingguan review progress, identifikasi blocker, dan update jadwal.\n\n## Tasks\n- [ ] Kumpulkan status update dari semua anggota\n- [ ] Update GitHub Project board\n- [ ] Identifikasi blocker & buat issue status: blocked\n- [ ] Notulen rapat (docs/notulen/)\n- [ ] Pastikan API Doc sudah sinkron dengan implementasi\n- [ ] Review PR yang pending" \
  "role: PM,week-3 (25-31 Mei),priority: high,documentation" \
  "$PM" "Week 3"

echo -e "\n  ${YELLOW}── WEEK 4: Payment & Notifikasi (1–7 Jun) ──${NC}"

create_issue \
  "[Backend] Integrasi Payment Gateway QRIS – Generate QR (FR-16, FR-19)" \
  "## Deskripsi\nIntegrasi dengan Midtrans/Xendit sandbox untuk generate QRIS.\n\n## Tasks\n- [ ] Setup Midtrans/Xendit SDK di Laravel\n- [ ] POST /api/payments/{payment_id}/qris (generate QR)\n- [ ] Simpan external_payment_id & update status PENDING\n- [ ] GET /api/payments/{payment_id} (cek status)\n- [ ] Konfigurasi .env untuk API key sandbox\n- [ ] Handle QRIS expiry\n\n## Referensi\n- API Doc 5.4\n- SRS FR-16, FR-19, NFR-06" \
  "role: Backend,week-4 (1-7 Jun),priority: high,module: payment" \
  "$BE1" "Week 4"

create_issue \
  "[Backend] Webhook Payment Callback & Status Update (FR-17, FR-20)" \
  "## Deskripsi\nImplementasi endpoint webhook untuk menerima callback dari payment gateway.\n\n## Tasks\n- [ ] POST /api/webhooks/payments (no auth, dengan signature verification)\n- [ ] Verifikasi signature/secret dari payment gateway (NFR-06)\n- [ ] Update Payment status: PAID / FAILED / EXPIRED\n- [ ] Jika DP PAID: trigger notifikasi event dp_paid\n- [ ] Jika Final PAID: update Order status → CLOSED + trigger final_paid\n- [ ] Logging semua webhook ke notification_logs\n- [ ] Test webhook dengan ngrok / Midtrans simulator\n\n## Referensi\n- API Doc 5.4, SRS FR-17, FR-20\n- Business Rule 4: Webhook wajib verifikasi signature" \
  "role: Backend,week-4 (1-7 Jun),priority: high,module: payment" \
  "$BE2" "Week 4"

create_issue \
  "[Backend] Integrasi n8n – Event Notifikasi (FR-21, FR-22)" \
  "## Deskripsi\nSetup n8n dan integrasi event notifikasi ke WhatsApp/Email.\n\n## Tasks\n- [ ] Setup n8n container (sudah ada di docker-compose)\n- [ ] Buat workflow n8n untuk setiap event:\n  - order_created → WA ke customer & provider\n  - order_accepted → WA ke customer\n  - order_rejected → WA ke customer\n  - dp_paid → WA ke customer & provider\n  - order_completed → WA ke customer (minta bayar pelunasan)\n  - final_paid → WA ke semua\n- [ ] POST /api/integrations/n8n/events\n- [ ] Konfigurasi WA provider di n8n (Fonnte/Wablas/dll)\n- [ ] Catat ke notification_logs setiap pengiriman\n\n## Referensi\n- API Doc 5.5\n- SRS FR-21, FR-22\n- Component Diagram: Backend → n8n → WA/Email" \
  "role: Backend,week-4 (1-7 Jun),priority: medium,module: notification" \
  "$BE3" "Week 4"

create_issue \
  "[Frontend] Screen: Pembayaran DP (QRIS)" \
  "## Deskripsi\nHalaman pembayaran DP dengan tampilan QR code.\n\n## Tasks\n- [ ] UI Halaman Bayar DP (informasi order, jumlah DP, QR code)\n- [ ] Integrasi POST /api/payments/{id}/qris\n- [ ] Tampilkan QR image dari qr_url\n- [ ] Timer countdown expiry QR\n- [ ] Polling GET /api/payments/{id} setiap 5 detik\n- [ ] Transisi ke 'DP Berhasil' setelah status PAID\n- [ ] Tombol regenerate QR jika expired\n\n## Referensi\n- API Doc 5.4, Business Process 3.3" \
  "role: Frontend,week-4 (1-7 Jun),priority: high,module: payment" \
  "$FE1" "Week 4"

create_issue \
  "[Frontend] Screen: Pembayaran Pelunasan (QRIS Final)" \
  "## Deskripsi\nHalaman pembayaran pelunasan setelah order COMPLETED.\n\n## Tasks\n- [ ] UI Halaman Bayar Final (detail harga final, sisa bayar)\n- [ ] Integrasi POST /api/payments/{final_id}/qris\n- [ ] Tampilkan QR pelunasan\n- [ ] Polling status pembayaran\n- [ ] Transisi ke 'Order Closed' setelah PAID\n- [ ] Tampilkan tombol Beri Rating setelah CLOSED\n\n## Referensi\n- API Doc 5.4, Business Process 3.5" \
  "role: Frontend,week-4 (1-7 Jun),priority: high,module: payment" \
  "$FE2" "Week 4"

create_issue \
  "[Frontend] Screen: Rating & Review + Dashboard Admin/Treasurer" \
  "## Deskripsi\nHalaman rating, review, dan dashboard khusus Admin & Treasurer.\n\n## Tasks\n- [ ] UI Form Rating (bintang 1–5, kolom komentar)\n- [ ] Integrasi POST /api/orders/{id}/review\n- [ ] UI Dashboard Treasurer (list transaksi, filter date & type)\n- [ ] Integrasi GET /api/treasurer/transactions\n- [ ] UI Admin: list provider, tombol verifikasi\n- [ ] Integrasi POST /api/admin/providers/{id}/verify\n\n## Referensi\n- API Doc 5.6, 5.7, SRS FR-23 s/d FR-26" \
  "role: Frontend,week-4 (1-7 Jun),priority: medium,module: review,module: admin" \
  "$FE3" "Week 4"

create_issue \
  "[Testing] Testing Payment Flow & Webhook" \
  "## Deskripsi\nPengujian alur pembayaran QRIS end-to-end dengan payment gateway sandbox.\n\n## Tasks\n- [ ] Test generate QRIS DP\n- [ ] Test webhook callback (simulasi PAID, FAILED, EXPIRED)\n- [ ] Test verifikasi signature webhook (valid & tampered)\n- [ ] Test otomasi closed order setelah Final PAID\n- [ ] Test timeout QR dan regenerate\n- [ ] Test notifikasi n8n terpicu sesuai event\n- [ ] Dokumentasikan hasil test\n\n## Referensi\n- API Doc 5.4, 5.5, SRS NFR-06" \
  "role: Testing,week-4 (1-7 Jun),priority: high,testing,module: payment,module: notification" \
  "$QA" "Week 4"

echo -e "\n  ${YELLOW}── WEEK 5: Frontend Integration & Polish (8–14 Jun) ──${NC}"

create_issue \
  "[Frontend] Integrasi end-to-end flow Customer (Order → Bayar DP → Closed)" \
  "## Deskripsi\nPastikan seluruh flow Customer dari awal sampai akhir berjalan mulus.\n\n## Tasks\n- [ ] Test flow: Register → Login → Cari Provider → Buat Order\n- [ ] Test flow: Bayar DP → Tunggu Provider Accept → Tunggu IN_PROGRESS\n- [ ] Test flow: Order COMPLETED → Bayar Final → CLOSED\n- [ ] Test flow: Beri Rating & Review\n- [ ] Fix navigasi antar screen\n- [ ] Handle semua error state (network error, expired token, dll)\n- [ ] Polish UI: loading state, empty state, error state\n\n## Referensi\n- Business Process 3.1 s/d 3.6" \
  "role: Frontend,week-5 (8-14 Jun),priority: high,module: order,module: payment" \
  "$FE1" "Week 5"

create_issue \
  "[Frontend] Integrasi end-to-end flow Provider" \
  "## Deskripsi\nPastikan seluruh flow Provider berjalan mulus.\n\n## Tasks\n- [ ] Test flow: Login Provider → Lihat order masuk → Terima\n- [ ] Test flow: Mulai kerja (IN_PROGRESS) setelah DP paid\n- [ ] Test flow: Input final_price → Complete order\n- [ ] UI notifikasi in-app untuk Provider\n- [ ] Polish UI Provider screens\n\n## Referensi\n- Business Process 3.4 s/d 3.5" \
  "role: Frontend,week-5 (8-14 Jun),priority: high,module: order" \
  "$FE2" "Week 5"

create_issue \
  "[Frontend] Polish UI, responsiveness & UX improvements" \
  "## Deskripsi\nPerbaikan visual dan pengalaman pengguna secara keseluruhan.\n\n## Tasks\n- [ ] Konsistensi warna, font, spacing di semua screen\n- [ ] Animasi transisi antar halaman\n- [ ] Splash screen & app icon\n- [ ] Handling offline state\n- [ ] Aksesibilitas (font size, contrast)\n- [ ] Test di berbagai ukuran layar Android\n\n## Referensi\n- SRS NFR-10 (Usability)" \
  "role: Frontend,week-5 (8-14 Jun),priority: medium,module: UI/UX" \
  "$FE3" "Week 5"

create_issue \
  "[Backend] Admin endpoints & Treasurer report (FR-25, FR-26)" \
  "## Deskripsi\nFinalisasi endpoint Admin dan Treasurer.\n\n## Tasks\n- [ ] POST /api/admin/providers/{id}/verify\n- [ ] GET /api/treasurer/transactions (dengan filter)\n- [ ] Middleware role guard: ADMIN, TREASURER\n- [ ] Response pagination untuk list transaksi\n- [ ] Pastikan semua endpoint terdokumentasi\n\n## Referensi\n- API Doc 5.7, SRS FR-25, FR-26" \
  "role: Backend,week-5 (8-14 Jun),priority: medium,module: admin" \
  "$BE1" "Week 5"

create_issue \
  "[Backend] Finalisasi & hardening API (security, validation, error handling)" \
  "## Deskripsi\nPastikan semua endpoint aman, tervalidasi, dan mengembalikan error yang konsisten.\n\n## Tasks\n- [ ] Review semua Form Request validation\n- [ ] Pastikan semua response mengikuti format API Doc\n- [ ] Rate limiting untuk endpoint sensitif\n- [ ] HTTPS enforcement\n- [ ] Review semua role middleware\n- [ ] Pastikan password hashing bcrypt\n- [ ] Remove debug logs & dd()\n\n## Referensi\n- SRS NFR-04 s/d NFR-07" \
  "role: Backend,week-5 (8-14 Jun),priority: high" \
  "$BE2,$BE3" "Week 5"

create_issue \
  "[Testing] Integration Testing – Full User Journey" \
  "## Deskripsi\nPengujian integrasi end-to-end untuk semua user journey.\n\n## Tasks\n- [ ] User journey Customer: dari register sampai review\n- [ ] User journey Provider: dari register sampai complete order\n- [ ] User journey Admin: verifikasi provider\n- [ ] User journey Treasurer: lihat laporan transaksi\n- [ ] Performance test: response time API < 1 detik (NFR-01)\n- [ ] Security test: akses cross-role harus 403\n- [ ] Test concurrent request (multiple order)\n\n## Referensi\n- SRS NFR-01 s/d NFR-10" \
  "role: Testing,week-5 (8-14 Jun),priority: high,testing" \
  "$QA" "Week 5"

create_issue \
  "[PM] Review dokumen final & persiapan demo UAS" \
  "## Deskripsi\nPersiapan presentasi dan pastikan semua dokumentasi lengkap.\n\n## Tasks\n- [ ] Update SRS jika ada perubahan implementasi\n- [ ] Pastikan API Documentation akurat dan up-to-date\n- [ ] Review semua diagram (Class, Sequence, Component, Deployment)\n- [ ] Siapkan demo script (skenario demo UAS)\n- [ ] Cek semua deliverable sesuai panduan UAS\n- [ ] Koordinasi jadwal gladi resik demo\n\n## Referensi\n- Panduan Tugas Besar Kelas A1" \
  "role: PM,week-5 (8-14 Jun),priority: high,documentation" \
  "$PM" "Week 5"

echo -e "\n  ${YELLOW}── WEEK 6: Testing, Bug Fix & Demo (15–18 Jun) ──${NC}"

create_issue \
  "[Testing] Final QA – Bug Fix Verification & Regression Test" \
  "## Deskripsi\nPengujian final sebelum demo UAS.\n\n## Tasks\n- [ ] Verify semua bug dari week sebelumnya sudah fixed\n- [ ] Regression test: pastikan fix tidak breaking fitur lain\n- [ ] Test di device Android fisik (minimal 2 device berbeda)\n- [ ] Test koneksi ke server production/staging\n- [ ] Buat laporan pengujian final\n- [ ] Sign-off QA: semua critical bug resolved\n\n## Referensi\n- TEST_PLAN_TukangDekat.md" \
  "role: Testing,week-6 (15-18 Jun),priority: high,testing" \
  "$QA" "Week 6"

create_issue \
  "[Backend] Deploy ke VPS & konfigurasi production" \
  "## Deskripsi\nDeploy aplikasi ke server VPS untuk demo UAS.\n\n## Tasks\n- [ ] Setup VPS (DigitalOcean/Niagahoster/dll)\n- [ ] Clone repo & konfigurasi .env production\n- [ ] docker-compose up di server\n- [ ] Setup domain / IP publik\n- [ ] Konfigurasi SSL (Let's Encrypt / self-signed)\n- [ ] Test semua endpoint dari URL production\n- [ ] Seed data dummy untuk demo\n\n## Referensi\n- Deployment Diagram, NFR-04" \
  "role: Backend,week-6 (15-18 Jun),priority: high" \
  "$BE1,$BE2" "Week 6"

create_issue \
  "[Frontend] Build APK release untuk demo" \
  "## Deskripsi\nBuild APK release Flutter untuk demo UAS.\n\n## Tasks\n- [ ] Update base URL ke production server\n- [ ] flutter build apk --release\n- [ ] Test APK di device fisik\n- [ ] Test semua fitur dengan server production\n- [ ] Upload APK ke Google Drive / release GitHub\n\n## Referensi\n- SRS 2.4 (Android min versi 8+)" \
  "role: Frontend,week-6 (15-18 Jun),priority: high" \
  "$FE1,$FE2,$FE3" "Week 6"

create_issue \
  "[PM] Laporan Akhir & Dokumentasi Final" \
  "## Deskripsi\nFinalisasi semua dokumentasi dan laporan untuk pengumpulan UAS.\n\n## Tasks\n- [ ] Update CHANGELOG.md dengan semua perubahan\n- [ ] Pastikan README.md lengkap (cara install, cara jalankan)\n- [ ] Laporan pengujian final dari QA\n- [ ] Screenshot demo semua fitur\n- [ ] Rekaman video demo (jika diminta)\n- [ ] Kumpulkan semua dokumen ke folder yang diminta dosen\n- [ ] Final review repo GitHub (hapus file tidak perlu)\n\n## Referensi\n- Panduan UAS Kelas A1" \
  "role: PM,week-6 (15-18 Jun),priority: high,documentation" \
  "$PM" "Week 6"

create_issue \
  "[ALL] Demo & Presentasi UAS" \
  "## Deskripsi\nPersiapan dan pelaksanaan demo TukangDekat untuk UAS.\n\n## Skenario Demo\n1. Register Customer & Provider\n2. Provider setup profil & layanan\n3. Customer cari provider & buat order\n4. Generate & bayar QRIS DP (sandbox)\n5. Provider terima order & mulai kerja\n6. Provider complete order + input final price\n7. Customer bayar pelunasan QRIS\n8. Order CLOSED – Customer beri rating\n9. Treasurer lihat laporan transaksi\n10. Admin verifikasi provider\n\n## Tasks\n- [ ] Gladi resik demo (14 Juni)\n- [ ] Siapkan device untuk demo\n- [ ] Backup APK & pastikan server live\n- [ ] Siapkan slide presentasi\n- [ ] Presentasi UAS (15–18 Juni)" \
  "role: PM,role: Backend,role: Frontend,role: Testing,week-6 (15-18 Jun),priority: high" \
  "$PM" "Week 6"

# =============================================================
# STEP 5 – Add all issues to Project Board
# =============================================================
echo -e "\n${CYAN}[5/5] Menambahkan issues ke Project Board...${NC}"

if [[ -n "$PROJECT_NUMBER" ]]; then
  ISSUE_NUMBERS=$(gh issue list --repo "$REPO" --state all --limit 100 --json number --jq '.[] | .number' 2>/dev/null | head -40)
  ADDED=0
  FAILED=0
  
  for ISSUE_NUM in $ISSUE_NUMBERS; do
    if gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --issue-number "$ISSUE_NUM" 2>/dev/null; then
      ((ADDED++))
    else
      ((FAILED++))
    fi
  done
  
  echo -e "  ${GREEN}✓${NC} $ADDED issues ditambahkan ke project"
  if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${YELLOW}⚠${NC} $FAILED issues gagal ditambahkan (mungkin duplikat)"
  fi
  echo -e "  ${CYAN}→ Lihat di: https://github.com/${PROJECT_OWNER}/projects/$PROJECT_NUMBER${NC}"
else
  echo -e "  ${YELLOW}⚠${NC} Project board belum ada — issues hanya di Issues tab"
  echo -e "  ${CYAN}→ Lihat di: https://github.com/${REPO}/issues${NC}"
fi

# =============================================================
# DONE
# =============================================================
echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗"
echo "║  ✓ Setup selesai!                                    ║"
echo "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Ringkasan yang dibuat:${NC}"
echo "  • Labels    : role, week, priority, module, status"
echo "  • Milestones: 6 milestone (Week 1–6)"
echo "  • Issues    : 35+ issues lengkap dengan assignee & label"
echo "  • Project   : Kanban board $PROJECT_NAME"
echo ""
echo -e "${YELLOW}⚠  PENTING – Ganti username GitHub di variabel ini:${NC}"
echo "  PM  = $PM"
echo "  BE1 = $BE1"
echo "  BE2 = $BE2"
echo "  BE3 = $BE3"
echo "  FE1 = $FE1"
echo "  FE2 = $FE2"
echo "  FE3 = $FE3"
echo "  QA  = $QA"
echo ""
echo -e "${CYAN}Lihat GitHub Project di:${NC}"
echo "  https://github.com/${REPO}/issues"
echo "  https://github.com/${REPO}/milestones"
echo ""