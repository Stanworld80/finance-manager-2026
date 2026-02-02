param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("up", "down", "test")]
    [string]$action
)

switch ($action) {
    "up" {
        Write-Host "Starting Firebase Emulators & Chromedriver..." -ForegroundColor Cyan
        Start-Process firebase -ArgumentList "emulators:start --only firestore,auth" -NoNewWindow
        Start-Process chromedriver -ArgumentList "--port=4444" -NoNewWindow
        Write-Host "Infrastructure is starting up in the background." -ForegroundColor Green
    }
    "down" {
        Write-Host "Killing Firebase Emulators & Chromedriver..." -ForegroundColor Yellow
        Stop-Process -Name "firebase" -ErrorAction SilentlyContinue
        Stop-Process -Name "chromedriver" -ErrorAction SilentlyContinue
        Write-Host "Infrastructure stopped." -ForegroundColor Green
    }
    "test" {
        Write-Host "Running Web Integration Tests..." -ForegroundColor Cyan
        flutter drive `
            --driver=test_driver/integration_test.dart `
            --target=integration_test/app_test.dart `
            -d web-server
    }
}
