# Action Plan - BE3 (Fatinasy7) - TukangDekat Backend Development

**Tanggal:** 4 Juni 2026  
**Nama:** Fatinasy7  
**Role:** Backend Developer 3 (BE3)  
**Project:** Project_Aplikasi_TukangDekat  
**Status:** Active Development

---

## 📌 Executive Summary

Anda telah ditetapkan sebagai **Backend Developer 3 (BE3)** dalam proyek TukangDekat dengan fokus pada:

1. ✅ **Completed:** CI/CD Staging Gateway (feature/backend-122-ci-staging)
2. 🔄 **In Progress:** Deploy-Smoke Setup (feature/backend-123-deploy-smoke)
3. ⏳ **Upcoming:** n8n Notification Integration (Week 4)
4. ⏳ **Upcoming:** API Hardening (Week 5, bersama BE2)

Dokumen ini menyediakan analisis lengkap, timeline, dan action items untuk menyelesaikan tugas Anda.

---

## 📊 Task Breakdown

### ✅ SELESAI: Week 3 - CI Staging Gateway

**Branch:** `feature/backend-122-ci-staging`  
**Status:** Merged ke `main`  

**Apa yang Diselesaikan:**
- GitHub Actions workflow `ci-staging.yml` untuk integration/staging
- Gate job dengan secrets (`DEPLOY_KEY`)
- Fallback informatif jika secrets belum ada
- Dokumentasi setup secrets dan runbook

---

### 🔄 IN PROGRESS: Week 4 - Deploy-Smoke (feature/backend-123-deploy-smoke)

**Status:** Currently Active (Branch pushed, PR #38 open)  
**Deadline:** 7 Juni 2026  
**Priority:** 🔴 HIGH  

#### Current progress
- [x] Branch pushed to origin
- [x] Pull request #38 opened
- [x] Deployment documentation updated (`backend/DEPLOY_STATUS.md`, `backend/DEPLOY_REPORT_FOR_PM.md`)
- [ ] Smoke test execution pending staging environment
- [ ] Queue worker verification pending staging environment

#### Tasks Checklist
- [ ] **Jalankan Migrasi di Staging**
  - Pastikan database schema lengkap
  - Verify data integrity post-migration
  - Dokumentasikan status migrasi

- [ ] **Aktifkan Queue Worker**
  - Setup Redis/Beanstalkd connection
  - Configure Supervisor untuk queue:work
  - Test job enqueueing dan processing
  - Monitor queue status dashboard

- [ ] **Implementasi Smoke Test**
  - Create comprehensive test script (bash + PHP artisan)
  - Test 10 critical endpoints:
    - POST /api/auth/login
    - GET /api/categories
    - GET /api/providers
    - POST /api/orders
    - GET /api/orders/{id}
    - POST /api/payments/{id}/qris
    - GET /api/payments/{id}
    - POST /api/webhooks/payments
    - POST /api/orders/{id}/start
    - POST /api/orders/{id}/complete
  - Verify response status dan payload
  - Test dengan real database

- [ ] **Dokumentasi Deployment**
  - Update DEPLOY_STATUS.md
  - Catat success/failure metrics
  - Create deployment verification report
  - Document queue monitoring procedures

#### Deliverables
```
backend/
├── deploy/
│   ├── smoke-test.sh         (✏️ Update/Create)
│   ├── laravel-queue.service (✏️ Verify)
│   ├── supervisor.conf       (✏️ Verify/Update)
│   └── README.md             (✏️ Update dengan instruksi)
├── DEPLOY_STATUS.md          (✏️ Create/Update)
├── DEPLOYMENT.md             (✏️ Update)
├── RUNBOOK.md                (✏️ Update)
└── tests/
    └── Feature/
        └── SmokeTestFeature.php  (📝 Create)
```

#### Implementation Guide

**1. Database Migration**
```bash
cd backend
# Verify migration files
ls database/migrations/

# Run migrations
php artisan migrate

# Verify schema
php artisan tinker
# Check: DB::select('SHOW TABLES;')
```

**2. Queue Worker Setup**
```bash
# Test queue locally
php artisan queue:work --timeout=60

# Test job dispatch
php artisan tinker
# Dispatch test job: 
# SendPayoutAlertWebhook::dispatch($payout)->onQueue('payouts');

# Check configuration
php artisan config:show queue
```

**3. Supervisor Configuration**
```bash
# Edit: /etc/supervisor/conf.d/laravel-queue.conf
# Pastikan:
# - program:laravel-queue
# - command: php artisan queue:work --queue=default,payouts,notifications
# - autostart=true
# - autorestart=true
# - numprocs=3

# Test
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status laravel-queue:*
```

**4. Smoke Test Script**
```bash
# File: backend/deploy/smoke-test.sh
# Test 10 endpoints dengan real database
# Output: smoke-test-result.json
# Status: OK, WARNING, FAILED
```

**5. Run Smoke Test**
```bash
bash backend/deploy/smoke-test.sh

# Expected output:
# ✓ POST /api/auth/login         (200 OK)
# ✓ GET /api/categories          (200 OK)
# ✓ GET /api/providers           (200 OK)
# ✓ POST /api/orders             (201 Created)
# ✓ GET /api/orders/{id}         (200 OK)
# ✓ POST /api/payments/{id}/qris (200 OK)
# ✓ GET /api/payments/{id}       (200 OK)
# ✓ POST /api/webhooks/payments  (200 OK)
# ✓ POST /api/orders/{id}/start  (200 OK)
# ✓ POST /api/orders/{id}/complete (200 OK)

# Summary: 10/10 passed
```

---

### ❌ PENDING: Week 4 - n8n Integration (feature/backend-124-n8n-integration)

**Timeline:** 1-7 Juni 2026  
**Priority:** 🟡 MEDIUM  
**Shared with:** Nobody (individual task)  

#### Overview
Integrasikan n8n workflow automation dengan API untuk mengirim notifikasi WhatsApp dan Email.

#### Major Tasks
1. **Setup n8n Environment**
   - Verify n8n container running (docker-compose)
   - Access n8n UI (http://localhost:5678)
   - Configure n8n credentials

2. **Design Notification Workflows**
   ```
   Event: order_created
   → POST /api/integrations/n8n/events
   → n8n webhook trigger
   → Send WA to customer & provider
   → Log to notification_logs
   
   Event: dp_paid
   → Payment webhook callback
   → Trigger n8n workflow
   → Send WA confirmation
   → Log notification
   
   Event: order_completed
   → Trigger n8n workflow
   → Send WA request untuk final payment
   → Log notification
   
   Event: final_paid
   → Trigger n8n workflow
   → Send WA order closed
   → Log all parties
   ```

3. **Implement API Integration**
   - POST /api/integrations/n8n/events
   - Request body: `{ event: 'order_created', order_id: 123, ... }`
   - Webhook signature validation
   - Error handling & retry logic

4. **Notification Logs**
   - Insert ke table `notification_logs`
   - Track: event, status, recipient, timestamp
   - For audit trail

#### Files to Create/Update
```
backend/
├── app/
│   ├── Http/Controllers/
│   │   └── WebhookController.php (atau IntegrationController)
│   ├── Services/
│   │   └── NotificationService.php
│   └── Models/
│       └── NotificationLog.php
├── routes/
│   └── api.php (tambah routes untuk n8n)
├── config/
│   └── services.php (tambah n8n config)
├── database/migrations/
│   └── create_notification_logs_table.php
└── tests/Feature/
    └── NotificationIntegrationTest.php
```

#### Estimated Effort
- Design & n8n setup: 2-3 jam
- API implementation: 4-5 jam
- Testing: 2-3 jam
- **Total: 8-11 jam**

---

### ❌ PENDING: Week 5 - API Hardening (feature/backend-125-api-hardening)

**Timeline:** 8-14 Juni 2026  
**Priority:** 🔴 HIGH  
**Shared with:** BE2 (Fajar1180)  

#### Collaboration Points
- Security audit (bersama)
- Validation standards (bersama)
- Error handling (bersama)
- Rate limiting (coordination)

#### Major Tasks
1. **Security Hardening**
   - Review middleware order & role checks
   - Verify HTTPS enforcement
   - Check CORS configuration
   - Password hashing verification (bcrypt)
   - Review environment secrets

2. **Validation Improvements**
   - Audit semua Form Request classes
   - Standardize error messages
   - Add rate limiting
   - Input sanitization

3. **Error Handling**
   - Standardize API error responses
   - Remove debug info dari production responses
   - Implement proper HTTP status codes
   - Consistent error format

4. **Code Cleanup**
   - Remove `dd()` dan `var_dump()`
   - Remove test/debug comments
   - Clean up unused imports
   - Verify no secrets hardcoded

---

## 🔄 Current Branch Status

```bash
# Current working branch
git branch --show-current
# Output: feature/backend-123-deploy-smoke

# View branch tracking
git branch -vv
# Output:
# * feature/backend-123-deploy-smoke  abc1234 [origin/feature/backend-123-deploy-smoke] Some commit message
# main                              def5678 [origin/main] Merge PR #XXX

# Commit log
git log --oneline -10
```

---

## 📋 Implementation Steps

### Step 1: Prepare Development Environment
```bash
# 1. Navigate to project
cd c:\UAS\PM_UAS_rekayasa_Sistem_Informasi
git status

# 2. Switch to deploy-smoke branch (if needed)
git checkout feature/backend-123-deploy-smoke

# 3. Update branch
git fetch origin
git rebase origin/main

# 4. Verify backend env
cd backend
composer install
php artisan config:cache
```

### Step 2: Implement Queue Worker
```bash
# 1. Check queue config
php artisan config:show queue
cat config/queue.php

# 2. Test Redis connection
php artisan tinker
# > Redis::ping()
# => "PONG"

# 3. Check Supervisor config
cat deploy/supervisor.conf

# 4. Test queue:work locally
php artisan queue:work --timeout=60 &

# 5. Dispatch test job
php artisan tinker
# > SendPayoutAlertWebhook::dispatch($payout)->onQueue('payouts');
# Check if job processed

# 6. Kill local queue worker
kill %1
```

### Step 3: Create Smoke Test Script
```bash
# 1. Create/update smoke-test.sh
# See: backend/deploy/smoke-test.sh template

# 2. Make executable
chmod +x backend/deploy/smoke-test.sh

# 3. Test locally
bash backend/deploy/smoke-test.sh

# 4. Commit
git add backend/deploy/smoke-test.sh
git commit -m "feat: add comprehensive smoke test script"
```

### Step 4: Documentation & Testing
```bash
# 1. Run full test suite
php artisan test

# 2. Run specific smoke test
php artisan test --filter SmokeTestFeature

# 3. Update DEPLOY_STATUS.md
# Document all steps taken

# 4. Verify all changes
git status
git diff origin/main

# 5. Commit
git add .
git commit -m "docs: update deployment status and procedures"
```

### Step 5: Create Pull Request
```bash
# 1. Push branch
git push origin feature/backend-123-deploy-smoke

# 2. Create PR via GitHub CLI
gh pr create \
  --title "[Backend] Migrasi staging, queue worker, dan smoke test post-deploy" \
  --body "$(cat << 'EOF'
## 📝 Description
Implementasi lengkap untuk migrasi staging, aktivasi queue worker, dan smoke test post-deploy.

## 🎯 Issue
Closes #XXX

## ✅ Checklist
- [x] Database migrations tested
- [x] Queue worker configured and tested
- [x] Smoke test script implemented
- [x] All tests passing
- [x] Documentation updated

## 📊 Changes
- backend/deploy/smoke-test.sh - New comprehensive smoke test
- backend/DEPLOY_STATUS.md - Updated deployment status
- backend/RUNBOOK.md - Updated with queue worker instructions
- backend/supervisor.conf - Verified configuration
- backend/tests/Feature/SmokeTestFeature.php - New feature tests

## 🧪 Testing
1. Run migrations: `php artisan migrate`
2. Test queue: `php artisan queue:work`
3. Run smoke test: `bash deploy/smoke-test.sh`
4. Run tests: `php artisan test`

All passed ✅
EOF
)" \
  --base main \
  --head feature/backend-123-deploy-smoke

# 3. Or via Web UI
# https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/compare/main...feature/backend-123-deploy-smoke
```

---

## 📅 Timeline & Milestones

| Date | Milestone | Status | Notes |
|------|-----------|--------|-------|
| 4 Juni | Start deploy-smoke | 🔄 In Progress | Currently active |
| 7 Juni | Finish deploy-smoke + PR | ⏳ Next | Deadline |
| 1-7 Juni | Week 4: n8n integration | ❌ Not Started | Overlap with deploy-smoke |
| 8-14 Juni | Week 5: API hardening | ❌ Not Started | Shared with BE2 |
| 15-18 Juni | Final testing & demo | ❌ Pending | Dependent on above |

---

## 🚀 Quick Commands Reference

```bash
# Project Navigation
cd c:\UAS\PM_UAS_rekayasa_Sistem_Informasi
cd backend

# Git Operations
git status                          # Check status
git log --oneline -10              # View recent commits
git diff origin/main               # View changes
git fetch origin                   # Update remote info
git rebase origin/main             # Rebase on main
git push origin feature/backend-123-deploy-smoke  # Push branch

# Laravel Operations
php artisan serve                  # Run dev server
php artisan migrate                # Run migrations
php artisan test                   # Run tests
php artisan queue:work             # Run queue worker
php artisan tinker                 # Interactive shell

# Docker Operations
docker-compose up -d               # Start containers
docker-compose down                # Stop containers
docker-compose logs -f laravel-api # View logs
docker-compose exec laravel-api bash  # Shell access

# GitHub CLI
gh auth status                     # Check auth status
gh issue list --repo radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi
gh pr create --title "..." --base main
gh pr view <PR_NUMBER>             # View PR details
gh pr merge <PR_NUMBER> --squash   # Merge PR
```

---

## 📚 Documentation Reference

**Internal Documents:**
- ANALISIS_BE3_FATINASY7.md - Complete analysis
- PROGRESS_TRACKING.md - Progress overview
- backend/DEPLOYMENT.md - Deployment guide
- backend/RUNBOOK.md - Operations runbook
- backend/DEPLOY_STATUS.md - Current deployment status

**API Documentation:**
- docs/api/API_DOCUMENTATION.md (or Swagger)
- backend/routes/api.php (endpoint definitions)

**Setup:**
- Setup_tukangdekat(FatinAsyifa).sh - Automated setup script
- QUICK_START_SETUP.md - Quick start guide
- PR_TRACKING_GUIDE_BE3.md - PR workflow guide

---

## 🔗 Related Links

**GitHub:**
- Repository: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi
- Issues: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/issues
- Pull Requests: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/pulls
- Project Board: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/projects

**Team:**
- **PM:** radenelsa7-bot (R.Elsa Balqis)
- **BE1:** NabilahAsana (API Auth, Orders)
- **BE2:** Fajar1180 (Payment, DP auto-create)
- **BE3:** Fatinasy7 (You - Deploy, n8n, Hardening)
- **QA:** aldyrmdny-lab

---

## ✅ Checklist Akhir

Sebelum submit final deliverable:

- [ ] feature/backend-123-deploy-smoke selesai & merged
- [ ] feature/backend-124-n8n-integration selesai & merged
- [ ] feature/backend-125-api-hardening selesai & merged (with BE2)
- [ ] Semua tests passing (php artisan test)
- [ ] Smoke test script berjalan sempurna
- [ ] Documentation lengkap & akurat
- [ ] PROGRESS_TRACKING.md updated
- [ ] GitHub Issues closed/linked
- [ ] Code review approved
- [ ] Ready untuk demo UAS

---

**Status:** 🟢 Ready for Development  
**Last Updated:** 4 Juni 2026  
**Next Review:** 7 Juni 2026
