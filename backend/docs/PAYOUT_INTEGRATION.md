<!-- markdownlint-disable -->

Panduan Integrasi Gateway Payout (Xendit) — Project Aplikasi Tukang Dekat

Tujuan
- Menjelaskan langkah aman untuk mengaktifkan gateway payout (Xendit) di staging/production.

Langkah singkat (sandbox)
1. Daftar akun Xendit sandbox: https://dashboard.xendit.co/signup (pilih sandbox).
2. Dapatkan `API Key` sandbox dari Dashboard → API Keys.
3. Tambahkan variabel di `.env` pada server/staging:

PAYOUT_GATEWAY=xendit
XENDIT_API_KEY=live_or_sandbox_key_here
XENDIT_BASE_URL=https://api.xendit.co
PAYOUT_MAX_ATTEMPTS=3

4. Pastikan `APP_ENV=staging` atau `APP_ENV=production` sesuai.
5. Jalankan migration & queue worker di server:

```bash
php artisan migrate --force
php artisan queue:restart
php artisan schedule:run   # untuk pengujian manual
php artisan payouts:process
php artisan payouts:process-pending --limit=10
php artisan payouts:alert --since=60
```

Catatan keamanan
- Jangan commit `XENDIT_API_KEY` ke Git. Simpan di environment atau secret manager (AWS Secrets Manager, GitHub Actions Secrets, .env pada server yang aman).
- Beri akses minimal: gunakan sandbox key untuk pengujian, gunakan live key hanya di production.
- Jika menggunakan CI/CD, inject key dari secret store, jangan simpan di repo.

Mode pengujian lokal
- Jika `XENDIT_API_KEY` tidak ada, aplikasi akan gunakan `MockPayoutGateway`.
- Untuk memaksa kegagalan saat pengujian UI, ada toggle `force_fail` pada endpoint admin.

Verifikasi end-to-end
1. Buat pembayaran `PAID` pada tabel `payments` (staging sandbox).
2. Jalankan `php artisan payouts:process` untuk membuat `provider_payouts`.
3. Jalankan `php artisan payouts:process-pending` untuk dispatch job ke queue.
4. Jalankan worker: `php artisan queue:work --once` atau biarkan supervisor menjalankan worker.
5. Periksa tabel `provider_payout_attempts` untuk status hasil.

Test gateway via artisan
- Terdapat command artisan `payouts:test-gateway` untuk menguji gateway konfigurasi.
- Contoh: jalankan di staging/local (Mock jika tidak ada `XENDIT_API_KEY`):

```bash
php artisan payouts:test-gateway 10000 --to=08123456789
```

Jika ingin memaksa percobaan pada environment `production`, tambahkan flag `--force`.

Monitoring & Alert
- Set `PAYOUT_ALERT_WEBHOOK` atau `PAYOUT_ALERT_EMAIL` di `.env`.
- Gunakan `php artisan payouts:alert --since=60` untuk mengirim alert untuk kegagalan terakhir 60 menit.

Runbook singkat produksi
- Pastikan `supervisor`/`systemd` menjalankan `php artisan queue:work --sleep=3 --tries=3`.
- Pastikan cron menjalankan scheduler setiap menit (`* * * * * php /path/artisan schedule:run >> /dev/null 2>&1`).

Butuh bantuan lebih lanjut?
- Jika ingin saya lanjutkan otomatisasi end-to-end, beri saya `XENDIT sandbox API key` atau izinkan saya tetap menggunakan `MockPayoutGateway` untuk verifikasi.

Men-suntikkan secrets (contoh)
- Menggunakan skrip di server (salin `deploy/set-secrets.sh` ke server dan jalankan):

```bash
# contoh: tambahkan XENDIT_API_KEY dan PAYOUT_GATEWAY
sudo deploy/set-secrets.sh /var/www/tukangdekat/backend/.env XENDIT_API_KEY=sk_sandbox_... PAYOUT_GATEWAY=xendit
```

- Menggunakan Ansible (contoh playbook `deploy/ansible_set_secrets.yml`):

```bash
ansible-playbook -i inventory deploy/ansible_set_secrets.yml --extra-vars "env_path=/var/www/tukangdekat/backend/.env xendit_key=sk_sandbox_..."
```

- Menggunakan GitHub Actions / CI: simpan `XENDIT_API_KEY` di Secrets repo (`Settings → Secrets`) dan injeksikan sebagai ENV saat deploy.

Catatan: jangan kirim kunci lewat chat atau commit ke repo. Gunakan secret store atau provider secret manager.
