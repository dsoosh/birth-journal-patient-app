#!/usr/bin/env pwsh
# Deploy Flutter patient app to Chrome for web debugging

$apiUrl = "http://localhost:8000/api/v1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Deploying Polozne Patient App to Chrome" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: " -NoNewline
Write-Host $apiUrl -ForegroundColor Yellow
Write-Host "Target: " -NoNewline
Write-Host "Chrome (Web)" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "`nProceed with deployment? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nBuilding and launching app in Chrome..." -ForegroundColor Green
flutter run -d chrome --dart-define API_BASE_URL=$apiUrl

Write-Host "`n[OK] Deployment complete!" -ForegroundColor Green
