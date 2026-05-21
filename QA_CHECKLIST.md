# QA Checklist — Final Release

1. Environment & Secrets
   - [ ] `APP_ENV` benar (staging/production)
   - [ ] `XENDIT_API_KEY`, `MIDTRANS_SERVER_KEY` diset (staging jika perlu)
   - [ ] `PAYOUT_ALERT_WEBHOOK` dan `PAYOUT_ALERT_EMAIL` diset

2. Database & Migrations
   - [ ] `php artisan migrate --force` berhasil di staging
   - [ ] Seeders jika diperlukan dijalankan

3. Queue & Jobs
   - [ ] Worker queue berjalan (`php artisan queue:work` atau systemd)
   - [ ] Jobs `SendProviderPayoutJob` dan `SendPayoutAlertWebhook` dieksekusi

4. Payments & Webhook
   - [ ] Midtrans webhook test: terima callback dan verifikasi signature
   - [ ] Xendit sandbox: kirim payout test (`php artisan payouts:test-gateway`) dan cek DB `payout_provider_responses`

5. Integration Tests
   - [ ] Jalankan `php artisan test` seluruhnya (unit + feature)
   - [ ] Run e2e tests (Playwright) untuk treasurer export jika tersedia

6. Release
   - [ ] Tag rilis dibuat (`v1.0.0`) dan Release notes diisi
   - [ ] Deploy ke staging via workflow/Ansible
   - [ ] Smoke test setelah deploy (basic API health check)

7. Post-release
   - [ ] Monitor logs & alerts (Sentry/Log files) 30 menit setelah release
   - [ ] Konfirmasi payout flows berjalan untuk 1–3 sample payouts
