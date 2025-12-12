<#
.SYNOPSIS
    Remove Appsmith watermark by patching the AppViewer bundle
.DESCRIPTION
    Patches the AppViewer JavaScript chunk to disable the watermark rendering.
    This modifies the hideWatermark condition to always be false.
    
    Run this after Appsmith is healthy if the watermark is still visible.
#>

$ErrorActionPreference = "Stop"

Write-Host "Applying Appsmith watermark patch..." -ForegroundColor Yellow

# Wait for container to be healthy
$attempts = 0
$maxAttempts = 30
$healthy = $false

Write-Host "Waiting for Appsmith to be ready..."
while (-not $healthy -and $attempts -lt $maxAttempts) {
    $attempts++
    $status = docker inspect --format='{{.State.Health.Status}}' nocode-appsmith 2>$null
    if ($status -eq "healthy") {
        $healthy = $true
    } else {
        Write-Host "  Waiting... ($attempts/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $healthy) {
    Write-Host "ERROR: Appsmith container not healthy. Run 'docker ps' to check status." -ForegroundColor Red
    exit 1
}

# Find the AppViewer chunk file
Write-Host "Finding AppViewer chunk file..."
$chunkFile = docker exec nocode-appsmith sh -c 'ls /opt/appsmith/editor/static/js/AppViewer.*.chunk.js 2>/dev/null | head -1'

if (-not $chunkFile) {
    Write-Host "ERROR: Could not find AppViewer chunk file" -ForegroundColor Red
    exit 1
}

Write-Host "  Found: $chunkFile"

# Check if already patched
$check = docker exec nocode-appsmith sh -c "grep -c 'children:false&&' $chunkFile 2>/dev/null || echo 0"
if ($check -gt 0) {
    Write-Host "Appsmith is already patched. No action needed." -ForegroundColor Green
    exit 0
}

# Apply patch: replace !W&& with false&&
Write-Host "Applying patch..."
docker exec nocode-appsmith perl -i -pe 's/children:!W&&/children:false\&\&/g' $chunkFile

# Verify
$verify = docker exec nocode-appsmith sh -c "grep -c 'children:false&&' $chunkFile 2>/dev/null || echo 0"
if ($verify -gt 0) {
    Write-Host ""
    Write-Host "SUCCESS! Watermark patch applied." -ForegroundColor Green
    Write-Host "Refresh Appsmith in your browser (Ctrl+Shift+F5) to see the change." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NOTE: This patch will be lost if the container is recreated." -ForegroundColor Yellow
    Write-Host "The start.ps1 script applies this automatically on startup." -ForegroundColor Yellow
} else {
    Write-Host "WARNING: Could not verify the patch was applied." -ForegroundColor Yellow
}
