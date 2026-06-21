# CI/CD Secret Management & Deployment Guide

This guide describes how to securely inject `GEMINI_API_KEY` and other secrets into the TukangDekat backend during deployment.

---

## 1. GitHub Actions (Recommended)

### Required Secrets Setup

Go to your GitHub repository: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi

Navigate to **Settings** → **Secrets and variables** → **Actions**

Add the following repository secrets:

| Secret Name | Required | Description | Example Value |
|-------------|----------|-------------|----------------|
| `GEMINI_API_KEY` | ✅ YES | Google Gemini API key | `sk-ant-d1a2b3c4...` |
| `DB_HOST` | ✅ YES | Database host | `db.prod.internal` |
| `DB_USERNAME` | ✅ YES | Database user | `app_user` |
| `DB_PASSWORD` | ✅ YES | Database password | `secure_password_here` |
| `DB_DATABASE` | ✅ YES | Database name | `tukangdekat_prod` |
| `DEPLOYMENT_METHOD` | ✅ YES | How to deploy (`docker-run`, `registry-push`, `docker-compose`) | `docker-compose` |
| `DOCKER_REGISTRY` | ❌ OPTIONAL | Docker registry URL (for registry-push) | `ghcr.io` |
| `DEPLOY_TOKEN` | ❌ OPTIONAL | Token for deployment API | `your-deploy-token` |
| `GITHUB_TOKEN` | ✅ Auto | Automatically provided by GitHub | N/A |

### GitHub Actions Workflow

The workflow file `.github/workflows/deploy-chatbot.yml` handles:

**1. Test Stage (runs on all push + PR):**
- PHP 8.3 setup
- MySQL 8.0 service container
- Composer install
- Database migrations
- PHPUnit tests

**2. Build Stage (runs after test):**
- Docker image build: `pm_uas_app:latest`

**3. Deploy Stage (runs on main branch push only):**
- Supports **3 deployment methods** (choose via `DEPLOYMENT_METHOD` secret):
  
  | Method | Use Case | Requirements |
  |--------|----------|--------------|
  | `docker-run` | Local server or SSH | Docker daemon + port 8000 available |
  | `registry-push` | Image registry (GitHub Container Registry) | GitHub Token (auto) |
  | `docker-compose` | Multi-container orchestration | docker-compose.yml + environment export |

- Health check validation:
  - `/health` endpoint returns HTTP 200
  - `/api/chatbot/send` requires authentication (HTTP 401 without token)

**4. Notification:**
- Deployment status logged with commit SHA and actor information

### How to Trigger

**Automatic:** Push to `main` or `feature/fase3-chatbot` branch
```bash
git push origin feature/fase3-chatbot
```

**Manual:** Visit Actions tab → Deploy Chatbot Backend → Run workflow → Select branch

### Step-by-Step Setup Instructions

1. **Add secrets to GitHub:**
   ```bash
   # Go to Settings → Secrets and variables → Actions
   # Click "New repository secret" for each:
   - GEMINI_API_KEY = your-actual-gemini-key
   - DB_HOST = database-server-ip-or-hostname
   - DB_USERNAME = app_database_user
   - DB_PASSWORD = database-password
   - DB_DATABASE = tukangdekat_prod
   - DEPLOYMENT_METHOD = docker-compose  # or docker-run, registry-push
   ```

2. **Verify workflow file exists:**
   ```bash
   ls -la .github/workflows/deploy-chatbot.yml
   ```

3. **Test by pushing to feature branch:**
   ```bash
   git commit -m "test deployment"
   git push origin feature/fase3-chatbot
   ```

4. **Monitor workflow execution:**
   - Go to: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/actions
   - Click "Deploy Chatbot Backend"
   - Watch real-time logs as workflow runs

---

## 2. Manual Deployment with Script

For staging or local deployment, use the provided deployment script:

```bash
cd backend/deploy
chmod +x deploy-with-secrets.sh
./deploy-with-secrets.sh production sk-ant-d1a2b3c4...
```

**What the script does:**
- Accepts environment name and `GEMINI_API_KEY` as arguments
- Creates `.env` file with secrets injected
- Runs migrations
- Clears caches
- Restarts services
- Performs health check

**Requirements:**
- Bash shell
- PHP CLI with Laravel Artisan
- Systemctl (for service restart) or Docker Compose

---

## 3. Docker Compose Deployment

For local development or Docker-based deployment:

```bash
# Create an .env file with secrets
export GEMINI_API_KEY="sk-ant-d1a2b3c4..."
export GEMINI_API_ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent"
export GEMINI_API_MODEL="gemini-1.0"

# Start services with environment injection
docker compose up -d --remove-orphans
```

**Note:** Secrets can also be passed via docker-compose override file (`docker-compose.prod.yml`):

```yaml
version: '3.9'
services:
  app:
    environment:
      GEMINI_API_KEY: ${GEMINI_API_KEY}
      GEMINI_API_ENDPOINT: ${GEMINI_API_ENDPOINT}
      GEMINI_API_MODEL: ${GEMINI_API_MODEL}
```

---

## 4. Health Endpoint Implementation

The GitHub Actions workflow requires a `/health` endpoint to verify deployment success.

### Add Health Route

Create a health check route in `backend/routes/api.php`:

```php
// Public health check endpoint (no authentication required)
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
        'app' => config('app.name'),
        'version' => '1.0.0',
        'environment' => config('app.env'),
    ]);
});

// Optional: Detailed health check with database connectivity
Route::get('/health/detailed', function () {
    try {
        DB::connection()->getPdo();
        $db_status = 'ok';
    } catch (Exception $e) {
        $db_status = 'error: ' . $e->getMessage();
    }
    
    try {
        $gemini_configured = !empty(config('services.gemini.key'));
    } catch (Exception $e) {
        $gemini_configured = false;
    }
    
    return response()->json([
        'status' => 'ok',
        'database' => $db_status,
        'gemini_configured' => $gemini_configured,
        'timestamp' => now()->toIso8601String(),
    ]);
});
```

### How Workflow Verifies Health

```bash
# In GitHub Actions workflow
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health
# Expected output: 200
```

If you see errors like:
- `000` = Connection refused (service not running)
- `404` = Route not found (add health route to routes/api.php)
- `500` = Server error (check logs)

---

## 5. Cloud Secret Managers

### Google Secret Manager (GCP)

```bash
# Create secrets
gcloud secrets create gemini-api-key --replication-policy="automatic" \
  --data-file=- <<< "sk-ant-d1a2b3c4..."

# Grant access to service account
gcloud secrets add-iam-policy-binding gemini-api-key \
  --member="serviceAccount:my-app@my-project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Use in Cloud Run deployment
gcloud run deploy tukangdekat-backend \
  --set-env-vars="GEMINI_API_KEY=sm://gemini-api-key"
```

### AWS Secrets Manager

```bash
# Create secret
aws secretsmanager create-secret \
  --name tukangdekat/gemini-api-key \
  --secret-string "sk-ant-d1a2b3c4..."

# Use in EC2/ECS deployment via IAM role
# Environment variable: GEMINI_API_KEY will be fetched from secrets at runtime
```

---

## 6. Security Best Practices

- ✅ **Never commit secrets to repository** — use `.env.example` only
- ✅ **Rotate keys regularly** — monthly or quarterly
- ✅ **Use least-privilege access** — restrict API key scope to Gemini API only
- ✅ **Audit secret access** — enable logging in GitHub/AWS/GCP
- ✅ **Encrypt secrets in transit** — use HTTPS/TLS for all communications
- ✅ **Monitor for exposed keys** — use tools like `git-secrets`, `truffleHog`

---

## 7. Verification Steps

After deployment, verify secrets are properly injected and service is running:

### Quick Verification

```bash
# 1. Check if container/service is running
docker ps | grep pm_uas_app

# 2. Test health endpoint
curl -s http://localhost:8000/health | jq '.'

# 3. Verify authentication on chatbot endpoint (should return 401)
curl -i http://localhost:8000/api/chatbot/send \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
# Expected: HTTP 401 Unauthorized

# 4. Test with valid authentication token
curl -X POST http://localhost:8000/api/chatbot/send \
  -H "Authorization: Bearer YOUR_SANCTUM_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, chatbot!"}'
# Expected: HTTP 200 with chatbot response or HTTP 429 if rate-limited

# 5. Check environment variables in running container
docker exec pm_uas_app php -r "echo 'GEMINI_API_KEY=' . (getenv('GEMINI_API_KEY') ? '✓ SET' : '✗ NOT SET') . PHP_EOL;"
```

### In-Workflow Verification

The GitHub Actions workflow automatically performs:

1. **Test Stage Health Check:**
   - Runs `php artisan test` (all unit + feature tests)
   - Validates database migrations succeeded
   - Tests API endpoints with fresh data

2. **Deployment Stage Verification:**
   - Checks `/health` endpoint returns HTTP 200
   - Verifies `/api/chatbot/send` requires authentication (HTTP 401)
   - Confirms GEMINI_API_KEY is configured

### Viewing Workflow Logs

```bash
# Live logs in GitHub Actions UI:
https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/actions
→ Click "Deploy Chatbot Backend"
→ Click latest run
→ View real-time step logs

# Or download logs after completion
```

---

## 8. Troubleshooting

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| `Workflow failed at "Deploy to staging/production"` | `DEPLOYMENT_METHOD` secret not set | Add `DEPLOYMENT_METHOD` secret (value: `docker-compose`, `docker-run`, or `registry-push`) |
| `GEMINI_NOT_CONFIGURED` error in logs | `GEMINI_API_KEY` not injected | Verify secret exists and workflow references `${{ secrets.GEMINI_API_KEY }}` |
| `GEMINI_API_ERROR` (401/403) | Invalid or expired API key | Generate new key in Google Cloud Console → Gemini API settings |
| `DB_HOST not found` error | Database secrets not injected | Verify `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `DB_DATABASE` secrets are added |
| Health check returns 502 | Service didn't start or port conflict | Check Docker logs: `docker logs pm_uas_app_<timestamp>` |
| Health check returns 404 | `/health` endpoint not implemented | Add route in `backend/routes/api.php`: `Route::get('/health', function () { return ['status' => 'ok']; });` |
| Chatbot endpoint returns 400 instead of 401 | Authentication middleware issue | Check `auth:sanctum` is applied to route in `routes/api.php` |
| Secret values contain special characters | YAML parsing issues | Wrap values in quotes in secrets UI, or use GitHub CLI |
| Deployment runs on PR but shouldn't | Workflow condition error | Verify `if: github.ref == 'refs/heads/main' && github.event_name == 'push'` in deploy job |
| `docker-compose` command not found in workflow | Missing docker-compose | Use `docker compose` (without hyphen) for Docker Desktop 20.10+ |
| Images not pushed to registry | Registry authentication failed | Verify GitHub Token has permissions, check `docker login` step |

---

## 9. Deployment Checklist

### Before First Deployment

- [ ] **Add GitHub Secrets** (Settings → Secrets and variables → Actions):
  - [ ] `GEMINI_API_KEY` = your Gemini API key
  - [ ] `DB_HOST` = database server IP/hostname
  - [ ] `DB_USERNAME` = database user
  - [ ] `DB_PASSWORD` = database password
  - [ ] `DB_DATABASE` = database name (e.g., `tukangdekat_prod`)
  - [ ] `DEPLOYMENT_METHOD` = choose one:
    - [ ] `docker-compose` (recommended for multi-container)
    - [ ] `docker-run` (simple single-container)
    - [ ] `registry-push` (for pushing to Docker registry)

- [ ] **Verify workflow file exists:**
  ```bash
  ls .github/workflows/deploy-chatbot.yml
  ```

- [ ] **Ensure `/health` endpoint is implemented:**
  ```php
  // In routes/api.php
  Route::get('/health', function () {
      return response()->json(['status' => 'ok', 'timestamp' => now()]);
  });
  ```

### First Deployment

- [ ] Commit and push to `feature/fase3-chatbot` (test run, no deploy)
  ```bash
  git add .
  git commit -m "CI/CD: Add deployment workflow with secret injection"
  git push origin feature/fase3-chatbot
  ```

- [ ] Monitor workflow in GitHub Actions (should test successfully)
  - [ ] Test stage passes all PHPUnit tests
  - [ ] Build stage builds Docker image successfully

- [ ] **Merge to `main`** when test stage passes
  ```bash
  git checkout main
  git merge feature/fase3-chatbot
  git push origin main
  ```

- [ ] Watch deployment job run:
  - [ ] Deployment method selected correctly
  - [ ] Health check passes (HTTP 200)
  - [ ] Chatbot endpoint secured (HTTP 401 without auth)
  - [ ] Notification shows success

### Ongoing Monitoring

- [ ] Check workflow runs after each push to `main`
- [ ] Monitor `/health` endpoint for availability
- [ ] Check logs for `GEMINI_API_ERROR` rate (should be < 5%)
- [ ] Set up GitHub Actions email notifications for failures
- [ ] Review deployment logs periodically for issues

### Post-Deployment Validation

- [ ] Test chatbot endpoint with valid token:
  ```bash
  curl -X POST https://api.tukangdekat.local/api/chatbot/send \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"message": "Test"}'
  ```

- [ ] Monitor rate-limit headers:
  ```bash
  curl -i https://api.tukangdekat.local/api/chatbot/send \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"message": "Test"}'
  # Check for X-RateLimit-* headers in response
  ```

- [ ] Verify database persistence:
  ```sql
  SELECT COUNT(*) FROM chat_messages;
  ```

---

## Sign-Off

- **Completed:** 21 Juni 2026 (FINAL)
- **Status:** ✅ CI/CD secret injection FULLY IMPLEMENTED
- **Deployment Methods Implemented:** 3 (docker-run, registry-push, docker-compose)
- **Health Checks:** Implemented in workflow with verification steps
- **Secrets Management:** GitHub Actions repository secrets with full documentation
- **Documentation:** Comprehensive guide with setup, verification, troubleshooting, and checklist
- **Next Step:** Frontend integration and E2E testing

