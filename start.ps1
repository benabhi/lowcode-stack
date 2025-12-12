<#
.SYNOPSIS
    Start all Low-Code Docker Suite services
.DESCRIPTION
    Starts Supabase, Appsmith, n8n, and Redis with proper health checks
    and applies the Appsmith watermark patch automatically.
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

Write-Host "Starting Low-Code Docker Suite..." -ForegroundColor Cyan
Write-Host ""

# Check if setup was run
if (-not (Test-Path "$ProjectRoot\supabase\.env")) {
    Write-Host "ERROR: Setup not complete. Run .\setup.ps1 first" -ForegroundColor Red
    exit 1
}

# Start Supabase
Write-Host "[1/5] Starting Supabase services..." -ForegroundColor Yellow
Push-Location "$ProjectRoot\supabase"
docker compose -f docker-compose.yml -f docker-compose.override.yml pull
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
Pop-Location

# Wait for database to be healthy
Write-Host "[2/5] Waiting for Supabase database to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$dbHealthy = $false

while (-not $dbHealthy -and $attempt -lt $maxAttempts) {
    $attempt++
    $status = docker inspect --format='{{.State.Health.Status}}' supabase-db 2>$null
    if ($status -eq "healthy") {
        $dbHealthy = $true
        Write-Host "  -> Database is healthy!" -ForegroundColor Green
    } else {
        Write-Host "  -> Waiting for database... ($attempt/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $dbHealthy) {
    Write-Host "WARNING: Database health check timed out. Continuing anyway..." -ForegroundColor Yellow
}

# Restart Supabase to ensure all dependent services start
Write-Host "[3/5] Ensuring all Supabase services are running..." -ForegroundColor Yellow
Push-Location "$ProjectRoot\supabase"
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
Pop-Location

# Wait a bit for services to stabilize
Write-Host "  -> Waiting for services to stabilize (15s)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Start additional services
Write-Host "[4/5] Starting additional services (n8n, Appsmith, Redis)..." -ForegroundColor Yellow
Push-Location "$ProjectRoot\services"
docker compose pull
docker compose up -d
Pop-Location

# Apply Appsmith watermark patch
Write-Host "[5/5] Applying Appsmith watermark patch..." -ForegroundColor Yellow
Write-Host "  -> Waiting for Appsmith to be healthy..." -ForegroundColor Gray

$attempts = 0
$maxAttempts = 24  # 2 minutes max
$healthy = $false
while (-not $healthy -and $attempts -lt $maxAttempts) {
    $attempts++
    $status = docker inspect --format='{{.State.Health.Status}}' nocode-appsmith 2>$null
    if ($status -eq "healthy") {
        $healthy = $true
    } else {
        Start-Sleep -Seconds 5
    }
}

if ($healthy) {
    # Find the AppViewer chunk file (name may vary by version)
    $chunkFile = docker exec nocode-appsmith sh -c 'ls /opt/appsmith/editor/static/js/AppViewer.*.chunk.js 2>/dev/null | head -1'
    if ($chunkFile) {
        # Patch: replace !W&& (hideWatermark check) with false&& to disable watermark
        docker exec nocode-appsmith perl -i -pe 's/children:!W&&/children:false\&\&/g' $chunkFile 2>&1 | Out-Null
        Write-Host "  -> Appsmith watermark patch applied!" -ForegroundColor Green
    } else {
        Write-Host "  -> Could not find AppViewer chunk to patch" -ForegroundColor Yellow
    }
} else {
    Write-Host "  -> Appsmith not ready, run remove-appsmith-watermark.ps1 later" -ForegroundColor Yellow
}

# Final health check
Write-Host ""
Write-Host "Checking service status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$services = @(
    @{Name="supabase-db"; Required=$true},
    @{Name="supabase-studio"; Required=$true},
    @{Name="nocode-n8n"; Required=$true},
    @{Name="nocode-appsmith"; Required=$true},
    @{Name="nocode-redis"; Required=$true}
)

$allHealthy = $true
foreach ($svc in $services) {
    $status = docker inspect --format='{{.State.Status}}' $svc.Name 2>$null
    $health = docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' $svc.Name 2>$null
    
    if ($status -eq "running") {
        if ($health -eq "healthy" -or $health -eq "no-healthcheck") {
            Write-Host "  ✓ $($svc.Name): running" -ForegroundColor Green
        } else {
            Write-Host "  ⏳ $($svc.Name): running ($health)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ $($svc.Name): $status" -ForegroundColor Red
        if ($svc.Required) { $allHealthy = $false }
    }
}

Write-Host ""
if ($allHealthy) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  All Services Started!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Some services may need more time" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Check status: docker ps -a" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "  - Supabase Studio: http://localhost:3000"
Write-Host "  - Appsmith:        http://localhost:8081"
Write-Host "  - n8n:             http://localhost:5678"
Write-Host ""
