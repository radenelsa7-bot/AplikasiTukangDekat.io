# Runbook Pengujian

## Tujuan
Runbook ini menjelaskan cara memverifikasi monitoring payout, alerting, dan perilaku aplikasi backend TukangDekat.
Dokumen ini ditujukan untuk developer dan QA agar dapat menjalankan pengujian lokal, staging, dan produksi dengan aman.

## 1. Pemeriksaan Sanity Test Lokal

### Jalankan unit dan feature test

```bash
cd backend
composer install
php artisan test
```

### Jalankan pengujian monitoring spesifik

```bash
cd backend
php artisan test --filter Monitoring
```

### Jalankan pengujian alur payout

```bash
cd backend
php artisan test --filter PayoutFlowTest
```

## 2. Validasi endpoint metrics

### Verifikasi `/api/metrics`

Jalankan terhadap server backend lokal:

```bash
curl http://127.0.0.1:8000/api/metrics
```

Harapan:
- HTTP 200
- Format plain text Prometheus exposition
- Baris metrik berisi `tukangdekat_payout_attempts_total`, `tukangdekat_failed_payout_attempts_total`, `tukangdekat_payout_failure_rate_percentage_last_window`

### Jika metrics hilang atau rusak

- Periksa `config/monitoring.php` untuk `MONITORING_METRICS_PATH` yang benar.
- Pastikan route tersedia di `backend/routes/api.php`.
- Tinjau log Laravel di `storage/logs/laravel.log` untuk error controller atau service.

## 3. Validasi perintah alerting

### Jalankan perintah alert secara manual

```bash
cd backend
php artisan payouts:alert --since=60
```

Harapan:
- Perintah selesai tanpa error fatal.
- Jika terkonfigurasi, mengirim alert webhook atau email sesuai threshold.

### Verifikasi konfigurasi

Pastikan `.env` memiliki salah satu berikut:

```env
PAYOUT_ALERT_EMAIL=ops@example.com
PAYOUT_ALERT_WEBHOOK=https://hooks.example.com/payout-alert
```

Juga verifikasi threshold monitoring di `config/monitoring.php`:
- `MONITORING_PAYOUT_FAILURE_ALERT_THRESHOLD`
- `MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD`

## 4. Daftar verifikasi staging

### Deploy ke staging

- Deploy backend dan jalankan migrasi.
- Jalankan scheduler dan queue worker.
- Pastikan environment staging memiliki nilai `.env` yang benar untuk monitoring dan alerting.

### Smoke test monitoring payout

- Jalankan alur payout di staging.
- Periksa bahwa catatan percobaan payout dibuat di tabel `provider_payout_attempts`.
- Pastikan `/api/metrics` mengembalikan hitungan valid setelah alur payout.
- Jalankan `php artisan payouts:alert --since=60` dan verifikasi tidak ada error runtime.

### Verifikasi pengiriman alert

- Jika menggunakan webhook Slack, pastikan contoh alert muncul di channel yang dikonfigurasi.
- Jika menggunakan email, pastikan email alert contoh terkirim.
- Jika tidak aman memicu alert nyata, tinjau output perintah dan pastikan koneksi sudah benar.

## 5. Investigasi kegagalan

### Sumber kegagalan umum

- Kunci `.env` hilang: `PAYOUT_ALERT_EMAIL`, `PAYOUT_ALERT_WEBHOOK`, atau override route monitoring.
- Route metrics diblokir oleh auth atau middleware.
- Catatan database tidak dimasukkan ke `provider_payout_attempts`.
- Queue worker tidak berjalan untuk job payout.

### Perintah troubleshooting

```bash
cd backend
php artisan queue:work --tries=3
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```

### Pemeriksaan database

```sql
SELECT status, COUNT(*) FROM provider_payout_attempts GROUP BY status;
SELECT * FROM provider_payout_attempts WHERE status = 'FAILED' ORDER BY created_at DESC LIMIT 50;
```

## 6. Hal yang perlu didokumentasikan selanjutnya

- Pastikan route alert di Sentry atau layanan alert eksternal.
- Catat URL staging endpoint untuk `/api/metrics` dan dashboard status.
- Simpan detail channel notifikasi alert di dokumentasi deploy.

---

Perbarui file ini jika alur monitoring atau threshold alert berubah.
