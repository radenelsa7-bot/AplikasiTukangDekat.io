## RUNBOOK: Payout (Xendit) — Panduan Singkat (Bahasa Indonesia)

Tujuan: cara menyiapkan, menguji, dan mendiagnosa payout provider (Xendit) untuk fitur payout sesuai SRS.

- **Lokasi file terkait**: layanan adapter di `app/Services/Payout/XenditPayoutGateway.php`.

1) Variabel lingkungan (ENV)
- `PAYOUT_GATEWAY`: pilih `xendit` atau `mock`.
- `XENDIT_API_KEY`: secret sandbox/production secret key (jangan commit ke repo).
- `XENDIT_BASE_URL`: opsional (default `https://api.xendit.co`).
- `XENDIT_DISBURSEMENT_PATH`: opsional path override (default `/disbursements`).
- `XENDIT_DEBUG`: `1` untuk mengaktifkan debug log (laravel.log) saat troubleshooting.

2) Cara menjalankan tes manual (lokal)
- Jalankan command artisan untuk mencoba satu payout (sandbox):

```bash
PAYOUT_GATEWAY=xendit XENDIT_API_KEY="<sandbox_key>" XENDIT_DEBUG=1 php artisan payouts:test-gateway 10000 --to=081234567890
```

- Output akan menampilkan kelas gateway yang dipakai dan JSON respons provider. Jika successful, respon biasanya mengandung `status` (mis. `PENDING`) dan `id`/`transaction_reference`.

3) Interpretasi hasil umum
- `API_VALIDATION_ERROR`: payload tidak cocok dengan schema endpoint sandbox. Adapter telah mencoba beberapa varian payload dan fallback form-encoded; jika masih terjadi, periksa log debug di `storage/logs/laravel.log` untuk field yang ditolak.
- `REQUEST_FORBIDDEN_ERROR`: key valid tapi tidak punya izin disbursement — hubungi Xendit dashboard atau support untuk mengaktifkan Disbursement pada akun sandbox/production.
- Jika respons sukses tapi `status` bukan `SUCCESS`, tangani sesuai business logic (mis. job retry/backoff atau set status PENDING).

4) Debugging cepat
- Aktifkan `XENDIT_DEBUG=1` untuk mencetak request/response (log tidak menampilkan secret key secara penuh, hanya indikasi). Periksa `storage/logs/laravel.log`.
- Gunakan `php artisan queue:work --tries=3` untuk memproses job dan melihat log runtime.

5) Keamanan & Idempotensi
- Simpan `XENDIT_API_KEY` di secret manager (GitHub Secrets / server env). Jangan commit.
- Adapter menambahkan header `X-IDEMPOTENCY-KEY` pada request. Pastikan idempotency dipertahankan saat retry.

6) Monitoring & Runbook ops
- Simpan setiap percobaan payout dan respons provider ke DB (attempt record). Buat alert/monitoring ketika jumlah gagal > threshold (contoh: 3x gagal per jam).
- Tindakan on-call: cek `laravel.log`, periksa request-id yang tercetak di log debug, hubungi Xendit support jika `REQUEST_FORBIDDEN_ERROR` atau error 5xx berulang.

7) Deploy / CI notes
- Tambahkan secrets di GitHub repo: `XENDIT_API_KEY` (production), `PAYOUT_GATEWAY`.
- Jangan jalankan `payouts:test-gateway` di environment `production` tanpa flag `--force`.

8) Catatan pengembang
- Jika sandbox menolak field tertentu, adapter mencoba fallback variant payload. Jika masih gagal, minta contoh payload yang diterima Xendit atau gunakan Mock gateway untuk CI.

-- Akhir RUNBOOK --
<!-- markdownlint-disable -->

# Runbook — Quick Production Steps

This runbook lists concrete commands to perform a production deploy and to operate the payout system.

1) Pull code & install dependencies

```bash
cd /var/www/tukangdekat/backend
git pull origin main
composer install --no-dev --prefer-dist --optimize-autoloader
```

2) Environment

Edit `.env` with production values. Add payout provider credentials:

```
APP_ENV=production
APP_DEBUG=false
DB_HOST=...
DB_DATABASE=...
DB_USERNAME=...
DB_PASSWORD=...

# Payout provider (example Xendit)
PAYOUT_GATEWAY=xendit
XENDIT_API_KEY=sk_prod_.....
XENDIT_BASE_URL=https://api.xendit.co
```

3) Migrate and seed

```bash
php artisan migrate --force
php artisan db:seed --class=AdminSeeder --force
php artisan db:seed --class=TreasurerSeeder --force
```

> Seeder `TreasurerSeeder` membuat user bendahara default. Ubah email dan password menggunakan env `TREASURER_SEED_EMAIL`, `TREASURER_SEED_PHONE`, dan `TREASURER_SEED_PASSWORD`.

4) Cache & optimize

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

5) Start scheduler & queue workers

Cron entry (one-liner):

```cron
* * * * * cd /var/www/tukangdekat/backend && php artisan schedule:run >> /dev/null 2>&1
```

Enable systemd worker (example):

```bash
sudo cp deploy/laravel-queue.service /etc/systemd/system/laravel-queue.service
sudo systemctl daemon-reload
sudo systemctl enable --now laravel-queue.service
sudo journalctl -u laravel-queue -f
```

Alerting & Monitoring:

- Configure `PAYOUT_ALERT_WEBHOOK` or `PAYOUT_ALERT_EMAIL` in `.env` to receive alerts when failed payouts exceed the configured threshold.
- The app schedules `payouts:alert --since=60` every 10 minutes by default.
- Check Prometheus-compatible metrics at `/api/metrics` by default.
- Override the metrics route segment with `MONITORING_METRICS_PATH` in `.env` if required.
- Gunakan `backend/docs/MONITORING_RUNBOOK.md` untuk detail runbook monitoring.
- Gunakan `backend/docs/TESTING_RUNBOOK.md` untuk prosedur pengujian dan validasi.

6) Manual operations

- Run aggregation manually: `php artisan payouts:process`
- Dispatch pending payouts manually: `php artisan payouts:process-pending --limit=25`
- Restart queue workers after deploy: `php artisan queue:restart`

7) Monitoring & retries

- Check `provider_payout_attempts` for failures:

```sql
SELECT * FROM provider_payout_attempts WHERE status = 'FAILED' ORDER BY created_at DESC LIMIT 50;
```

- Retry failed payout from admin UI or via `SendProviderPayoutJob` dispatch.

- Export failed attempts to CSV: `php artisan payouts:export-failed --since=60 --email=ops@example.com`

8) Rollback

- If a deploy causes issues, revert to previous git tag/commit and run migrations rollback only if safe.

If you want, I can also add automated health checks or a small management script to export failed attempts and email alerts.
