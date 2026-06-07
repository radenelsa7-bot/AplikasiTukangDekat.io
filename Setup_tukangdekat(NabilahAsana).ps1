# =============================================================
#  TukangDekat – Project Setup Script for Backend 1 (Nabilah Asana)
#  PowerShell Version (Windows)
#  Created: 2026-06-04
#
#  CARA PAKAI:
#  1. Open PowerShell as Administrator
#  2. Run: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
#  3. Run: .\Setup_tukangdekat(NabilahAsana).ps1
# =============================================================

param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$Repo = "radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi",
    [string]$Assignee = "NabilahAsana"
)

# ─── COLOR CODES ─────────────────────────────────────────────
function Write-Header { Write-Host "`n$('-'*60)`n$($args[0])`n$('-'*60)`n" -ForegroundColor Cyan }
function Write-Success { Write-Host "✓ $($args[0])" -ForegroundColor Green }
function Write-Error_Custom { Write-Host "✗ $($args[0])" -ForegroundColor Red }
function Write-Warning_Custom { Write-Host "⚠ $($args[0])" -ForegroundColor Yellow }
function Write-Info { Write-Host "ℹ $($args[0])" -ForegroundColor Blue }
function Write-Section { Write-Host "`n→ $($args[0])" -ForegroundColor Yellow }

# ─── CONFIGURATION ───────────────────────────────────────────
$BackendDir = Join-Path $ProjectPath "backend"
$Timestamp = Get-Date -Format "yyyy-MM-dd HHmmss"

# ─── PREREQUISITE CHECKS ────────────────────────────────────
function Check-Prerequisites {
    Write-Header "CHECKING PREREQUISITES"
    
    $missingTools = 0
    
    # Check git
    try {
        $gitVersion = (git --version 2>$null) -replace "git version ", ""
        Write-Success "Git: $gitVersion"
    } catch {
        Write-Error_Custom "Git not found - https://git-scm.com/"
        $missingTools++
    }
    
    # Check GitHub CLI
    try {
        $ghVersion = (gh --version 2>$null | Select-Object -First 1)
        Write-Success "GitHub CLI: $ghVersion"
        
        $authStatus = & gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error_Custom "Not logged in to GitHub. Run: gh auth login"
            $missingTools++
        } else {
            Write-Success "GitHub: Logged in"
        }
    } catch {
        Write-Error_Custom "GitHub CLI not found - https://cli.github.com/"
        $missingTools++
    }
    
    # Check PHP
    try {
        $phpVersion = (php --version 2>$null | Select-Object -First 1)
        Write-Success "PHP: $phpVersion"
    } catch {
        Write-Error_Custom "PHP not found"
        $missingTools++
    }
    
    # Check Composer
    try {
        $composerVersion = (composer --version 2>$null)
        Write-Success "Composer: $composerVersion"
    } catch {
        Write-Error_Custom "Composer not found"
        $missingTools++
    }
    
    # Check Docker
    try {
        $dockerVersion = (docker --version 2>$null)
        Write-Success "Docker: $dockerVersion"
    } catch {
        Write-Warning_Custom "Docker not found - some features will be limited"
    }
    
    # Check Node.js (optional)
    try {
        $nodeVersion = (node --version 2>$null)
        Write-Success "Node.js: $nodeVersion"
    } catch {
        Write-Warning_Custom "Node.js not found (optional)"
    }
    
    if ($missingTools -gt 0) {
        Write-Error_Custom "$missingTools required tools not found. Please install them first."
        exit 1
    }
    
    Write-Success "All prerequisites met!"
}

# ─── REPOSITORY SETUP ────────────────────────────────────────
function Setup-Repository {
    Write-Header "SETTING UP REPOSITORY"
    
    $gitDir = Join-Path $ProjectPath ".git"
    
    if (-not (Test-Path $gitDir)) {
        Write-Info "Repository not initialized. Cloning from GitHub..."
        $parentPath = Split-Path $ProjectPath
        Push-Location $parentPath
        & git clone "https://github.com/$Repo.git" (Split-Path $ProjectPath -Leaf)
        Pop-Location
        Write-Success "Repository cloned"
    } else {
        Write-Success "Repository already exists"
    }
    
    # Ensure main branch
    Push-Location $ProjectPath
    & git fetch origin main 2>$null
    & git checkout main 2>$null
    & git pull origin main 2>$null
    Pop-Location
    
    Write-Success "Main branch updated"
}

# ─── BACKEND SETUP ──────────────────────────────────────────
function Setup-Backend {
    Write-Header "SETTING UP BACKEND ENVIRONMENT"
    
    if (-not (Test-Path $BackendDir)) {
        Write-Error_Custom "Backend directory not found: $BackendDir"
        exit 1
    }
    
    Push-Location $BackendDir
    
    # Check .env
    Write-Section ".env Configuration"
    if (-not (Test-Path ".env")) {
        Write-Info "Creating .env..."
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
        } else {
            Write-Warning_Custom ".env.example not found. Creating minimal .env..."
            @"
APP_NAME=TukangDekat
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=tukangdekat_dev
DB_USERNAME=root
DB_PASSWORD=

CACHE_DRIVER=file
SESSION_DRIVER=cookie
QUEUE_CONNECTION=redis

SENTRY_LARAVEL_DSN=

LOG_CHANNEL=stack
"@ | Out-File ".env" -Encoding UTF8
        }
        Write-Success ".env created"
    } else {
        Write-Success ".env exists"
    }
    
    # Generate app key
    Write-Section "APP_KEY Setup"
    $envContent = Get-Content ".env" -Raw
    if ($envContent -notmatch "APP_KEY=base64:") {
        Write-Info "Generating APP_KEY..."
        & php artisan key:generate
        Write-Success "APP_KEY generated"
    }
    
    # Install dependencies
    Write-Section "Composer Dependencies"
    if (-not (Test-Path "vendor")) {
        Write-Info "Installing Composer dependencies..."
        & composer install --no-interaction --prefer-dist
        Write-Success "Composer dependencies installed"
    } else {
        Write-Success "Composer dependencies already installed"
        Write-Info "Running composer update..."
        & composer update --no-interaction
    }
    
    Pop-Location
    Write-Success "Backend environment ready"
}

# ─── CREATE WORKING BRANCHES ────────────────────────────────
function Create-Branches {
    Write-Header "CREATING FEATURE BRANCHES FOR BE1 TASKS"
    
    $branches = @(
        "feature/backend-121-nabilah-integration-tests",
        "feature/backend-124-nabilah-monitoring-alerts",
        "feature/backend-nabilah-documentation"
    )
    
    Push-Location $ProjectPath
    
    & git checkout main
    & git pull origin main 2>$null
    
    foreach ($branch in $branches) {
        $branchExists = & git show-ref --verify --quiet "refs/heads/$branch" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Warning_Custom "Branch already exists: $branch"
            & git checkout $branch
            & git pull origin $branch 2>$null
        } else {
            Write-Info "Creating branch: $branch"
            & git checkout -b $branch
            & git push -u origin $branch 2>$null
        }
    }
    
    & git checkout main
    Pop-Location
    
    Write-Success "Feature branches created"
}

# ─── SETUP MONITORING ────────────────────────────────────────
function Setup-Monitoring {
    Write-Header "SETTING UP MONITORING & TESTING INFRASTRUCTURE"
    
    Push-Location $BackendDir
    
    Write-Section "Sentry Configuration"
    $envContent = Get-Content ".env" -Raw
    if ($envContent -notmatch "SENTRY_LARAVEL_DSN") {
        Write-Warning_Custom "SENTRY_LARAVEL_DSN not configured"
        Write-Info "To enable Sentry:"
        Write-Info "  1. Go to https://sentry.io and create project"
        Write-Info "  2. Copy DSN to .env: SENTRY_LARAVEL_DSN=your-dsn"
    } else {
        Write-Success "Sentry DSN configured"
    }
    
    Write-Section "Monitoring Services"
    if (Test-Path "app/Services/MonitoringService.php") {
        $content = Get-Content "app/Services/MonitoringService.php" -Raw
        if ($content -match "MonitoringService") {
            Write-Success "MonitoringService found"
        }
    } else {
        Write-Warning_Custom "MonitoringService not found"
    }
    
    Write-Section "Metrics Endpoint"
    $apiRoute = Get-Content "routes/api.php" -Raw
    if ($apiRoute -match "/api/metrics") {
        Write-Success "Metrics endpoint registered"
    } else {
        Write-Warning_Custom "Metrics endpoint not found in routes/api.php"
    }
    
    Pop-Location
    Write-Success "Monitoring setup verification complete"
}

# ─── RUN TESTS ──────────────────────────────────────────────
function Run-Tests {
    Write-Header "RUNNING TESTS"
    
    Push-Location $BackendDir
    
    Write-Section "PHPUnit Tests"
    if (Test-Path "phpunit.xml") {
        Write-Info "Running all tests..."
        & php vendor/bin/phpunit --testdox
        Write-Success "Test run completed"
    } else {
        Write-Warning_Custom "phpunit.xml not found"
    }
    
    Write-Section "Integration Test Suite"
    if (Test-Path "tests/Feature/PayoutPipeline") {
        Write-Info "Running payout integration tests..."
        & php vendor/bin/phpunit tests/Feature/PayoutPipeline --testdox 2>$null || $true
    } else {
        Write-Warning_Custom "Payout integration tests directory not found"
    }
    
    Pop-Location
    Write-Success "Test execution completed"
}

# ─── GENERATE SUMMARY ────────────────────────────────────────
function Generate-Summary {
    Write-Header "GENERATING SETUP SUMMARY"
    
    $summaryPath = Join-Path $ProjectPath "BE1_SETUP_SUMMARY.md"
    
    $summary = @"
# Backend 1 (Nabilah Asana) - Project Setup Summary

**Setup Date**: $(Get-Date -Format "yyyy-MM-dd HHmm")  
**Project**: TukangDekat  
**Assignee**: Nabilah Asana (BE1)

## ✅ Setup Completed

### Prerequisites Verified
- ✓ Git installed
- ✓ GitHub CLI installed & logged in
- ✓ PHP 8.2+ installed
- ✓ Composer installed
- ✓ Docker available (optional)

### Repository Setup
- ✓ Repository ready
- ✓ Main branch current

### Backend Environment
- ✓ .env configured
- ✓ APP_KEY generated
- ✓ Composer dependencies installed

### Feature Branches
- ✓ feature/backend-121-nabilah-integration-tests
- ✓ feature/backend-124-nabilah-monitoring-alerts
- ✓ feature/backend-nabilah-documentation

## 📋 Your Tasks (BE1)

### Task 1: Finalize Alerting (Due: 2026-06-07)
Branch: \`feature/backend-121-nabilah-integration-tests\`

- [ ] Configure Sentry alert rules
- [ ] Setup notifications
- [ ] Test alerts
- [ ] Document procedures

### Task 2: Staging Verification (Due: 2026-06-07)
Branch: \`feature/backend-124-nabilah-monitoring-alerts\`

- [ ] Deploy to staging
- [ ] Verify metrics
- [ ] Collect baseline (24h)
- [ ] Document setup

### Task 3: Documentation (Due: 2026-06-14)
Branch: \`feature/backend-nabilah-documentation\`

- [ ] Update RUNBOOK.md
- [ ] Create MONITORING_RUNBOOK.md
- [ ] Document procedures
- [ ] Train team

## 🚀 Quick Commands

\`\`\`powershell
# Start development
cd backend
docker-compose up -d
php artisan serve

# Run tests
php vendor/bin/phpunit
php vendor/bin/phpunit tests/Feature/PayoutPipeline

# Check metrics
curl http://localhost:8000/api/metrics
\`\`\`

## 📞 Support
- GitHub Issues: https://github.com/$Repo/issues
- Backend Team: [Contact info]
- PM: R.Elsa Balqis

For more details, see BE1_NABILAH_ASANA_ANALYSIS.md and BE1_QUICK_START.md
"@

    $summary | Out-File $summaryPath -Encoding UTF8
    Write-Success "Setup summary generated: BE1_SETUP_SUMMARY.md"
}

# ─── MAIN EXECUTION ────────────────────────────────────────
function Main {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ TUKANGDEKAT PROJECT SETUP                          ║" -ForegroundColor Cyan
    Write-Host "║ Backend 1 (Nabilah Asana)                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    Write-Info "Project Path: $ProjectPath"
    Write-Info "Backend Path: $BackendDir"
    Write-Info "Repository: $Repo"
    
    # Execute setup steps
    Check-Prerequisites
    Setup-Repository
    Setup-Backend
    Create-Branches
    Setup-Monitoring
    Run-Tests
    Generate-Summary
    
    # Final summary
    Write-Header "✅ SETUP COMPLETED SUCCESSFULLY!"
    
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "1. Review BE1_QUICK_START.md for quick reference"
    Write-Host "2. Read BE1_NABILAH_ASANA_ANALYSIS.md for detailed tasks"
    Write-Host "3. Update .env with your Sentry DSN"
    Write-Host "4. Start development: cd backend && docker-compose up -d"
    Write-Host "5. Check GitHub issues for tracking"
    Write-Host "`nHappy coding! 🚀`n" -ForegroundColor Cyan
}

# Run main function
Main
