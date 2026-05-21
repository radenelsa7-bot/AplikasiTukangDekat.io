# Release v1.0.0

Tanggal: 2026-05-19

Ringkasan
---------
- Menambahkan monitoring untuk pipeline payout: persistence provider responses, notifikasi (email + webhook + Slack), queued alert job.
- Menambahkan helper deploy/secrets: contoh file, `set_github_secrets.sh`, `set_server_env.sh`, dan panduan Ansible Vault.
- Perubahan pada adapter Xendit: refactor, retry/sanitization, form-encoded fallback.
- Menambahkan unit tests untuk payout monitoring dan job dispatch.

Changelog (pilihan commit terakhir)
----------------------------------

```
9e8693a Belum jadi
1170c4b docs: add webhook alert docs (redacted) and queue worker note
c0e1fad feat(payout): add provider response persistence and alerting (migration, model, notification, gateway)
79c7270 feat(auth): enhance login and logout functionality with improved token handling
a4e228e feat: add auto project board with issue assignment
179e35d add Setup_tukangdekat_github.sh
690d91d fix(treasurer): make e2e export auth work with sanctum
64a2034 Add DEPLOY_STATUS.md: deployment status and next steps
f7a6e62 chore(payout): prefer configured gateway and allow PAYOUT_GATEWAY=mock
```

Petunjuk upgrade
-----------------
1. Tarik perubahan dari `main` dan jalankan migrasi:

```
git pull origin main
cd backend
php artisan migrate --force
```

2. Pastikan environment variabel berikut terkonfigurasi di server/staging (GitHub Secrets / .env):
- `XENDIT_API_KEY` (jika menggunakan Xendit sandbox/production)
- `PAYOUT_ALERT_WEBHOOK` (opsional, Slack incoming webhook atau generic URL)
- `PAYOUT_ALERT_EMAIL` (email ops untuk notifikasi)

3. Jalankan queue worker (disarankan systemd/service):

```
php artisan queue:work --sleep=3 --tries=3
```

Catatan
-------
- Contoh Slack webhook di `deploy/SETUP_SECRETS.md` telah direkat untuk menghindari push-protection. Masukkan URL asli melalui GitHub Secrets atau server `.env`.
- Review `backend/deploy/SETUP_SECRETS.md` dan `backend/RUNBOOK.md` untuk langkah deploy lengkap.
