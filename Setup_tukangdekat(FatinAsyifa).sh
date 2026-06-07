#!/usr/bin/env bash
# =============================================================
#  Project Aplikasi TukangDekat – Automated Setup Script
#  Dibuat oleh: Fatinasy7 (Backend Developer 3)
#  Target: Project_Aplikasi_TukangDekat
#  Tanggal: 4 Juni 2026
#
#  FITUR:
#  - Clone/initialize project
#  - Setup environment variables
#  - Install dependencies
#  - Configure database
#  - Setup Docker services
#  - Initialize Git branches
#  - Create PR tracking
#
#  CARA PAKAI:
#  1. bash "Setup_tukangdekat(FatinAsyifa).sh"
#  2. Follow prompts
# =============================================================

set -e

# ─── COLOR CODES ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# ─── CONFIG ───────────────────────────────────────────────────
PROJECT_NAME="Project_Aplikasi_TukangDekat"
PROJECT_DIR="${HOME}/${PROJECT_NAME}"
GITHUB_REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"
BACKEND_DIR="${PROJECT_DIR}/backend"
MOBILE_DIR="${PROJECT_DIR}/mobile"
DOCS_DIR="${PROJECT_DIR}/docs"

# Backend Config
BE_ENV_FILE="${BACKEND_DIR}/.env"
BE_ENV_EXAMPLE="${BACKEND_DIR}/.env.example"
BE_PORT=8000
DB_NAME="tukangdekat"
DB_USER="root"
DB_PASS="password"

# Mobile Config
FLUTTER_SDK_CHECK=false

# ─── FUNCTIONS ───────────────────────────────────────────────

print_header() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  $1"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

print_step() {
  echo -e "${BLUE}→${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

check_command() {
  if command -v "$1" &> /dev/null; then
    print_success "$1 terdeteksi"
    return 0
  else
    print_error "$1 tidak ditemukan"
    return 1
  fi
}

# ─── MAIN SCRIPT ──────────────────────────────────────────────

print_header "Project Aplikasi TukangDekat - Setup Otomatis"
echo -e "${CYAN}Target Project:${NC} $PROJECT_NAME"
echo -e "${CYAN}Backend Directory:${NC} $BACKEND_DIR"
echo -e "${CYAN}Mobile Directory:${NC} $MOBILE_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 1: Check Prerequisites
# ─────────────────────────────────────────────────────────────
print_header "[1/8] Checking Prerequisites"

echo -e "${YELLOW}Checking required tools...${NC}"
MISSING_TOOLS=0

check_command "git" || ((MISSING_TOOLS++))
check_command "docker" || ((MISSING_TOOLS++))
check_command "docker-compose" || ((MISSING_TOOLS++))
check_command "php" || ((MISSING_TOOLS++))
check_command "composer" || ((MISSING_TOOLS++))

if command -v flutter &> /dev/null; then
  FLUTTER_SDK_CHECK=true
  print_success "Flutter SDK terdeteksi"
else
  print_warning "Flutter SDK belum terinstall (opsional)"
fi

if [[ $MISSING_TOOLS -gt 0 ]]; then
  echo ""
  print_error "Ada $MISSING_TOOLS tools yang belum terinstall"
  echo -e "${YELLOW}Silakan install tools berikut:${NC}"
  echo "  - Git: https://git-scm.com/download"
  echo "  - Docker: https://docs.docker.com/get-docker/"
  echo "  - PHP 8.2+: https://www.php.net/downloads"
  echo "  - Composer: https://getcomposer.org/download/"
  echo "  - Flutter (opsional): https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo -e "${GREEN}✓ Semua prerequisite terpenuhi${NC}\n"

# ─────────────────────────────────────────────────────────────
# STEP 2: Clone atau Verifikasi Project
# ─────────────────────────────────────────────────────────────
print_header "[2/8] Verify/Clone Project Repository"

if [[ -d "$PROJECT_DIR" ]]; then
  print_warning "Direktori $PROJECT_NAME sudah ada"
  read -p "Gunakan direktori yang ada? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup dibatalkan"
    exit 1
  fi
else
  print_step "Cloning repository..."
  git clone "https://github.com/${GITHUB_REPO}.git" "$PROJECT_DIR"
  print_success "Repository berhasil di-clone ke $PROJECT_DIR"
fi

cd "$PROJECT_DIR"
print_success "Working directory: $PROJECT_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 3: Setup Git Branches
# ─────────────────────────────────────────────────────────────
print_header "[3/8] Setup Git Branches"

echo -e "${YELLOW}Current branch:${NC} $(git branch --show-current)"

# Buat atau update tracking branches
TRACKING_BRANCHES=(
  "feature/backend-89-90-foundation-tracking"
  "feature/backend-101-103-core-api-tracking"
  "feature/backend-109-111-payments-webhooks-tracking"
  "feature/backend-119-124-finalization-deploy-tracking"
  "feature/frontend-91-99-foundation-tracking"
  "feature/frontend-104-106-service-flow-tracking"
  "feature/frontend-112-114-payment-flow-tracking"
  "feature/frontend-116-125-polish-release-tracking"
)

# Buat working branches untuk BE3
WORKING_BRANCHES=(
  "feature/backend-123-deploy-smoke"
  "feature/backend-124-n8n-integration"
  "feature/backend-125-api-hardening"
)

echo -e "${YELLOW}Membuat/updating tracking branches...${NC}"
for branch in "${TRACKING_BRANCHES[@]}"; do
  if ! git show-ref --quiet "refs/heads/$branch"; then
    git fetch origin "$branch" 2>/dev/null && git checkout "$branch" 2>/dev/null || {
      print_warning "Tracking branch $branch tidak ditemukan di remote"
    }
  else
    print_success "Branch $branch sudah ada"
  fi
done

echo -e "${YELLOW}Checking working branches untuk BE3...${NC}"
for branch in "${WORKING_BRANCHES[@]}"; do
  if git show-ref --quiet "refs/heads/$branch"; then
    print_success "Branch $branch sudah ada"
  else
    print_warning "Branch $branch belum ada"
  fi
done

git checkout main 2>/dev/null || git checkout develop 2>/dev/null || git checkout -q main
print_success "Switched ke main branch"
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 4: Backend Setup
# ─────────────────────────────────────────────────────────────
print_header "[4/8] Setup Backend (Laravel)"

cd "$BACKEND_DIR"
print_step "Backend directory: $BACKEND_DIR"

# Copy .env file
if [[ ! -f "$BE_ENV_FILE" ]]; then
  if [[ -f "$BE_ENV_EXAMPLE" ]]; then
    print_step "Creating .env dari .env.example..."
    cp "$BE_ENV_EXAMPLE" "$BE_ENV_FILE"
  else
    print_warning ".env.example tidak ditemukan, creating basic .env..."
    cat > "$BE_ENV_FILE" << 'EOF'
APP_NAME="TukangDekat"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=tukangdekat
DB_USERNAME=root
DB_PASSWORD=password

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=cookie
EOF
  fi
  print_success ".env file created"
else
  print_success ".env file sudah ada"
fi

# Generate APP_KEY jika belum ada
if ! grep -q "APP_KEY=base64:" "$BE_ENV_FILE"; then
  print_step "Generating APP_KEY..."
  php artisan key:generate 2>/dev/null || print_warning "APP_KEY generation skipped"
fi

# Install dependencies
if [[ ! -d "vendor" ]]; then
  print_step "Installing PHP dependencies dengan Composer..."
  composer install --no-interaction
  print_success "PHP dependencies installed"
else
  print_success "vendor directory sudah ada"
  read -p "Run composer install untuk update dependencies? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    composer install --no-interaction
  fi
fi

# Database setup
echo -e "${YELLOW}Database Configuration:${NC}"
read -p "Database name (default: tukangdekat): " -r DB_NAME_INPUT
DB_NAME="${DB_NAME_INPUT:-tukangdekat}"

read -p "Database user (default: root): " -r DB_USER_INPUT
DB_USER="${DB_USER_INPUT:-root}"

read -sp "Database password (default: password): " -r DB_PASS_INPUT
echo ""
DB_PASS="${DB_PASS_INPUT:-password}"

# Update .env dengan database config
sed -i.bak "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$BE_ENV_FILE"
sed -i.bak "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USER/" "$BE_ENV_FILE"
sed -i.bak "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" "$BE_ENV_FILE"
rm -f "$BE_ENV_FILE.bak"

print_success "Database configuration updated"
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 5: Docker Setup
# ─────────────────────────────────────────────────────────────
print_header "[5/8] Docker Setup"

cd "$PROJECT_DIR"

if [[ -f "docker-compose.yml" ]]; then
  print_step "docker-compose.yml found"
  
  read -p "Build dan start Docker containers? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Building Docker images..."
    docker-compose build
    
    print_step "Starting Docker containers..."
    docker-compose up -d
    
    sleep 5
    
    # Run migrations
    print_step "Running database migrations..."
    docker-compose exec -T laravel-api php artisan migrate --force 2>/dev/null || print_warning "Migrations skipped"
    
    # Seed database
    read -p "Seed database dengan dummy data? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker-compose exec -T laravel-api php artisan db:seed --force 2>/dev/null || print_warning "Seeding skipped"
    fi
    
    print_success "Docker containers running"
    echo -e "${CYAN}Services:${NC}"
    docker-compose ps
  fi
else
  print_warning "docker-compose.yml tidak ditemukan"
fi
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 6: Mobile Setup (Flutter)
# ─────────────────────────────────────────────────────────────
print_header "[6/8] Setup Mobile (Flutter - Optional)"

if [[ "$FLUTTER_SDK_CHECK" == true ]]; then
  cd "$MOBILE_DIR"
  print_step "Mobile directory: $MOBILE_DIR"
  
  read -p "Setup Flutter dependencies? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Running flutter pub get..."
    flutter pub get
    
    print_step "Running flutter pub upgrade..."
    flutter pub upgrade
    
    print_success "Flutter dependencies updated"
  fi
else
  print_warning "Flutter SDK tidak terinstall, skip mobile setup"
fi
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 7: Documentation & Reference
# ─────────────────────────────────────────────────────────────
print_header "[7/8] Documentation Setup"

cd "$PROJECT_DIR"

if [[ ! -f "QUICK_START.md" ]]; then
  cat > "QUICK_START_SETUP.md" << 'EOF'
# Quick Start Guide - Project_Aplikasi_TukangDekat

## Backend (Laravel)

### Prerequisites
- PHP 8.2+
- Composer
- MySQL/MariaDB
- Redis (untuk queue & cache)

### Setup
```bash
cd backend
cp .env.example .env
php artisan key:generate
composer install
php artisan migrate
php artisan db:seed
```

### Run Server
```bash
php artisan serve
# atau dengan docker-compose up
```

### Queue Worker
```bash
php artisan queue:work
# atau dengan supervisor
sudo supervisorctl start laravel-queue:*
```

### Testing
```bash
php artisan test
# atau
vendor/bin/phpunit
```

## Mobile (Flutter)

### Prerequisites
- Flutter 3.22+
- Android SDK 33+
- iOS SDK 12+ (untuk macOS)

### Setup
```bash
cd mobile
flutter pub get
flutter pub upgrade
```

### Run
```bash
# Android emulator
flutter run

# iOS simulator
flutter run -d iPhone

# Physical device
flutter run -d <device_id>
```

### Build
```bash
# APK Release
flutter build apk --release

# iOS Release
flutter build ios --release
```

## API Documentation

- Swagger UI: http://localhost:8000/api/documentation
- Postman Collection: docs/postman/TukangDekat_API.postman_collection.json

## Common Issues

### Database Connection Error
- Pastikan MySQL running
- Check `.env` database configuration
- Run: `php artisan migrate:refresh --seed`

### Queue Not Processing
- Check Redis connection
- Verify `config/queue.php` settings
- Run queue worker: `php artisan queue:work`

### Flutter Build Error
- Run: `flutter clean`
- Run: `flutter pub get`
- Run: `flutter run`

## Deployment

Lihat: `backend/DEPLOYMENT.md` dan `backend/RUNBOOK.md`
EOF
  print_success "QUICK_START_SETUP.md created"
fi

# Update PROGRESS_TRACKING.md
if [[ -f "PROGRESS_TRACKING.md" ]]; then
  print_success "PROGRESS_TRACKING.md exists"
  echo -e "${CYAN}Last update:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# STEP 8: Create PR Tracking Instructions
# ─────────────────────────────────────────────────────────────
print_header "[8/8] PR Tracking Setup"

cat > "PR_TRACKING_GUIDE_BE3.md" << 'EOF'
# PR Tracking Guide untuk BE3 (Fatinasy7)

## Workflow

### 1. Branch Naming Convention
- Feature: `feature/backend-XXX-deskripsi-singkat`
- Bugfix: `bugfix/backend-XXX-deskripsi`
- Hotfix: `hotfix/backend-XXX-deskripsi`

Contoh: `feature/backend-123-deploy-smoke`

### 2. Commit Message Format
```
type: brief description

- Detailed change 1
- Detailed change 2

Issue: #123
Related: feature/backend-123-deploy-smoke
```

Tipe: feat, fix, refactor, test, docs, chore

### 3. Pull Request Template
```markdown
## 📝 Description
Singkat deskripsi perubahan

## 🎯 Issue/Feature
- Closes #XXX
- Related: feature/backend-123-deploy-smoke

## ✅ Checklist
- [ ] Code tested locally
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Database migration included (jika perlu)

## 📊 Related Files
- backend/app/...
- backend/tests/...

## 🔍 Testing
Cara untuk test perubahan:
1. Checkout branch ini
2. `composer install`
3. `php artisan migrate`
4. `php artisan test`
```

### 4. Membuat PR di GitHub

```bash
# 1. Push branch
git push origin feature/backend-123-deploy-smoke

# 2. Create PR via CLI
gh pr create \
  --title "[Backend] Migrasi staging, queue worker, dan smoke test" \
  --body-file PR_BODY.md \
  --base main \
  --head feature/backend-123-deploy-smoke

# 3. Atau via GitHub Web UI
# - Go to https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/pulls
# - Click "New Pull Request"
# - Select head branch: feature/backend-123-deploy-smoke
# - Select base branch: main
```

### 5. Review Checklist

Sebelum merging, pastikan:
- ✅ Semua tests passed
- ✅ Code review approved
- ✅ No conflicts dengan main
- ✅ Branch up-to-date dengan main
- ✅ Database migration tested
- ✅ Documentation updated
- ✅ Deployment tested di staging

### 6. Merging
```bash
# Option 1: Via CLI
gh pr merge <PR_NUMBER> --squash

# Option 2: Via Web UI
# Click "Squash and Merge" atau "Create a merge commit"
```

### 7. Update Progress Tracking
Setelah merge, update:
- PROGRESS_TRACKING.md - Pindahkan task ke "Sudah Selesai"
- GitHub Issues - Close issue terkait
- GitHub Project Board - Move card ke "Done"

## BE3 Tasks Timeline

| Week | Task | Branch | Status |
|------|------|--------|--------|
| W4 | Deploy-Smoke | `feature/backend-123-deploy-smoke` | 🔄 In Progress |
| W4 | n8n Integration | `feature/backend-124-n8n-integration` | ❌ Pending |
| W5 | API Hardening | `feature/backend-125-api-hardening` | ❌ Pending |

## Useful Commands

```bash
# Update branch dari main
git fetch origin
git rebase origin/main

# Interactive rebase (squash commits)
git rebase -i origin/main

# Force push (hati-hati!)
git push --force-with-lease origin feature/backend-XXX

# View diff sebelum push
git diff origin/main...feature/backend-XXX

# Check branch protection rules
gh api repos/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/branches/main --json protectionRules
```

## Support

- PM: @radenelsa7-bot
- BE1: @NabilahAsana
- BE2: @Fajar1180
- QA: @aldyrmdny-lab

Untuk bantuan, buat issue atau ping di GitHub.
EOF

print_success "PR_TRACKING_GUIDE_BE3.md created"
echo ""

# ─────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────
print_header "✅ Setup Selesai!"

echo -e "${CYAN}Project Setup Summary:${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} Project cloned: $PROJECT_DIR"
echo -e "  ${GREEN}✓${NC} Git branches configured"
echo -e "  ${GREEN}✓${NC} Backend (Laravel) configured"
echo -e "  ${GREEN}✓${NC} Docker environment ready"
if [[ "$FLUTTER_SDK_CHECK" == true ]]; then
  echo -e "  ${GREEN}✓${NC} Mobile (Flutter) configured"
fi
echo -e "  ${GREEN}✓${NC} Documentation created"
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo "  1. Backend Development:"
echo "     cd $BACKEND_DIR"
echo "     git checkout feature/backend-123-deploy-smoke"
echo "     php artisan serve"
echo ""
echo "  2. Database Operations:"
echo "     php artisan migrate:fresh --seed"
echo "     php artisan queue:work"
echo ""
echo "  3. Testing:"
echo "     php artisan test"
echo "     bash deploy/smoke-test.sh"
echo ""
echo "  4. Create PR:"
echo "     gh pr create --title \"[Backend] ...\" --base main"
echo ""

echo -e "${CYAN}Documentation:${NC}"
echo "  - ANALISIS_BE3_FATINASY7.md"
echo "  - PR_TRACKING_GUIDE_BE3.md"
echo "  - QUICK_START_SETUP.md"
echo "  - PROGRESS_TRACKING.md"
echo ""

echo -e "${CYAN}Useful Links:${NC}"
echo "  - GitHub Repo: https://github.com/${GITHUB_REPO}"
echo "  - Issues: https://github.com/${GITHUB_REPO}/issues"
echo "  - Project Board: https://github.com/${GITHUB_REPO}/projects"
echo ""

echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
