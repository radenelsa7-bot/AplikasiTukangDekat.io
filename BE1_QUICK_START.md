# 🚀 QUICK START - Backend 1 (Nabilah Asana)

## 📋 Ringkasan Tugas BE1

Anda ditugaskan untuk **menyelesaikan dan memverifikasi** infrastruktur monitoring dan testing backend TukangDekat.

| No. | Tugas | Status | Due Date | Branch |
|-----|-------|--------|----------|--------|
| 1 | Integration test untuk network failures & backoff | ✅ 80% | 2026-06-07 | `feature/backend-121-nabilah-integration-tests` |
| 2 | Monitoring/metrics produksi & alerting | ✅ 70% | 2026-06-07 | `feature/backend-124-nabilah-monitoring-alerts` |
| 3 | Documentation & Runbook | 🔄 0% | 2026-06-14 | `feature/backend-nabilah-documentation` |

---

## ⚡ Setup Cepat (5 Menit)

### 1. Clone Script & Jalankan Setup
```bash
# Masuk ke folder project
cd "PM_UAS_rekayasa_Sistem_Informasi"

# Jalankan script setup (pilih satu)
# Option A: Bash (Mac/Linux/WSL)
bash "Setup_tukangdekat(NabilahAsana).sh"

# Option B: PowerShell (Windows)
# Kami akan buat versi PowerShell juga
```

### 2. Script Akan Otomatis Membuat:
- ✅ Feature branches untuk 3 tugas Anda
- ✅ Setup backend environment (.env, composer)
- ✅ Jalankan Docker containers
- ✅ Setup & verify monitoring infrastructure
- ✅ Run test suite untuk verifikasi
- ✅ Create GitHub issues untuk tracking
- ✅ Generate dokumentasi ringkas

### 3. Setelah Setup, Anda Siap dengan:
```
✓ Backend environment ready
✓ Feature branches created
✓ Tests passing
✓ Monitoring configured
✓ GitHub issues for tracking
```

---

## 📊 Analisa Status Anda

Dokumen **BE1_NABILAH_ASANA_ANALYSIS.md** berisi:
- ✅ Apa yang **sudah selesai** (80%)
- ⏳ Apa yang **masih pending** (20%)
- 📋 Checklist lengkap per task
- 🎯 Success criteria yang jelas
- 📞 Escalation path jika ada masalah

---

## 🎯 Prioritas Pekerjaan (Week 6 - 15-18 Juni)

### 🔴 HIGH PRIORITY (Harus selesai minggu ini)
1. **Configure Alerting Rules** (Sentry)
   - Set threshold: >5% = WARNING
   - Set threshold: >20% = CRITICAL
   - Setup notifications ke Slack/Email

2. **Staging Verification**
   - Deploy ke staging environment
   - Verify metrics collection
   - Collect 24-hour baseline
   - Document setup

### 🟡 MEDIUM PRIORITY (Next)
3. **Documentation & Runbook**
   - Update backend/RUNBOOK.md
   - Create docs/MONITORING_RUNBOOK.md
   - Document emergency procedures

---

## 🛠️ Command Reference

### Setup & Development
```bash
# Navigate to backend
cd backend

# Start containers
docker-compose up -d

# Run migrations
php artisan migrate

# Start dev server
php artisan serve
```

### Testing
```bash
# Run all tests
php vendor/bin/phpunit

# Run specific test
php vendor/bin/phpunit tests/Feature/PayoutPipeline

# With verbose output
php vendor/bin/phpunit --testdox
```

### Monitoring
```bash
# Check metrics endpoint
curl http://localhost:8000/api/metrics

# View logs
tail -f storage/logs/laravel.log
```

### Git Workflow
```bash
# Create/switch to branch
git checkout -b feature/backend-121-nabilah-integration-tests

# Make changes
git add .
git commit -m "feat: [description]"

# Push to remote
git push origin feature/backend-121-nabilah-integration-tests

# Create PR
gh pr create --title "..." --body "..."
```

---

## 📁 File Penting untuk Dibaca

### 1. **BE1_NABILAH_ASANA_ANALYSIS.md** (BACA DULU!)
   - Analisa lengkap status Anda
   - Detailed breakdown per task
   - Checklist untuk sign-off

### 2. **PROGRESS_TRACKING.md**
   - Status overall project
   - Apa yang sudah selesai di backend
   - Reference untuk understanding flow

### 3. **backend/RUNBOOK.md**
   - Deployment procedures
   - Monitoring procedures
   - Emergency escalation

### 4. **backend/README.md**
   - Project struktur
   - API documentation
   - Development setup

---

## 🔑 Key Endpoints & Files

### API Endpoints
- `GET /api/metrics` - Prometheus metrics (monitoring)
- `GET /api/payout/{id}` - Payout details
- `POST /api/payout/webhook` - Xendit webhooks

### Backend Services
- `app/Services/MonitoringService.php` - Monitoring logic
- `app/Services/MetricsCollectorService.php` - Metrics collection
- `app/Services/XenditPayoutGateway.php` - Payment gateway

### Test Files
- `tests/Feature/PayoutPipeline/NetworkFailureTest.php`
- `tests/Feature/PayoutPipeline/RetryBackoffTest.php`
- `tests/Unit/Monitoring/MetricsCollectorTest.php`

---

## ⚠️ Common Issues & Solutions

### Issue: Docker containers won't start
```bash
# Solution: Check Docker daemon
docker ps
docker-compose up -d --verbose
```

### Issue: Composer dependencies conflicts
```bash
# Solution: Clear cache and reinstall
composer clear-cache
composer install --no-cache
```

### Issue: Database migration fails
```bash
# Solution: Check MySQL is running
docker-compose ps
docker-compose logs db
```

### Issue: Tests failing locally
```bash
# Solution: Run with detailed output
php vendor/bin/phpunit --verbose
php vendor/bin/phpunit tests/Feature --stop-on-failure
```

### Issue: GitHub CLI not working
```bash
# Solution: Check auth status
gh auth status
gh auth login  # Re-login if needed
```

---

## 📞 Support & Help

### Need Help With?

| Issue | Contact | How |
|-------|---------|-----|
| Backend/PHP questions | Backend Team Lead | Slack/Email |
| Deployment/DevOps | Infra Team | GitHub Issues |
| Project management | R.Elsa Balqis (PM) | GitHub Issues |
| General questions | Backend Team | Team meeting |

### Report Issues
1. Create GitHub issue with `[BE1]` prefix
2. Assign to yourself
3. Add label: `role: Backend, priority: high`
4. Include: error message, steps to reproduce, what you tried

---

## ✅ Checklist untuk Selesai

Sebelum merge PR ke `main`, pastikan:

- [ ] Semua tests passing (local + CI/CD)
- [ ] Alerting rules configured dan tested
- [ ] Staging deployed dan verified
- [ ] Metrics baseline collected (24 hours)
- [ ] Documentation updated
- [ ] Code reviewed oleh Backend Lead
- [ ] PR merged to main

---

## 🎯 Success = 

✅ All tests passing  
✅ Monitoring alerts working  
✅ Staging verified  
✅ Team trained  
✅ Documentation complete  

---

## 📅 Timeline

```
Week 6 (15-18 Juni 2026)
├── Mon-Wed: Finalize alerting & staging verification
├── Wed-Thu: Documentation & training
└── Thu-Fri: Final testing & merge to main

DEADLINE: Friday 18 Juni 2026 23:59 WIB
```

---

**Setup ini dibuat**: 2026-06-04  
**Script**: Setup_tukangdekat(NabilahAsana).sh  
**For**: Nabilah Asana (BE1)

Jika ada pertanyaan, baca **BE1_NABILAH_ASANA_ANALYSIS.md** untuk detail lengkap! 🚀
