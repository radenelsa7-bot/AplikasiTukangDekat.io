<!-- markdownlint-disable -->

# Setup GitHub & Runtime Secrets

Daftar secret yang diperlukan untuk fitur payout, webhook, dan deploy.

- `XENDIT_API_KEY` — Xendit API key (sandbox/production)
- `XENDIT_SECRET` — optional webhook secret for Xendit (if used)
- `MIDTRANS_SERVER_KEY` — Midtrans server key (for webhook verification)
- `MIDTRANS_CLIENT_KEY` — Midtrans client key (optional)
- `MIDTRANS_WEBHOOK_KEY` — Midtrans webhook signature secret
- `PAYOUT_GATEWAY` — `mock` or `xendit`

- `DEPLOY_HOST` — SSH host for deployment (example: `app.example.com`)
- `DEPLOY_USER` — SSH user (example: `deploy`)
- `DEPLOY_KEY` — SSH private key (PEM) for `DEPLOY_USER`
- `DEPLOY_PATH` — Deploy path on server (example: `/var/www/app`)
- `DEPLOY_PORT` — SSH port (optional, default `22`)

- `APP_ENV` — `production` or `staging`
- `APP_KEY` — Laravel `APP_KEY` (base64:...)
- `DB_CONNECTION`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` — Database creds

Quick commands

1) Using `gh` CLI (recommended):

```
gh secret set XENDIT_API_KEY -b"$XENDIT_API_KEY"
gh secret set MIDTRANS_SERVER_KEY -b"$MIDTRANS_SERVER_KEY"
gh secret set DEPLOY_HOST -b"$DEPLOY_HOST"
gh secret set DEPLOY_USER -b"$DEPLOY_USER"
gh secret set DEPLOY_KEY -b"$(cat ~/.ssh/deploy_id_rsa)"
gh secret set DEPLOY_PATH -b"/var/www/app"
```

2) Using `curl` + GitHub API (when `GH_API_TOKEN` available):

```
REPO_OWNER=Fajar1180
REPO_NAME=Project-Aplikasi-Tukang-Dekat
GH_API_TOKEN=ghp_xxx

curl -X PUT -H "Authorization: token $GH_API_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/secrets/XENDIT_API_KEY \
  -d '{"encrypted_value":"REPLACE_WITH_ENCRYPTED_VALUE","key_id":"REPLACE_KEY_ID"}'
```

See GitHub docs for encrypting values: https://docs.github.com/actions/security-guides/encrypted-secrets

3) Local/dev quick tests

Set `.env` for local mock gateway:

```
PAYOUT_GATEWAY=mock
XENDIT_API_KEY=__unused__
```

Run tests:

```
cd backend
php artisan test --filter PayoutFlowTest
php artisan test --filter PayoutRetryTest
```

Test gateway command (uses configured gateway):

```
php artisan payouts:test-gateway 10000 --to=08123456789
```

If using Xendit sandbox, set `XENDIT_API_KEY` to sandbox key and `PAYOUT_GATEWAY=xendit`.

### Skrip bantu untuk memasang secrets

Di folder `deploy/` tersedia skrip contoh untuk memudahkan pemasangan secrets:

- `set_github_secrets.sh`: gunakan `gh` CLI untuk menyimpan secrets ke GitHub Actions. Contoh:

```bash
./deploy/set_github_secrets.sh Fajar1180 Project-Aplikasi-Tukang-Dekat deploy/secrets/github_secrets.txt
```

- `set_server_env.sh`: copy file lokal KEY=VALUE ke server remote via `scp` (overwrite). Contoh:

```bash
./deploy/set_server_env.sh deploy@app.example.com /var/www/tukangdekat/backend/.env deploy/secrets/.env
```

- `ansible_set_secrets.yml`: contoh playbook Ansible yang menyalin `deploy/secrets/.env` ke server target.

Gunakan skrip ini sebagai template dan sesuaikan sesuai kebijakan keamanan tim (gunakan secret manager bila memungkinkan).

### Contoh file secrets

Saya juga menambahkan contoh file di `deploy/secrets/`:

- `github_secrets.txt.example` — contoh format KEY=VALUE untuk `set_github_secrets.sh`.
- `.env.example` — contoh `.env` untuk server.
- `ansible_inventory.example` — contoh inventory untuk Ansible.
- `ANSIBLE_VAULT_README.md` — panduan singkat Ansible Vault.

Isi file contoh tersebut mohon dilengkapi sebelum menjalankan skrip.
Webhook alert (Slack)

Jika Anda ingin menerima notifikasi ke channel Slack, buat Incoming Webhook di Slack dan masukkan URL-nya ke environment variable `PAYOUT_ALERT_WEBHOOK`.

Contoh `.env` entry:

```
PAYOUT_ALERT_WEBHOOK=https://<your-slack-incoming-webhook-url>
PAYOUT_ALERT_EMAIL=ops@example.com
```

Catatan: sistem mengirim payload yang diformat khusus untuk Slack jika URL mengandung `hooks.slack.com`. Notifikasi webhook dikirim melalui job queue (`SendPayoutAlertWebhook`) sehingga membutuhkan queue worker yang berjalan di server, contohnya:

```
php artisan queue:work --sleep=3 --tries=3
```

Pastikan service/systemd untuk queue worker di-restart saat deploy.
Server deploy notes

- Upload `DEPLOY_KEY` to GitHub Secrets (as `DEPLOY_KEY`) and set `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`.
- After secrets set, trigger Actions → Deploy workflow (or merge PR to `main`).
- On server, ensure systemd unit for queue worker is configured and restarted after deploy.

If you want, saya bisa: men-generate skrip `deploy/set_github_secrets.sh` yang menggunakan `gh` atau menyiapkan Playbook Ansible untuk menulis `.env` di server.
