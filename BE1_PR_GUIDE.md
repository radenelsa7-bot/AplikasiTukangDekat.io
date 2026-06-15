# 📝 Pull Request Guide - BE1 (Nabilah Asana)

**For**: Nabilah Asana (Backend 1)  
**Project**: TukangDekat  
**Date**: 2026-06-04

---

## 🎯 Tujuan Dokumen

Panduan lengkap untuk membuat dan manage pull request (PR) untuk setiap task BE1. Ikuti template dan checklist ini untuk memastikan PR berkualitas dan mudah di-review.

---

## 📋 PR Checklist (Sebelum Create PR)

Sebelum membuat PR, pastikan:

- [ ] Code sudah ditulis & tested locally
- [ ] Semua tests passing: `php vendor/bin/phpunit`
- [ ] Code sudah di-commit dengan message yang jelas
- [ ] Branch sudah di-push ke remote
- [ ] No conflicts dengan main branch
- [ ] Documentation updated (README, comments)
- [ ] No hardcoded credentials atau sensitive data
- [ ] .env.example diupdate jika ada config baru

---

## 🔧 Setup untuk PR

### 1. Memastikan Branch Updated
```bash
# Switch ke branch Anda
git checkout feature/backend-121-nabilah-integration-tests

# Update dari main
git fetch origin main
git rebase origin/main

# Jika ada conflicts, resolve dan:
git add .
git rebase --continue

# Push updated branch
git push origin feature/backend-121-nabilah-integration-tests --force
```

### 2. Final Local Testing
```bash
# Run all tests
php vendor/bin/phpunit

# Run specific test suite
php vendor/bin/phpunit tests/Feature/PayoutPipeline

# Check for errors
php artisan tinker  # Quick check if no syntax errors
```

### 3. Create PR via GitHub CLI
```bash
# Create PR dengan interactive mode
gh pr create

# Or dengan flag
gh pr create --title "..." --body "..." --base main

# Push to draft if not ready
gh pr create --draft --title "..." --body "..."
```

---

## 📝 PR Template untuk Task 1 (Integration Tests)

### Judul PR:
```
[Backend-121] Integration test untuk network failures dan backoff
```

### Body PR (Template):
```markdown
## 📝 Deskripsi

Menambahkan comprehensive integration test untuk payout pipeline yang mencakup:
- Network failure scenarios (timeout, connection lost)
- Retry/backoff mechanism testing
- Provider unavailable handling
- Logging dan fallback response

## 🔧 Perubahan

### Tests Added:
- `tests/Feature/PayoutPipeline/NetworkFailureTest.php` - 5 test cases
- `tests/Feature/PayoutPipeline/RetryBackoffTest.php` - 6 test cases
- `tests/Unit/Services/PayoutAdapterTest.php` - 8 test cases
- `tests/Unit/Monitoring/MetricsCollectorTest.php` - 7 test cases

### Code Modified:
- `app/Services/XenditPayoutGateway.php` - Hardened retry logic
- `app/Services/PayoutAdapter.php` - Enhanced error handling

### Total: 26 test cases, all passing ✓

## ✅ Test Results

```
PHPUnit 10.x
Feature Tests: 11/11 passing ✓
Unit Tests: 15/15 passing ✓
Total Coverage: 82% for payout module
```

## 📋 Checklist

- [x] All tests passing locally
- [x] CI/CD pipeline green
- [x] Code reviewed (self-review)
- [x] No hardcoded secrets
- [x] README/docs updated
- [x] Follows code style guidelines

## 🔗 Referensi

- GitHub Issue: #121
- Milestone: Backend – Integration & Reliability
- PROGRESS_TRACKING.md
- BE1_NABILAH_ASANA_ANALYSIS.md

## 📸 Screenshots (jika ada)

N/A (Backend tests)

## 🤔 Notes untuk Reviewer

- Network failure tests menggunakan mocked HTTP client
- Semua test cases deterministic (no flaky tests)
- Performance impact: minimal (tests run in <2s)
- Ready for production deployment
```

---

## 📝 PR Template untuk Task 2 (Monitoring & Alerts)

### Judul PR:
```
[Backend-124] Monitoring/metrics produksi dan alerting
```

### Body PR (Template):
```markdown
## 📝 Deskripsi

Setup monitoring infrastructure untuk production payout pipeline:
- Sentry integration untuk error tracking
- Prometheus metrics endpoint (`/api/metrics`)
- Payout pipeline monitoring (success rate, failure rate, response time)
- Alert infrastructure setup

## 🔧 Perubahan

### Services Created:
- `app/Services/MonitoringService.php` - Core monitoring logic
- `app/Services/MetricsCollectorService.php` - Metrics collection

### Configuration:
- `config/monitoring.php` - Monitoring configuration
- `.env.example` - Sentry DSN template
- `routes/api.php` - `/api/metrics` endpoint

### Monitoring Metrics:
```
GET /api/metrics (Prometheus format)

Available metrics:
- payout_success_total{*}
- payout_failure_total{reason="*"}
- payout_response_time_seconds
- payout_retry_attempts_total
- webhook_failure_total
- queue_job_count
```

## ✅ Verification

- [x] Sentry integration working
- [x] Metrics endpoint accessible
- [x] All metrics being collected
- [x] Prometheus format valid
- [x] Configuration example provided
- [x] Tests passing

## 📊 Monitoring Status

| Component | Status | Details |
|-----------|--------|---------|
| Sentry | ✅ Working | Exception & transaction tracking |
| Prometheus | ✅ Working | Metrics endpoint responding |
| Payout Tracking | ✅ Working | All metrics collected |
| Alerts (pending) | ⏳ Next | Rules to be configured |

## 🔗 Referensi

- GitHub Issue: #124
- Milestone: Backend – Deploy & Monitoring
- PROGRESS_TRACKING.md
- BE1_NABILAH_ASANA_ANALYSIS.md

## 🤔 Notes untuk Reviewer

- Sentry DSN should be added to GitHub Secrets, not committed
- Metrics endpoint is public (consider adding auth in future)
- Performance impact: <5ms per request
- Already integrated with existing payout services
- Ready for staging deployment
```

---

## 📝 PR Template untuk Task 3 (Documentation)

### Judul PR:
```
[Backend-129] Dokumentasi & Runbook
```

### Body PR (Template):
```markdown
## 📝 Deskripsi

Comprehensive documentation untuk monitoring, testing, dan runbook:
- Updated backend/RUNBOOK.md dengan monitoring procedures
- Created docs/MONITORING_RUNBOOK.md untuk monitoring guide
- Created docs/TESTING_RUNBOOK.md untuk testing guide
- Updated README.md dengan sections baru

## 📄 Files Created/Updated

### Updated:
- `backend/RUNBOOK.md` - +Monitoring section, +Troubleshooting
- `backend/README.md` - +Monitoring, +Testing, +FAQ sections

### Created:
- `docs/MONITORING_RUNBOOK.md` - Complete monitoring guide
- `docs/TESTING_RUNBOOK.md` - Testing procedures
- `docs/EMERGENCY_PROCEDURES.md` - Emergency escalation

## 📋 Dokumentasi Coverage

### Monitoring Runbook mencakup:
- [ ] Sentry dashboard access & usage
- [ ] Metrics interpretation (/api/metrics)
- [ ] Alert threshold meanings
- [ ] Emergency escalation
- [ ] Common issues & solutions

### Testing Runbook mencakup:
- [ ] Running integration tests
- [ ] Test failure troubleshooting
- [ ] Adding new test cases
- [ ] Local test environment setup

### Emergency Procedures:
- [ ] Escalation path
- [ ] On-call rotation
- [ ] Critical alert handling
- [ ] Communication protocol

## ✅ Checklist

- [x] All documentation complete
- [x] Proofread & grammar checked
- [x] Links & references verified
- [x] Screenshots/diagrams included (if applicable)
- [x] Team reviewed for clarity
- [x] Ready for distribution

## 🔗 Referensi

- GitHub Issue: #129
- Milestone: Frontend – Alerts, Tests & Notes
- PROGRESS_TRACKING.md
- Previous PRs (#121, #124)

## 📢 Notes untuk Reviewer

- Documentation is written for both technical & non-technical audience
- All procedures have been tested & validated
- Ready for team training & distribution
- Can be printed or published to wiki
```

---

## 🔄 PR Review Process

### Step 1: Submit PR
```bash
gh pr create --title "..." --body "..."
```

### Step 2: Wait for CI/CD
- ✅ Tests should pass
- ✅ Linting should pass (if configured)
- ✅ Code coverage should be adequate

### Step 3: Address Review Comments
```bash
# Make changes based on feedback
git add .
git commit -m "Review: Address feedback on XYZ"
git push origin feature/backend-xxx

# Re-request review
gh pr review --comment "Changes addressed. Ready for re-review."
```

### Step 4: Get Approval
```bash
# Check PR status
gh pr view

# Expected output:
# ✓ Approved by: backend-team-lead
# ✓ CI/CD passing
# ✓ Ready to merge
```

### Step 5: Merge PR
```bash
# Merge using GitHub CLI
gh pr merge --squash  # OR --rebase

# Or via GitHub web UI
# Click "Merge pull request" button
```

---

## 💬 Tips untuk PR yang Baik

### Judul PR yang Baik:
```
❌ BAD:
  "Fix stuff"
  "Update backend"
  "WIP"

✅ GOOD:
  "[Backend-121] Integration test untuk network failures dan backoff"
  "[Backend-124] Monitoring/metrics produksi dan alerting"
  "[Backend-129] Dokumentasi & Runbook"
```

### Description yang Baik:
```
✅ Includes:
- Clear problem statement
- What was changed and why
- How to test/verify
- List of files changed
- Link to issue & milestone
- Notes for reviewer

❌ Avoid:
- "See commits" (reviewer shouldn't read commits)
- Long paragraphs (use bullet points)
- Technical jargon without explanation
- Committing without PR description
```

### Commit Messages yang Baik:
```
❌ BAD:
  "fix"
  "update"
  "done"
  "asdf"

✅ GOOD:
  "feat: Add network failure test cases for payout pipeline"
  "refactor: Extract monitoring logic to separate service"
  "docs: Add monitoring runbook with procedures"
  "test: Increase coverage to 82% for payout module"

Format: <type>: <description>
Types: feat, fix, refactor, docs, test, chore, style
```

---

## 🚀 Full PR Workflow Example

### 1. Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/backend-121-nabilah-integration-tests
```

### 2. Work on Feature
```bash
# Make changes
git add .
git commit -m "feat: Add network failure test cases"
git commit -m "test: Add retry/backoff test suite"
git commit -m "docs: Update PROGRESS_TRACKING with test results"
```

### 3. Push & Create PR
```bash
git push origin feature/backend-121-nabilah-integration-tests

# Create PR
gh pr create \
  --title "[Backend-121] Integration test untuk network failures dan backoff" \
  --body "$(cat pr_template.md)" \
  --milestone "Backend – Integration & Reliability" \
  --label "role: Backend,testing,priority: high"
```

### 4. Wait for Feedback
```bash
# Check status
gh pr view

# Address any feedback
git commit -m "review: Fix test edge cases per feedback"
git push origin feature/backend-121-nabilah-integration-tests
```

### 5. Merge when Approved
```bash
# Ensure up to date
git fetch origin main
git rebase origin/main

# Merge
gh pr merge --squash
```

### 6. Update Tracking
```bash
# Update BE1_PROGRESS_TRACKING.md
# Mark task as complete
# Update GitHub issue status
```

---

## ✅ Final PR Verification Checklist

Before clicking "Merge":

### Code Quality:
- [ ] All tests passing
- [ ] No console.log or debug code
- [ ] No hardcoded secrets/credentials
- [ ] Code follows project style guide
- [ ] Comments clear and meaningful

### Documentation:
- [ ] README updated (if needed)
- [ ] Code comments added
- [ ] CHANGELOG updated
- [ ] API docs updated (if applicable)

### Testing:
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Manual testing completed
- [ ] Edge cases tested

### Process:
- [ ] Issue is linked
- [ ] Milestone assigned
- [ ] Labels correct
- [ ] Reviewer approved
- [ ] CI/CD pipeline green
- [ ] No merge conflicts

### Post-Merge:
- [ ] Verify main branch has changes
- [ ] Delete feature branch
- [ ] Update PROGRESS_TRACKING.md
- [ ] Close related issues
- [ ] Update project board

---

## 📞 PR Help & Support

### Questions?
1. Check this guide first
2. Look at previous PRs for examples
3. Ask Backend Team Lead
4. Comment on draft PR for early feedback

### Common Issues:
- **PR stuck in review**: Add comment asking for feedback
- **Tests failing**: Run locally with verbose output
- **Merge conflicts**: Rebase from main, resolve, push
- **CI/CD failing**: Check logs, fix issues, push again

---

## 📚 Resources

- [GitHub PR Docs](https://docs.github.com/en/pull-requests)
- [GitHub CLI Docs](https://cli.github.com/manual)
- [Git Branching Guide](https://git-scm.com/book/en/v2/Git-Branching-Branch-Management)

---

**Good luck with your PRs! 🚀**

Remember: A good PR is reviewable, testable, and well-documented.

---

**Document Version**: 1.0  
**Created**: 2026-06-04  
**For**: Nabilah Asana (BE1)

See also:
- BE1_QUICK_START.md
- BE1_NABILAH_ASANA_ANALYSIS.md
- BE1_PROGRESS_TRACKING.md

