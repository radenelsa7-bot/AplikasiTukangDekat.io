# Deploy Smoke Report (for PM)

Branch: feature/backend-123-deploy-smoke
Pull Request: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/pull/38
Date: 6 Juni 2026

Summary
- Objective: Finalize smoke-test artefacts and documentation to validate deployment readiness.
- Status: Documentation and smoke-test scripts prepared; smoke execution pending on staging.

What I updated
- `backend/DEPLOY_STATUS.md`: updated status, added step-by-step smoke-test instructions and environment requirements.
- `backend/.github/workflows/ci-staging.yml`: improved staging CI workflow to skip when secrets are missing and updated triggers to include `feature/backend-123-deploy-smoke`.
- Confirmed presence of:
  - `deploy/smoke-test.sh` (script to run smoke test)
  - `app/Console/Commands/DeploySmokeTest.php` (artisan `deploy:smoke` command)
  - Supervisor configuration: `deploy/supervisor.conf`

How to verify (Ops)
1. Ensure server has PHP (>=8.1), composer, database and redis configured.
2. Ensure queue worker running (systemd or supervisor).
3. From backend directory run:

```bash
./deploy/smoke-test.sh
# or
php artisan deploy:smoke --url="https://staging.example.com"
```

Expected outcome: exit code 0 and printed information about health check and artisan readiness commands.

## Current Work Update
- Current backend feature branch: `feature/backend-120-reviews-rating-api`
- Completed DP auto-create order flow and moved to Reviews & Rating API work.
- Added provider review summary endpoint and rating aggregation support.
- Added feature tests for review creation and provider rating summary.
- Local verification blocked because PHP runtime is not available in this editor environment.
- Next planned step: run the new Review API tests and validate the `/api/reviews/provider/{id}/summary` endpoint once PHP runtime is available.

Notes
- I pushed the documentation update to branch `feature/backend-123-deploy-smoke` on the remote.
- GitHub Actions are now configured to run the staging workflow for this branch when repository secrets are available.
- Pull request #38 is open and ready for review.
- Smoke test execution is pending staging environment access.

Blockers
- Local smoke test via Docker cannot be executed in this environment because Docker is not installed.
- Staging environment access is required to complete smoke validation and production queue worker testing.

Next steps (to be done on staging environment)
- Execute smoke test and record results in this file or `backend/DEPLOY_STATUS.md`.
- If smoke test passes, mark `Full smoke test validation` and `Production queue worker testing` as completed in `backend/DEPLOY_STATUS.md`.
