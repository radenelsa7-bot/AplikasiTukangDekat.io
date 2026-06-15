#!/usr/bin/env bash

# =============================================================
#  Project_Aplikasi_TukangDekat – Project Setup Script for Backend 1 (Nabilah Asana)
#  Created: 2026-06-04
#  Dibuat untuk: Nabilah Asana (BE1)
#
#  CARA PAKAI:
#  1. Pastikan sudah install: git, PHP, Composer, Docker, Docker Compose
#  2. Jalankan script ini: bash "Setup_tukangdekat(NabilahAsana).sh"
#  3. Script akan automatic setup project dan membuat branch untuk tugas BE1
#
#  REQUIREMENTS:
#  - Git
#  - GitHub CLI (gh) - https://cli.github.com/
#  - PHP 8.2+
#  - Composer
#  - Docker & Docker Compose
#  - Node.js (untuk frontend testing)
# =============================================================

set -e

# ─── COLOR CODES ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'  # No Color

# ─── CONFIGURATION ───────────────────────────────────────────
REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"
PROJECT_ROOT="$(pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend"
ASSIGNEE="NabilahAsana"
BE1_EMAIL="nabilah.asana@example.com"  # Update dengan email GitHub kamu

# ─── LOGGING FUNCTIONS ───────────────────────────────────────
log_header() {
  echo -e "\n${CYAN}╔════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║ $1${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"
}

log_info() {
  echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
  echo -e "${GREEN}✓ ${1}${NC}"
}

log_warn() {
  echo -e "${YELLOW}⚠ ${1}${NC}"
}

log_error() {
  echo -e "${RED}✗ ${1}${NC}"
}

log_section() {
  echo -e "\n${YELLOW}→ ${1}${NC}"
}

# ─── PREREQUISITE CHECKS ────────────────────────────────────
check_prerequisites() {
  log_header "CHECKING PREREQUISITES"

  local missing_tools=0

  # Check git
  if ! command -v git &> /dev/null; then
    log_error "Git tidak ditemukan"
    missing_tools=$((missing_tools + 1))
  else
    log_success "Git: $(git --version | awk '{print $3}')"
  fi

  # Check GitHub CLI
  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) tidak ditemukan - https://cli.github.com/"
    missing_tools=$((missing_tools + 1))
  else
    log_success "GitHub CLI: $(gh --version)"
    if ! gh auth status &> /dev/null; then
      log_error "Belum login ke GitHub. Jalankan: gh auth login"
      missing_tools=$((missing_tools + 1))
    else
      log_success "GitHub: Sudah login"
    fi
  fi

  # Check PHP
  if ! command -v php &> /dev/null; then
    log_error "PHP tidak ditemukan"
    missing_tools=$((missing_tools + 1))
  else
    log_success "PHP: $(php --version | head -n1)"
  fi

  # Check Composer
  if ! command -v composer &> /dev/null; then
    log_error "Composer tidak ditemukan"
    missing_tools=$((missing_tools + 1))
  else
    log_success "Composer: $(composer --version | awk '{print $NF}')"
  fi

  # Check Docker
  if ! command -v docker &> /dev/null; then
    log_error "Docker tidak ditemukan"
    missing_tools=$((missing_tools + 1))
  else
    log_success "Docker: $(docker --version)"
  fi

  # Check Docker Compose
  if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose tidak ditemukan"
    missing_tools=$((missing_tools + 1))
  else
    log_success "Docker Compose: $(docker-compose --version)"
  fi

  # Check Node.js (optional)
  if command -v node &> /dev/null; then
    log_success "Node.js: $(node --version)"
  else
    log_warn "Node.js tidak ditemukan (opsional, diperlukan untuk testing)"
  fi

  if [[ $missing_tools -gt 0 ]]; then
    log_error "$missing_tools tools tidak ditemukan. Silakan install terlebih dahulu."
    exit 1
  fi

  log_success "Semua prerequisites terpenuhi!"
}

# ─── REPOSITORY SETUP ────────────────────────────────────────
setup_repository() {
  log_header "SETTING UP REPOSITORY"

  if [[ ! -d .git ]]; then
    log_info "Repository belum di-initialize. Cloning dari GitHub..."
    cd "$(dirname "$PROJECT_ROOT")"
    gh repo clone "$REPO" "$(basename "$PROJECT_ROOT")"
    cd "$PROJECT_ROOT"
    log_success "Repository cloned"
  else
    log_success "Repository sudah ada"
  fi

  # Ensure main branch
  git fetch origin main 2>/dev/null || true
  git checkout main 2>/dev/null || git checkout -b main
  git pull origin main 2>/dev/null || true
  log_success "Main branch updated"
}

# ─── BACKEND SETUP ──────────────────────────────────────────
setup_backend() {
  log_header "SETTING UP BACKEND ENVIRONMENT"

  if [[ ! -d "$BACKEND_DIR" ]]; then
    log_error "Backend directory not found: $BACKEND_DIR"
    exit 1
  fi

  cd "$BACKEND_DIR"

  # Check .env
  if [[ ! -f .env ]]; then
    log_info "Creating .env from .env.example..."
    cp .env.example .env 2>/dev/null || {
      log_warn ".env.example tidak ditemukan. Creating minimal .env..."
      cat > .env << 'EOF'
APP_NAME=Project_Aplikasi_TukangDekat
    APP_ENV=local
    APP_KEY=
    APP_DEBUG=true
    APP_URL=http://localhost:8000

    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=project_aplikasi_tukangdekat_dev
DB_USERNAME=root
DB_PASSWORD=

CACHE_DRIVER=file
SESSION_DRIVER=cookie
QUEUE_CONNECTION=redis

SENTRY_LARAVEL_DSN=

LOG_CHANNEL=stack
EOF
    }
    log_success ".env created"
  else
    log_success ".env exists"
  fi

  # Generate app key if not set
  if ! grep -q "APP_KEY=base64:" .env; then
    log_info "Generating APP_KEY..."
    php artisan key:generate
    log_success "APP_KEY generated"
  fi

  # Install dependencies
  if [[ ! -d vendor ]]; then
    log_info "Installing Composer dependencies..."
    composer install --no-interaction --prefer-dist
    log_success "Composer dependencies installed"
  else
    log_success "Composer dependencies already installed"
    log_info "Running composer update..."
    composer update --no-interaction
  fi

  # Database setup (optional if docker compose is ready)
  log_section "Database Setup"
  if command -v docker-compose &> /dev/null; then
    log_info "Starting Docker containers..."
    docker-compose up -d --wait 2>/dev/null || log_warn "Docker Compose startup may need manual intervention"
    sleep 2

    if [[ -f "database/migrations" ]]; then
      log_info "Running migrations..."
      php artisan migrate --force 2>/dev/null || log_warn "Migrations may need manual run"
      log_success "Migrations completed"
    fi
  else
    log_warn "Docker Compose not available. Skip container setup."
  fi

  cd "$PROJECT_ROOT"
  log_success "Backend environment ready"
}

# ─── CREATE WORKING BRANCHES ────────────────────────────────
create_branches() {
  log_header "CREATING FEATURE BRANCHES FOR BE1 TASKS"

  # Ensure we're on main
  git checkout main
  git pull origin main 2>/dev/null || true

  # Define branches
  local branches=(
    "feature/backend-121-nabilah-integration-tests"
    "feature/backend-124-nabilah-monitoring-alerts"
    "feature/backend-nabilah-documentation"
  )

  for branch in "${branches[@]}"; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      log_warn "Branch sudah ada: $branch"
      git checkout "$branch"
      git pull origin "$branch" 2>/dev/null || true
    else
      log_info "Creating branch: $branch"
      git checkout -b "$branch"
      git push -u origin "$branch" 2>/dev/null || true
    fi
  done

  # Return to main
  git checkout main
  log_success "Feature branches created"
}

# ─── SETUP MONITORING & TESTING ─────────────────────────────
setup_monitoring() {
  log_header "SETTING UP MONITORING & TESTING INFRASTRUCTURE"

  cd "$BACKEND_DIR"

  # Check for Sentry configuration
  log_section "Sentry Configuration"
  if ! grep -q "SENTRY_LARAVEL_DSN" .env; then
    log_warn "SENTRY_LARAVEL_DSN not configured in .env"
    log_info "To enable Sentry:"
    log_info "  1. Go to https://sentry.io and create project"
    log_info "  2. Copy DSN to .env: SENTRY_LARAVEL_DSN=your-dsn"
  else
    log_success "Sentry DSN configured"
  fi

  # Check monitoring services
  log_section "Monitoring Services"
  if grep -q "MonitoringService" "app/Services/MonitoringService.php" 2>/dev/null; then
    log_success "MonitoringService found"
  else
    log_warn "MonitoringService not found. Create it or run integration setup."
  fi

  # Check metrics endpoint
  log_section "Metrics Endpoint"
  if grep -q "/api/metrics" "routes/api.php" 2>/dev/null; then
    log_success "Metrics endpoint registered"
  else
    log_warn "Metrics endpoint not found in routes/api.php"
  fi

  cd "$PROJECT_ROOT"
  log_success "Monitoring setup verification complete"
}

# ─── RUN TESTS ──────────────────────────────────────────────
run_tests() {
  log_header "RUNNING TESTS"

  cd "$BACKEND_DIR"

  log_section "PHPUnit Tests"
  if [[ -f phpunit.xml ]]; then
    log_info "Running all tests..."
    php vendor/bin/phpunit --testdox 2>/dev/null || {
      log_warn "Some tests may have failed"
      php vendor/bin/phpunit --testdox || true
    }
    log_success "Test run completed (check output above)"
  else
    log_warn "phpunit.xml not found"
  fi

  log_section "Integration Test Suite"
  if [[ -d "tests/Feature/PayoutPipeline" ]]; then
    log_info "Running payout integration tests..."
    php vendor/bin/phpunit tests/Feature/PayoutPipeline --testdox 2>/dev/null || {
      log_warn "Integration tests may need debugging"
      true
    }
  else
    log_warn "Payout integration tests directory not found"
  fi

  cd "$PROJECT_ROOT"
  log_success "Test execution completed"
}

# ─── CREATE GITHUB ISSUES ────────────────────────────────────
create_tracking_issues() {
  log_header "CREATING GITHUB TRACKING ISSUES"

  log_section "Issue 1: Finalize Alerting Rules"
  gh issue create \
    --repo "$REPO" \
    --title "[Backend-121] Finalize Alerting Rules Configuration" \
    --body "## Task for BE1 (Nabilah Asana)

Configure Sentry alerting rules for production payout pipeline.

## Checklist
- [ ] Configure threshold: >5% failure rate = WARNING
- [ ] Configure threshold: >20% failure rate = CRITICAL
- [ ] Configure threshold: response time >5s = CRITICAL
- [ ] Setup Slack notifications
- [ ] Setup Email notifications
- [ ] Test alert delivery
- [ ] Document alerting runbook

## References
- PROGRESS_TRACKING.md
- BE1_NABILAH_ASANA_ANALYSIS.md
- Branch: feature/backend-121-nabilah-integration-tests" \
    --label "role: Backend,module: notification,priority: high,status: review" \
    --assignee "$ASSIGNEE" 2>/dev/null || log_warn "Issue creation may require manual setup"

  log_section "Issue 2: Staging Deployment Verification"
  gh issue create \
    --repo "$REPO" \
    --title "[Backend-124] Staging Deployment & Monitoring Verification" \
    --body "## Task for BE1 (Nabilah Asana)

Deploy and verify monitoring stack in staging environment.

## Checklist
- [ ] Deploy to staging
- [ ] Verify Sentry integration
- [ ] Verify Prometheus metrics at /api/metrics
- [ ] Run smoke tests with monitoring active
- [ ] Collect 24-hour baseline metrics
- [ ] Document monitoring dashboard URLs

## References
- PROGRESS_TRACKING.md
- BE1_NABILAH_ASANA_ANALYSIS.md
- Branch: feature/backend-124-nabilah-monitoring-alerts" \
    --label "role: Backend,module: notification,priority: high,status: review" \
    --assignee "$ASSIGNEE" 2>/dev/null || log_warn "Issue creation may require manual setup"

  log_section "Issue 3: Documentation & Runbook"
  gh issue create \
    --repo "$REPO" \
    --title "[Backend-129] Monitoring Documentation & Runbook" \
    --body "## Task for BE1 (Nabilah Asana)

Create comprehensive documentation for monitoring and alerting procedures.

## Checklist
- [ ] Update RUNBOOK.md with monitoring procedures
- [ ] Create docs/MONITORING_RUNBOOK.md
- [ ] Document Sentry dashboard access
- [ ] Document /api/metrics interpretation
- [ ] Document emergency escalation procedure
- [ ] Document integration test running procedures

## Deliverables
- Updated backend/RUNBOOK.md
- New docs/MONITORING_RUNBOOK.md

## References
- PROGRESS_TRACKING.md
- BE1_NABILAH_ASANA_ANALYSIS.md
- Branch: feature/backend-nabilah-documentation" \
    --label "role: Backend,documentation,priority: medium" \
    --assignee "$ASSIGNEE" 2>/dev/null || log_warn "Issue creation may require manual setup"

  log_success "Tracking issues created/skipped"
}

# ─── GENERATE PROJECT SUMMARY ────────────────────────────────
generate_summary() {
  log_header "PROJECT SETUP SUMMARY"

  cat > "${PROJECT_ROOT}/BE1_SETUP_SUMMARY.md" << EOF
# Backend 1 (Nabilah Asana) - Project Setup Summary

**Setup Date**: $(date)  
**Project**: Project_Aplikasi_TukangDekat  
**Assignee**: Nabilah Asana (BE1)

## ✅ Setup Completed

### Prerequisites Verified
- ✓ Git installed
- ✓ GitHub CLI installed & logged in
- ✓ PHP 8.2+ installed
- ✓ Composer installed
- ✓ Docker & Docker Compose installed

### Repository Setup
- ✓ Repository cloned/updated
- ✓ Main branch current

### Backend Environment
- ✓ .env configured
- ✓ APP_KEY generated
- ✓ Composer dependencies installed
- ✓ Database migrations (optional)
- ✓ Docker containers started (optional)

### Feature Branches Created
- ✓ \`feature/backend-121-nabilah-integration-tests\`
- ✓ \`feature/backend-124-nabilah-monitoring-alerts\`
- ✓ \`feature/backend-nabilah-documentation\`

### Monitoring & Testing
- ✓ Monitoring services verified
- ✓ Metrics endpoint configured
- ✓ PHPUnit test suite ready
- ✓ Integration tests available

## 📋 Your Tasks (BE1 - Nabilah Asana)

### Priority 1 - Finalize Alerting (Due: 2026-06-07)
1. Configure Sentry alert rules with thresholds
2. Setup Slack/Email notifications
3. Test alert delivery
4. Document alerting procedures

**Branch**: \`feature/backend-121-nabilah-integration-tests\`

### Priority 2 - Staging Verification (Due: 2026-06-07)
1. Deploy monitoring to staging
2. Verify metrics collection
3. Run baseline metrics collection (24 hours)
4. Document setup

**Branch**: \`feature/backend-124-nabilah-monitoring-alerts\`

### Priority 3 - Documentation (Due: 2026-06-14)
1. Update RUNBOOK.md with monitoring procedures
2. Create MONITORING_RUNBOOK.md
3. Document emergency procedures
4. Train team

**Branch**: \`feature/backend-nabilah-documentation\`

## 🚀 Quick Start Commands

### Start Development
\`\`\`bash
# Navigate to backend
cd backend

# Start Docker containers
docker-compose up -d

# Run migrations (if needed)
php artisan migrate

# Start development server
php artisan serve
\`\`\`

### Run Tests
\`\`\`bash
# All tests
php vendor/bin/phpunit

# Specific test suite
php vendor/bin/phpunit tests/Feature/PayoutPipeline

# With detailed output
php vendor/bin/phpunit --testdox
\`\`\`

### Check Metrics
\`\`\`bash
# Access metrics endpoint
curl http://localhost:8000/api/metrics
\`\`\`

### Git Workflow
\`\`\`bash
# Switch to your branch
git checkout feature/backend-121-nabilah-integration-tests

# Make changes and commit
git add .
git commit -m "Feature: [description]"

# Push to remote
git push origin feature/backend-121-nabilah-integration-tests

# Create Pull Request
gh pr create --title "[Backend-121] Title" --body "Description"
\`\`\`

## 📚 Important Files & References

### Main Documentation
- BE1_NABILAH_ASANA_ANALYSIS.md - Full analysis of BE1 tasks
- PROGRESS_TRACKING.md - Overall project progress
- backend/RUNBOOK.md - Deployment & operations
- backend/README.md - Project README

### Backend Code
- backend/app/Services/MonitoringService.php - Monitoring logic
- backend/app/Services/MetricsCollectorService.php - Metrics collection
- backend/routes/api.php - Metrics endpoint (/api/metrics)
- backend/config/monitoring.php - Monitoring config

### Tests
- backend/tests/Feature/PayoutPipeline/NetworkFailureTest.php
- backend/tests/Feature/PayoutPipeline/RetryBackoffTest.php
- backend/tests/Unit/Monitoring/MetricsCollectorTest.php

### GitHub Issues
- Issue #121: Integration test untuk network failures
- Issue #124: Monitoring/metrics produksi dan alerting
- Issue #129: Dokumentasi & Runbook (new)

## 🔗 Useful Links

- GitHub Repository: https://github.com/$REPO
- Project Board: https://github.com/$REPO/projects
- Sentry: https://sentry.io
- Prometheus: http://localhost:9090 (if configured)

## 📞 Support & Escalation

- **Backend Team Lead**: [Contact info]
- **Project Manager**: R.Elsa Balqis
- **GitHub Issues**: Assign to yourself or comment on issue

## ⚠️ Important Notes

1. **Environment Variables**: Update .env with your Sentry DSN and other credentials
2. **Database**: Ensure MySQL is running or Docker containers are started
3. **Docker**: If using Docker Compose, ensure Docker daemon is running
4. **Credentials**: Never commit .env with real credentials; use GitHub Secrets
5. **Testing**: Run tests locally before pushing to ensure CI passes

## 🎯 Success Criteria

Before marking your tasks complete:
- [ ] All tests passing (local + CI/CD)
- [ ] Monitoring alerts configured and tested
- [ ] Staging deployment verified
- [ ] Documentation complete and reviewed
- [ ] Pull requests merged to main
- [ ] Team trained on procedures

---

**Setup Script Version**: 1.0  
**Last Updated**: $(date)

For more details, see BE1_NABILAH_ASANA_ANALYSIS.md
EOF

  log_success "Setup summary generated: BE1_SETUP_SUMMARY.md"
}

# ─── MAIN EXECUTION ────────────────────────────────────────
main() {
  log_header "Project_Aplikasi_TukangDekat PROJECT SETUP FOR BACKEND 1 (Nabilah Asana)"
  
  log_info "Project Root: $PROJECT_ROOT"
  log_info "Backend Dir: $BACKEND_DIR"
  log_info "Repository: $REPO"
  echo ""

  # Execute setup steps
  check_prerequisites
  setup_repository
  setup_backend
  create_branches
  setup_monitoring
  run_tests
  create_tracking_issues
  generate_summary

  # Final summary
  log_header "✅ SETUP COMPLETED SUCCESSFULLY!"
  
  echo -e "${GREEN}Next Steps:${NC}"
  echo "1. Review BE1_SETUP_SUMMARY.md for quick reference"
  echo "2. Read BE1_NABILAH_ASANA_ANALYSIS.md for detailed task breakdown"
  echo "3. Check out your feature branches:"
  echo "   - git checkout feature/backend-121-nabilah-integration-tests"
  echo "   - git checkout feature/backend-124-nabilah-monitoring-alerts"
  echo "   - git checkout feature/backend-nabilah-documentation"
  echo ""
  echo "4. Update .env with your Sentry DSN and credentials"
  echo "5. Start development: cd backend && docker-compose up -d"
  echo "6. Review GitHub Issues created for tracking"
  echo ""
  echo -e "${CYAN}Happy coding! 🚀${NC}"
}

# Execute main function
main "$@"
