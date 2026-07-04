param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("up", "down", "test")]
    [string]$action
)

$composeFile = "docker-compose.yml"

switch ($action) {
    "up" {
        Write-Host "Starting Firebase Emulators & Chromedriver via Docker Compose..." -ForegroundColor Cyan
        if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
            docker-compose -f $composeFile up -d --build
        } elseif (Get-Command "docker" -ErrorAction SilentlyContinue) {
            docker compose -f $composeFile up -d --build
        } else {
            Write-Warning "Docker/Docker Compose not found. Falling back to local background execution..."
            Start-Process firebase -ArgumentList "emulators:start --only firestore,auth" -NoNewWindow
            Start-Process chromedriver -ArgumentList "--port=4444" -NoNewWindow
        }
        Write-Host "Infrastructure is starting up in the background." -ForegroundColor Green
    }
    "down" {
        Write-Host "Stopping Infrastructure..." -ForegroundColor Yellow
        if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
            docker-compose -f $composeFile down
        } elseif (Get-Command "docker" -ErrorAction SilentlyContinue) {
            docker compose -f $composeFile down
        } else {
            Write-Warning "Docker not found. Stopping local processes..."
        }
        
        # Always run local cleanup just in case
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
