# Monitoring Runbook

## Overview

This runbook documents the monitoring and alerting setup for the TukangDekat backend payout pipeline.

## Metrics Endpoint

- Endpoint: `/api/metrics` by default (the actual route is configured in `config/monitoring.php` and exposed under the API prefix)
- Override via `MONITORING_METRICS_PATH` in `.env` if needed
- Format: plain text Prometheus exposition format
- Example:
  - `curl http://localhost:8000/api/metrics`

## Metrics Provided

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

1. Configure `PAYOUT_ALERT_EMAIL` or `PAYOUT_ALERT_WEBHOOK` in `.env`.
2. Use the existing command:
   - `php artisan payouts:alert --since=60`
3. This command sends an email/webhook when failed payout attempts in the window reach or exceed the configured alert threshold in `config/monitoring.php`.
4. If failures exceed `MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD`, the alert is marked as `critical`; otherwise it is `warning`.

## Deployment Verification

- Ensure `PROMETHEUS_ENABLED=true` if using Prometheus.
- Verify `config/monitoring.php` values:
  - `MONITORING_PAYOUT_FAILURE_WINDOW`
  - `MONITORING_PAYOUT_FAILURE_ALERT_THRESHOLD`
  - `MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD`

## Troubleshooting

- If `/api/metrics` returns 500, check Laravel logs in `storage/logs/laravel.log`.
- If failure counts look incorrect, verify the `provider_payout_attempts` table is populated.
- If alerts are not sent, verify `PAYOUT_ALERT_EMAIL` or `PAYOUT_ALERT_WEBHOOK` is set and the mail/webhook service is reachable.

## Notes

This runbook is part of BE1 work for backend monitoring and reliability. It should be kept in sync with `backend/RUNBOOK.md` and `backend/config/monitoring.php`.
