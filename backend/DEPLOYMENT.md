<!-- markdownlint-disable -->

# Penerapan & Daftar Periksa Produksi

Dokumen ini mengumpulkan langkah-langkah minimal dan praktis untuk menjalankan aplikasi Laravel ini dalam produksi dan mengoperasikan pekerja latar belakang serta penjadwal.

## Prasyarat

- PHP 8.1+ dengan ekstensi yang diperlukan (pdo_mysql, mbstring, openssl, json, curl, zip untuk pembuatan XLSX jika Anda membutuhkan Excel di sisi server). Instal `ext-zip` untuk mengaktifkan perpustakaan XLSX sisi server.
- Composer terinstal
- Server web (nginx / Apache) dan supervisor proses (systemd atau Supervisor) untuk pekerja antrian.
- Database (MySQL/MariaDB) dapat diakses dan dikonfigurasi di `.env`

## Langkah-langkah penerapan dasar

1. Klona repositori pada server ke `/var/www/tukangdekat` (contoh).
2. Instal dependensi PHP:

```bash
cd /var/www/tukangdekat/backend
composer install --no-dev --prefer-dist --optimize-autoloader
php artisan key:generate
cp .env.example .env
# perbarui .env dengan DB, mail, dan kunci API provider
```

3. Izin file:

```bash
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
```

4. Migrasi dan seed database (jalankan setelah mengonfigurasi `.env`):

```bash
php artisan migrate --force
php artisan db:seed --class=AdminSeeder --force   # jika Anda memiliki seeder untuk membuat admin/bendahara
```

5. Optimasi cache dan config:

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Penjadwal (cron)

Proyek ini mendaftarkan perintah terjadwal di `bootstrap/app.php`. Untuk menjalankan penjadwal setiap menit, tambahkan ini ke crontab sistem:

```cron
* * * * * cd /var/www/tukangdekat/backend && php artisan schedule:run >> /dev/null 2>&1
```

Ini akan mengeksekusi entri berikut yang dikonfigurasi oleh aplikasi:

- `payouts:process` — setiap hari pada `01:00` (agregat pembayaran PAID menjadi pembayaran provider)
- `payouts:process-pending --limit=25` — setiap 5 menit (dispatch pekerjaan untuk pembayaran yang tertunda)

## Pekerja antrian (contoh systemd)

Buat unit systemd agar pekerja antrian berjalan dengan andal dan restart jika terjadi kegagalan. Contoh unit `/etc/systemd/system/laravel-queue.service`:

```ini
[Unit]
Description=Pekerja Antrian Laravel
After=network.target

[Service]
User=www-data
Group=www-data
Restart=always
RestartSec=3
ExecStart=/usr/bin/php /var/www/tukangdekat/backend/artisan queue:work --sleep=3 --tries=3 --queue=default
SyslogIdentifier=laravel-queue
Environment=APP_ENV=production
Environment=QUEUE_CONNECTION=database

[Install]
WantedBy=multi-user.target
```

Perintah untuk mengaktifkan:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now laravel-queue.service
sudo journalctl -u laravel-queue -f
```

Atau gunakan Supervisor (contoh):

```
[program:laravel-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/tukangdekat/backend/artisan queue:work --sleep=3 --tries=3 --queue=default
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/laravel-queue.log
```

## Server web

Gunakan konfigurasi nginx/Apache produksi standar. Pastikan `public/` adalah akar dokumen dan PHP-FPM dikonfigurasi untuk pengguna `www-data`.

## Perintah operasional

- Restart antrian saat menerapkan kode baru: `php artisan queue:restart`
- Pemicu agregasi secara manual: `php artisan payouts:process`
- Dispatch pembayaran yang tertunda secara manual: `php artisan payouts:process-pending --limit=25`

## Catatan & Keamanan

- Rute helper pengembangan `/test-login/{role}` telah dihapus. Jangan aktifkan kembali rute helper dev di produksi.
- Simpan kredensial gateway provider di luar repositori dan simpan di variabel lingkungan (`.env`) atau manajer rahasia.
- Pantau tabel `provider_payout_attempts` untuk upaya yang gagal dan coba lagi melalui UI admin atau perintah `php artisan`.

Jika Anda mau, saya juga dapat menambahkan file unit `systemd` contoh di atas ke dalam repo di bawah `deploy/` untuk referensi mudah.
