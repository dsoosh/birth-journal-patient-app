#!/usr/bin/env pwsh
# Deploy Flutter patient app to connected phone with correct backend IP

# Check if Railway backend is available
$railwayUrl = "https://birth-journal-backend-production.up.railway.app/api/v1/health"
$useRailway = $false

Write-Host "Checking Railway backend availability..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $railwayUrl -Method GET -TimeoutSec 5 -SkipHttpsVerification -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Railway backend is available" -ForegroundColor Green
        $apiUrl = "https://birth-journal-backend-production.up.railway.app/api/v1"
        $useRailway = $true
    }
} catch {
    Write-Host "✗ Railway backend is not reachable" -ForegroundColor Yellow
}

# Fallback to local WiFi if Railway not available
if (-not $useRailway) {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | 
        Where-Object { 
            $_.IPAddress -notlike '127.*' -and 
            $_.IPAddress -notlike '169.254.*' -and 
            $_.InterfaceAlias -like '*Wi-Fi*' 
        } |
        Select-Object -First 1).IPAddress
    
    if (-not $ipAddress) {
        Write-Host "Error: Could not determine Wi-Fi IP address and Railway is unavailable" -ForegroundColor Red
        exit 1
    }
    
    $apiUrl = "http://${ipAddress}:8000/api/v1"
    Write-Host "Using local WiFi IP: $ipAddress" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Deploying Polozne Patient App" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: " -NoNewline
Write-Host $apiUrl -ForegroundColor Yellow
Write-Host ""

# Check if device is connected
Write-Host "Checking for connected devices..." -ForegroundColor Gray
flutter devices

$confirmation = Read-Host "Proceed with deployment? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "Building and deploying app..." -ForegroundColor Green
flutter run --dart-define API_BASE_URL=$apiUrl

Write-Host "[OK] Deployment complete!" -ForegroundColor Green
