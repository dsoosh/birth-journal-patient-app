#!/usr/bin/env pwsh
# Deploy Flutter patient app to Chrome for web debugging

# Function to get local WiFi IP address
function Get-LocalWifiIP {
    try {
        $ip = ipconfig | Select-String "IPv4 Address" | Select-Object -Last 1 | `
              ForEach-Object { [regex]::Matches($_, '\d+\.\d+\.\d+\.\d+')[0].Value }
        return $ip
    } catch {
        Write-Host "Warning: Could not determine local IP address" -ForegroundColor Yellow
        return "192.168.1.1"  # Fallback
    }
}

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
    $localIp = Get-LocalWifiIP
    $apiUrl = "http://$($localIp):8000/api/v1"
    Write-Host "Using local WiFi IP: $localIp" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Deploying Polozne Patient App to Chrome" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: " -NoNewline
Write-Host $apiUrl -ForegroundColor Yellow
Write-Host "Target: " -NoNewline
Write-Host "Chrome (Web)" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Proceed with deployment? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "Building and launching app in Chrome..." -ForegroundColor Green
flutter run -d chrome --dart-define API_BASE_URL=$apiUrl

Write-Host "[OK] Deployment complete!" -ForegroundColor Green
