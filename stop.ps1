<#
.SYNOPSIS
    Stop all Low-Code Docker Suite services
#>

param(
    [switch]$RemoveVolumes
)

$ProjectRoot = $PSScriptRoot

Write-Host "Stopping Low-Code Docker Suite..." -ForegroundColor Cyan
Write-Host ""

# Stop additional services first
Write-Host "[1/2] Stopping additional services..." -ForegroundColor Yellow
Push-Location "$ProjectRoot\services"
if ($RemoveVolumes) {
    docker compose down -v
} else {
    docker compose down
}
Pop-Location

# Stop Supabase
Write-Host "[2/2] Stopping Supabase services..." -ForegroundColor Yellow
Push-Location "$ProjectRoot\supabase"
if ($RemoveVolumes) {
    docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
} else {
    docker compose -f docker-compose.yml -f docker-compose.override.yml down
}
Pop-Location

Write-Host ""
Write-Host "All services stopped!" -ForegroundColor Green

if ($RemoveVolumes) {
    Write-Host "Volumes were removed. All data has been deleted." -ForegroundColor Yellow
} else {
    Write-Host "Volumes preserved. Use -RemoveVolumes to delete all data." -ForegroundColor Gray
}
Write-Host ""
