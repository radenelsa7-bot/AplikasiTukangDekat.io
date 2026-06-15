# Checklist: Merge & Deploy to Staging

Tujuan: memastikan branch `feature/backend-123-deploy-smoke` digabung dan dideploy ke staging dengan aman.

## Prerequisites
- Akses ke repo (push/merge) dan environment staging.
- Docker dan Docker Compose di server staging (atau akses ke runner CI).
- Backup database staging tersedia.
- Environment variables staging siap: `MIDTRANS_SERVER_KEY`, `XENDIT_API_KEY`, `N8N_WEBHOOK_URL`, `APP_ENV=staging`, dll.

## 1) Review & Merge
- Pastikan PR code review selesai dan review komentar ditangani.
- Pastikan branch up-to-date dengan `main` dan tidak ada conflict.
- **PENTING**: Pastikan GitHub Actions workflow `Backend Tests` sudah passing pada PR sebelum merge.
  - Lihat tab `Checks` di PR → pastikan `Backend Tests / Run Backend Test Suite` status ✅ PASS
  - Jika gagal, investigate error pada tab Actions dan fix sebelum merge

Commands:
```bash
# tarik branch terbaru
git fetch origin
# pindah ke main dan tarik
git checkout main
git pull origin main
# gabungkan fitur ke main (lokal) untuk cek
git checkout feature/backend-123-deploy-smoke
git rebase main    # atau git merge main
# push jika perlu
git push origin feature/backend-123-deploy-smoke
```
- Merge PR melalui GitHub UI atau `git merge` dan buat tag jika perlu.
  - **Rekomendasi**: Merge via GitHub UI agar workflow trigger otomatis pada main branch

## 2) Prepare Staging (pre-deploy)
- Pastikan backup DB staging terbaru dibuat.
- Pastikan migrasi telah diuji di lokal/dev container.
- Pastikan konfigurasi secrets/env di staging sudah di-set.

Commands (CI/Server):
```bash
# contoh: tarik image/build
git checkout main
git pull origin main
docker compose pull
docker compose build --no-cache app
```

## 3) Run Tests on Staging (or CI) Before Migrate
- Jalankan test suite di staging/CI (non-destructive):
  - **Jika menggunakan GitHub Actions**: workflow sudah otomatis berjalan pada PR/push. Pastikan status ✅ sebelum proceed.
  - **Manual test** (jika tidak ada CI):

Commands:
```bash
# di server/CI
docker compose run --rm app php artisan test
# atau jalankan hanya smoke/payment tests
docker compose run --rm app php artisan test --filter=PaymentWebhookTest
```
- Pastikan semua test passing. Jika gagal, rollback merge and investigate.
- Lihat dokumentasi setup: [backend/GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) untuk detail workflow CI

## 4) Apply Migrations
- Jalankan migrasi dalam mode non-interactive dan tanyakan rollback plan.

Commands:
```bash
# backup DB (example)
# mysqldump -u user -p dbname > backup.sql

# migrasi
docker compose run --rm app php artisan migrate --force
```

## 5) Deploy & Restart Services
- Restart app containers and queue workers.

Commands:
```bash
docker compose up -d --remove-orphans
# restart queue workers jika dipakai
docker compose exec app php artisan queue:restart
```

## 6) Post-deploy Verification
- Jalankan smoke test singkat:
```bash
docker compose run --rm app php artisan test --filter=SmokeTestFeature
```
- Periksa endpoint pembayaran manual (generate/capture QRIS) pada staging.
- Verifikasi webhook flow: kirim test webhook ke `/api/webhooks/payment`.
- Periksa logs untuk error (tail):
```bash
docker compose logs -f app
```
- Cek database: tabel `payments` telah memiliki kolom `qris_code`, `qris_image`, `checkout_url` dan data baru jika ada.

## 7) Monitoring & Rollback Plan
- Pastikan monitoring/logging (Sentry/Prometheus/etc.) aktif.
- Jika ada masalah kritis → rollback:
  - Revert merge commit on GitHub or `git revert <merge-commit>`
  - Restart previous image or deploy previous tag
  - Restore DB from backup if migration changed data schema incompatibly

## 8) Post-release Tasks
- Run full E2E with mobile app.
- Run performance test if needed.
- Document any environment var changes in ops docs.

---
Jika Anda ingin, saya bisa:
- Membuat GitHub Actions workflow untuk menjalankan tes otomatis pada PR/merge. ✅ **SELESAI** — lihat `.github/workflows/backend-tests.yml`
- Membuat skrip deploy otomatis untuk staging.

Dokumentasi: [backend/GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

Tandai mana yang mau saya lanjutkan.
