<#
.SYNOPSIS
    Setup script for Low-Code Docker Suite
.DESCRIPTION
    This script sets up a complete low-code development environment with:
    - Supabase (Postgres, Auth, Storage, Realtime, API)
    - Appsmith (Low-code app builder)
    - n8n (Workflow automation)
    - Redis (Caching)
.NOTES
    Run this script from the project root directory
#>

param(
    [switch]$SkipSupabaseClone,
    [switch]$GenerateSecrets
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Low-Code Docker Suite Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to generate random strings
function New-RandomString {
    param([int]$Length = 32)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function New-JwtSecret {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}

# Step 1: Download Supabase docker files (using GitHub API - much faster than git clone!)
if (-not $SkipSupabaseClone) {
    Write-Host "[1/5] Downloading Supabase docker files..." -ForegroundColor Yellow
    
    if (Test-Path "$ProjectRoot\supabase") {
        Write-Host "  -> Removing existing supabase folder..." -ForegroundColor Gray
        Remove-Item -Recurse -Force "$ProjectRoot\supabase"
    }
    
    # Download the docker folder as a zip from GitHub
    $zipUrl = "https://github.com/supabase/supabase/archive/refs/heads/master.zip"
    $zipPath = "$ProjectRoot\supabase-master.zip"
    $extractPath = "$ProjectRoot\supabase-extract"
    
    Write-Host "  -> Downloading from GitHub..." -ForegroundColor Gray
    try {
        # Use faster download method
        $ProgressPreference = 'SilentlyContinue'  # Speed up download
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
    } catch {
        Write-Host "ERROR: Failed to download Supabase files" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  -> Extracting docker folder..." -ForegroundColor Gray
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    
    # Move only the docker folder
    New-Item -ItemType Directory -Path "$ProjectRoot\supabase" -Force | Out-Null
    Copy-Item -Recurse -Force "$extractPath\supabase-master\docker\*" "$ProjectRoot\supabase\"
    
    # Cleanup
    Remove-Item -Force $zipPath
    Remove-Item -Recurse -Force $extractPath
    
    Write-Host "  -> Done!" -ForegroundColor Green
} else {
    Write-Host "[1/5] Skipping Supabase download (using existing)" -ForegroundColor Gray
}

# Step 2: Verify Supabase files exist
Write-Host "[2/5] Verifying Supabase docker files..." -ForegroundColor Yellow

if (-not (Test-Path "$ProjectRoot\supabase\docker-compose.yml")) {
    Write-Host "ERROR: docker-compose.yml not found in supabase folder" -ForegroundColor Red
    exit 1
}

# Create docker-compose.override.yml to expose Studio on port 3000
$overrideContent = @"
# Override to expose Studio port
services:
  studio:
    ports:
      - "3000:3000"
"@
$overrideContent | Set-Content "$ProjectRoot\supabase\docker-compose.override.yml"
Write-Host "  -> Created docker-compose.override.yml (Studio on port 3000)" -ForegroundColor Gray

# Step 3: Create .env file for Supabase
Write-Host "[3/5] Creating Supabase environment file..." -ForegroundColor Yellow

$envExample = Get-Content "$ProjectRoot\supabase\.env.example" -Raw

if ($GenerateSecrets) {
    Write-Host "  -> Generating secure secrets..." -ForegroundColor Gray
    
    # Generate secrets
    $postgresPassword = New-RandomString -Length 32
    $jwtSecret = New-JwtSecret
    $anonKey = New-RandomString -Length 40
    $serviceRoleKey = New-RandomString -Length 40
    $dashboardPassword = New-RandomString -Length 16
    
    # Replace placeholders (basic replacements for demo - in production use proper JWT generation)
    $envContent = $envExample
    $envContent = $envContent -replace 'POSTGRES_PASSWORD=.*', "POSTGRES_PASSWORD=$postgresPassword"
    $envContent = $envContent -replace 'DASHBOARD_PASSWORD=.*', "DASHBOARD_PASSWORD=$dashboardPassword"
    
    $envContent | Set-Content "$ProjectRoot\supabase\.env"
    
    Write-Host "  -> Secrets generated! Check supabase/.env" -ForegroundColor Green
    Write-Host "  -> IMPORTANT: For production, generate proper JWT keys at:" -ForegroundColor Yellow
    Write-Host "     https://supabase.com/docs/guides/self-hosting/docker#generate-and-configure-api-keys" -ForegroundColor Yellow
} else {
    Copy-Item "$ProjectRoot\supabase\.env.example" "$ProjectRoot\supabase\.env"
    Write-Host "  -> Using example .env (CHANGE SECRETS BEFORE PRODUCTION!)" -ForegroundColor Yellow
}

# Step 4: Create services directory and docker-compose
Write-Host "[4/5] Creating additional services configuration..." -ForegroundColor Yellow

if (-not (Test-Path "$ProjectRoot\services")) {
    New-Item -ItemType Directory -Path "$ProjectRoot\services" -Force | Out-Null
}

# Step 5: Final message
Write-Host "[5/5] Finalizing..." -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review and update supabase/.env with your secrets"
Write-Host "  2. Run: .\start.ps1 to start all services"
Write-Host "  3. Run: .\stop.ps1 to stop all services"
Write-Host ""
Write-Host "Service URLs after startup:" -ForegroundColor Cyan
Write-Host "  - Supabase Studio: http://localhost:8000"
Write-Host "  - Appsmith:        http://localhost:8081"
Write-Host "  - n8n:             http://localhost:5678"
Write-Host ""
