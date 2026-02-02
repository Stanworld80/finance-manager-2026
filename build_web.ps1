$pubspecPath = "pubspec.yaml"

if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found!"
    exit 1
}

$content = Get-Content $pubspecPath -Raw

# Regex to find version like 1.0.0+1
if ($content -match "version: (\d+\.\d+\.\d+)\+(\d+)") {
    $version = $matches[1]
    $buildNumber = [int]$matches[2]
    $newBuildNumber = $buildNumber + 1
    $newVersion = "$version+$newBuildNumber"

    $content = $content -replace "version: \d+\.\d+\.\d+\+\d+", "version: $newVersion"
    Set-Content -Path $pubspecPath -Value $content
    Write-Host "Updated version to $newVersion" -ForegroundColor Green
} else {
    Write-Warning "Version pattern not found in pubspec.yaml. Skipping increment."
}

Write-Host "Building Flutter Web..." -ForegroundColor Cyan
flutter build web

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!" -ForegroundColor Green
} else {
    Write-Error "Build Failed!"
    exit $LASTEXITCODE
}
