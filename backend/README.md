<!-- markdownlint-disable MD033 MD041 -->

<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## Tentang Laravel

Laravel adalah kerangka kerja aplikasi web dengan sintaks ekspresif dan elegan. Kami percaya pengembangan harus menjadi pengalaman yang menyenangkan dan kreatif untuk benar-benar memuaskan. Laravel menghilangkan kesulitan pengembangan dengan memudahkan tugas-tugas umum yang digunakan dalam banyak proyek web, seperti:

- [Mesin routing sederhana dan cepat](https://laravel.com/docs/routing).
- [Kontainer injeksi ketergantungan yang kuat](https://laravel.com/docs/container).
- Multiple back-end untuk penyimpanan [session](https://laravel.com/docs/session) dan [cache](https://laravel.com/docs/cache).
- [ORM database](https://laravel.com/docs/eloquent) ekspresif dan intuitif.
- [Migrasi database](https://laravel.com/docs/migrations) yang independen dari basis data.
- [Pemrosesan pekerjaan latar belakang yang kuat](https://laravel.com/docs/queues).
- [Penyiaran acara secara real-time](https://laravel.com/docs/broadcasting).

Laravel dapat diakses, powerful, dan menyediakan alat yang diperlukan untuk aplikasi besar dan robust.

## Belajar Laravel

Laravel memiliki [dokumentasi](https://laravel.com/docs) paling ekstensif dan menyeluruh serta perpustakaan tutorial video dari semua kerangka kerja aplikasi web modern, membuat semakin mudah untuk memulai dengan kerangka kerja. Anda juga dapat melihat [Laravel Learn](https://laravel.com/learn), di mana Anda akan dipandu dalam membangun aplikasi Laravel modern.

Jika Anda tidak ingin membaca, [Laracasts](https://laracasts.com) dapat membantu. Laracasts berisi ribuan tutorial video tentang berbagai topik termasuk Laravel, PHP modern, unit testing, dan JavaScript. Tingkatkan keterampilan Anda dengan menggali perpustakaan video komprehensif kami.

## Sponsor Laravel

Kami ingin mengucapkan terima kasih kepada sponsor berikut atas pendanaan pengembangan Laravel. Jika Anda tertarik menjadi sponsor, silakan kunjungi [program Mitra Laravel](https://partners.laravel.com).

### Mitra Premium

- **[Vehikl](https://vehikl.com)**
- **[Tighten Co.](https://tighten.co)**
- **[Kirschbaum Development Group](https://kirschbaumdevelopment.com)**
- **[64 Robots](https://64robots.com)**
- **[Curotec](https://www.curotec.com/services/technologies/laravel)**
- **[DevSquad](https://devsquad.com/hire-laravel-developers)**
- **[Redberry](https://redberry.international/laravel-development)**
- **[Active Logic](https://activelogic.com)**

## Berkontribusi

Terima kasih telah mempertimbangkan untuk berkontribusi pada kerangka kerja Laravel! Panduan kontribusi dapat ditemukan di [dokumentasi Laravel](https://laravel.com/docs/contributions).

## Kode Etik

Untuk memastikan komunitas Laravel menyambut semua orang, silakan tinjau dan patuhi [Kode Etik](https://laravel.com/docs/contributions#code-of-conduct).

## Kerentanan Keamanan

Jika Anda menemukan kerentanan keamanan dalam Laravel, silakan kirim email ke Taylor Otwell melalui [taylor@laravel.com](mailto:taylor@laravel.com). Semua kerentanan keamanan akan ditangani dengan cepat.

## Lisensi

Kerangka kerja Laravel adalah perangkat lunak open-source yang dilisensikan di bawah [lisensi MIT](https://opensource.org/licenses/MIT).

## Catatan Proyek (Ringkas)

Proyek ini mencakup laporan bendahara (treasurer), agregasi payout provider, job dispatch untuk payout, pencatatan percobaan (attempt logging), dan ekspor laporan ke CSV/XLS/XLSX.

Helper sementara `/test-login/{role}` telah dihapus — gunakan alur autentikasi yang sebenarnya pada environment produksi.

### Penjadwalan (Scheduler)

Beberapa tugas terjadwal:

- `payouts:process` dijadwalkan tiap hari pada pukul `01:00`.
- `payouts:process-pending --limit=25` dijalankan setiap 5 menit.

Untuk server produksi, tambahkan satu cron entry agar scheduler Laravel dijalankan setiap menit:

```bash
* * * * * cd /path/to/Project-Aplikasi-Tukang-Dekat/backend && php artisan schedule:run >> /dev/null 2>&1
```

### Perintah Berguna

```bash
php artisan payouts:process
php artisan payouts:process-pending --limit=25
php artisan schedule:list
```

### Monitoring & Alerting

- Lihat dokumentasi monitoring di `backend/docs/MONITORING_RUNBOOK.md`.
- Lihat dokumentasi pengujian monitoring di `backend/docs/TESTING_RUNBOOK.md`.
- Pastikan `.env` memiliki konfigurasi `PAYOUT_ALERT_EMAIL` atau `PAYOUT_ALERT_WEBHOOK` jika alerting ingin diaktifkan.
- Untuk memeriksa endpoint metrics lokal:

```bash
curl http://127.0.0.1:8000/api/metrics
```
