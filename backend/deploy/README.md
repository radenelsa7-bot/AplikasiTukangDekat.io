<!-- markdownlint-disable -->

Panduan Deploy Singkat — Queue & Scheduler Laravel (Bahasa Indonesia)

1) Menyalin unit systemd (contoh)

```bash
sudo cp deploy/laravel-queue.service /etc/systemd/system/laravel-queue.service
sudo systemctl daemon-reload
sudo systemctl enable --now laravel-queue.service
sudo journalctl -u laravel-queue -f
```

2) Atau gunakan Supervisor (contoh)

```bash
sudo cp deploy/supervisor.conf /etc/supervisor/conf.d/laravel-queue.conf
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-queue:*
tail -f /var/log/laravel-queue.log
```

3) Pastikan cron menjalankan scheduler setiap menit:

```cron
* * * * * cd /var/www/tukangdekat/backend && php artisan schedule:run >> /dev/null 2>&1
```

4) Variabel lingkungan penting
- Tempatkan `XENDIT_API_KEY`, `PAYOUT_GATEWAY`, `PAYOUT_ALERT_WEBHOOK`, dan `PAYOUT_ALERT_EMAIL` di environment server atau di `.env` (gunakan secret manager bila memungkinkan).

5) Uji pipeline setelah deploy

```bash
php artisan migrate --force
php artisan payouts:test-gateway 10000 --to=08123456789
php artisan payouts:process
php artisan payouts:process-pending --limit=25
```

6) Smoke test

Run the deploy smoke test script after deploy and worker restart:

```bash
./deploy/smoke-test.sh
```

Or run the Laravel command directly:

```bash
php artisan deploy:smoke --url="http://127.0.0.1"
```

7) Monitoring
- `php artisan payouts:alert --since=60` and `php artisan payouts:export-failed --since=60 --email=ops@example.com`

Catatan
- Sesuaikan path dengan layout deploy Anda. Contoh di atas menggunakan `/var/www/tukangdekat/backend`.

Contoh injeksi environment

- systemd (set env di unit file): edit `deploy/laravel-queue.service` dan tambahkan baris `Environment=` untuk secrets. Contoh:

```
[Service]
Environment=APP_ENV=production
Environment=PAYOUT_GATEWAY=xendit
Environment=XENDIT_API_KEY=sk_prod_....
ExecStart=/usr/bin/php /var/www/tukangdekat/backend/artisan queue:work --sleep=3 --tries=3 --queue=default
```

- supervisor (set environment pada program): di `deploy/supervisor.conf` tambahkan `environment=`. Contoh:

```
[program:laravel-queue]
command=php /var/www/tukangdekat/backend/artisan queue:work --sleep=3 --tries=3 --queue=default
environment=APP_ENV="production",PAYOUT_GATEWAY="xendit",XENDIT_API_KEY="sk_prod_..."
user=www-data
```

Catatan keamanan: lebih baik mengambil secrets dari secret store seperti Vault atau AWS Secrets Manager dan jangan menyimpan secrets di file. Pastikan file unit/config hanya dapat dibaca oleh root dan jangan commit file yang berisi secrets ke git.
