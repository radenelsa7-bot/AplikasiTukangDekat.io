# Runbook Monitoring

## Ringkasan

Runbook ini mendokumentasikan setup monitoring dan alerting untuk pipeline payout backend TukangDekat.

## Endpoint Metrics

- Endpoint: `/api/metrics` secara default (route dikonfigurasi di `config/monitoring.php` dan diekspos di bawah prefix API)
- Bisa override melalui `MONITORING_METRICS_PATH` di `.env`
- Format: teks plain Prometheus exposition format
- Contoh:
  - `curl http://localhost:8000/api/metrics`

## Metrik yang Disediakan

- `tukangdekat_app_metrics_generated_timestamp`
- `tukangdekat_monitoring_window_minutes`
- `tukangdekat_payout_attempts_total`
- `tukangdekat_failed_payout_attempts_total`
- `tukangdekat_recent_payout_attempts_total`
- `tukangdekat_recent_failed_payout_attempts_total`
- `tukangdekat_payout_failure_rate_percentage_last_window`
- `tukangdekat_payout_provider_response_records_total`
- `tukangdekat_notification_logs_total`
- `tukangdekat_alert_trigger_threshold`
- `tukangdekat_alert_critical_threshold`
- `tukangdekat_alert_triggered`
- `tukangdekat_alert_severity`

## Alerting

1. Konfigurasikan `PAYOUT_ALERT_EMAIL` atau `PAYOUT_ALERT_WEBHOOK` di `.env`.
2. Gunakan perintah berikut:
   - `php artisan payouts:alert --since=60`
3. Perintah ini mengirim email/webhook ketika jumlah gagal payout dalam window mencapai atau melebihi threshold yang dikonfigurasi di `config/monitoring.php`.
4. Jika kegagalan melebihi `MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD`, alert akan ditandai sebagai `critical`; jika tidak, akan ditandai sebagai `warning`.

## Verifikasi Deploy

- Pastikan `PROMETHEUS_ENABLED=true` jika menggunakan Prometheus.
- Verifikasi nilai di `config/monitoring.php`:
  - `MONITORING_PAYOUT_FAILURE_WINDOW`
  - `MONITORING_PAYOUT_FAILURE_ALERT_THRESHOLD`
  - `MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD`

## Troubleshooting

- Jika `/api/metrics` mengembalikan 500, periksa log Laravel di `storage/logs/laravel.log`.
- Jika jumlah kegagalan terlihat salah, pastikan tabel `provider_payout_attempts` terisi dengan benar.
- Jika alert tidak terkirim, pastikan `PAYOUT_ALERT_EMAIL` atau `PAYOUT_ALERT_WEBHOOK` terpasang dan layanan email/webhook dapat dijangkau.

## Catatan

Runbook ini adalah bagian dari pekerjaan BE1 untuk monitoring dan reliability backend. Harap disinkronkan dengan `backend/RUNBOOK.md` dan `backend/config/monitoring.php`.
