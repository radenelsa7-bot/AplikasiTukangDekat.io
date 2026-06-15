# GitHub Actions: Backend Test Workflow

Dokumentasi setup dan konfigurasi untuk GitHub Actions workflow yang menjalankan test suite backend otomatis.

## File Workflow

Lokasi: `.github/workflows/backend-tests.yml`

Workflow ini:
- **Trigger**: Push atau PR ke branch `main`, `feature/backend-123-deploy-smoke`, `develop` (hanya jika ada perubahan di folder `backend/`)
- **Runs on**: `ubuntu-latest`
- **Services**: MySQL 8.0 (untuk database testing)
- **Steps**: Build → Migrate → Test → Report

## Konfigurasi Workflow

### Trigger Events
```yaml
on:
  push:
    branches:
      - main
      - feature/backend-123-deploy-smoke
      - develop
  pull_request:
    branches:
      - main
      - feature/backend-123-deploy-smoke
      - develop
```

**Modifikasi jika perlu:**
- Tambahkan branch lain yang perlu di-monitor
- Ubah `develop` menjadi branch staging Anda

### Test Stages
1. **Build Docker Image** — `docker-compose build app`
2. **Start Services** — `docker-compose up -d`
3. **Migrate Database** — `php artisan migrate --force`
4. **Run Full Test Suite** — `php artisan test`
5. **Run Payment Tests** — `php artisan test --filter=PaymentWebhookTest`
6. **Run Smoke Tests** — `php artisan test --filter=SmokeTestFeature`
7. **Schema Dump** — `php artisan schema:dump`
8. **Cleanup** — `docker-compose down -v`

### Environment Variables (Optional)

Jika test memerlukan env vars khusus, tambahkan di workflow atau set di GitHub Secrets:

**Contoh .env untuk test:**
```env
APP_ENV=testing
APP_DEBUG=true
APP_KEY=base64:... # Generate with php artisan key:generate
DB_HOST=mysql
DB_DATABASE=pm_uas_test
DB_USERNAME=app_user
DB_PASSWORD=app_password
DB_PORT=3306
MIDTRANS_SERVER_KEY=test_... # Use test keys
XENDIT_API_KEY=test_...
N8N_WEBHOOK_URL=https://mock-webhook.example.com/
LOG_CHANNEL=errorlog
```

Set di GitHub repo:
1. Go to Settings → Secrets and variables → Actions
2. Create secrets (e.g., `MIDTRANS_SERVER_KEY`, `XENDIT_API_KEY`)
3. Referensi dalam workflow: `${{ secrets.MIDTRANS_SERVER_KEY }}`

### GitHub Secrets (Optional)

Untuk mengirim notifikasi ke Slack atau tools lain:

```
SLACK_WEBHOOK_URL = https://hooks.slack.com/services/...
```

Set Slack webhook:
1. Go to Slack workspace → Apps → Incoming Webhooks
2. Create new webhook
3. Copy URL ke GitHub Secrets: `Settings → Secrets → New repository secret`

## Monitoring & Troubleshooting

### View Workflow Runs
1. Go to repo → Actions tab
2. Pilih workflow `Backend Tests`
3. Lihat history run dan detail setiap langkah

### If Tests Fail
1. Click pada failed run
2. Lihat `Run Backend Test Suite` step → output
3. Lihat `Collect logs on failure` → download artifacts
4. Review `app-logs.txt` dan `mysql-logs.txt`

### Common Issues

**Issue**: MySQL service tidak siap
- **Solusi**: Workflow sudah punya `health-cmd` dan sleep 10s; jika masih gagal, tambah sleep lebih lama.

**Issue**: Docker image tidak build
- **Solusi**: Check `backend/Dockerfile` dan `docker-compose.yml` syntax; pastikan semua path benar.

**Issue**: Test timeout
- **Solusi**: Tambah `timeout-minutes: 30` di `jobs.test:` jika perlu.

## Modifikasi & Customization

### Tambah test suite baru
Edit `.github/workflows/backend-tests.yml` step `Run X tests`:
```yaml
- name: Run CustomTest
  working-directory: ./backend
  if: always()
  run: |
    docker-compose run --rm app php artisan test --filter=CustomTest
```

### Tambah post-deploy steps (staging)
Jika ingin deploy otomatis ke staging setelah test lulus:
```yaml
- name: Deploy to staging
  if: github.ref == 'refs/heads/feature/backend-123-deploy-smoke' && success()
  run: |
    # Tambah script deploy Anda di sini
    # Contoh: ssh deploy@staging.example.com './deploy.sh'
```

### Report ke services lain
Tambahkan step sebelum `notify` job untuk mengirim ke Datadog, New Relic, atau APM lainnya.

## CI/CD Integration

### Require Workflow Passing Before Merge
1. Go to repo → Settings → Branches
2. Add branch protection rule: `main`, `feature/backend-123-deploy-smoke`
3. Check: "Require status checks to pass before merging"
4. Select: `Backend Tests / Run Backend Test Suite`
5. Save

Sekarang merge tidak akan possible jika test gagal.

## Next Steps

1. **Commit & push** workflow file:
```bash
git add .github/workflows/backend-tests.yml
git commit -m "ci: Add GitHub Actions workflow for backend tests"
git push origin feature/backend-123-deploy-smoke
```

2. **Monitor** PR → Actions tab untuk lihat test berjalan

3. **Setup branch protection** (optional) untuk enforce test passing sebelum merge

4. **Configure secrets** jika diperlukan (SLACK_WEBHOOK_URL, test keys, etc.)

---

## Example Output

Saat workflow berhasil, Anda akan lihat di PR:
```
✅ All checks passed
- Backend Tests / Run Backend Test Suite — PASS
- Backend Tests / Send Notifications — PASS
```

Saat gagal:
```
❌ Some checks were unsuccessful
- Backend Tests / Run Backend Test Suite — FAIL
```

Klik untuk lihat detail error dan logs.
