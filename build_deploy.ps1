<#
.SYNOPSIS
    Build and Deploy script for FinanceManager2026.
.DESCRIPTION
    Handles version bumping, building (APK/AppBundle/Web), and deploying to Firebase.
    Adapted from example/build_deploy.sh.
.PARAMETER Environment
    Target environment: 'dev' (Staging) or 'prod'. Default is 'dev'.
.PARAMETER Platform
    Target platform: 'web', 'android', or 'all'. Default is 'all'.
.PARAMETER BuildMode
    Flutter build mode: 'debug', 'profile', or 'release'.
.PARAMETER NoDeploy
    If set, skips the deployment step.
.PARAMETER NoClean
    If set, skips 'flutter clean'.
.PARAMETER BypassTest
    If set, skips unit tests.
#>
param(
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev",

    [ValidateSet("web", "android", "all")]
    [string]$Platform = "all",

    [ValidateSet("debug", "profile", "release")]
    [string]$BuildMode = "",

    [switch]$NoDeploy,
    [switch]$NoClean,
    [switch]$BypassTest,
    [switch]$NoGit
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$Config = @{
    dev  = @{
        ProjectId          = "finance-manager-2026-stg"
        AndroidAppId       = "1:420654277416:android:4b750e6abdb68a7150661d" # Verified Staging App ID
        DartDefines        = "APP_ENV=dev"
        Flavor             = "dev"
        EntryPoint         = "lib/main_dev.dart"
        GoogleServicesPath = "android/app/google-services.staging.json"
    }
    prod = @{
        ProjectId          = "finance-manager-2026"
        AndroidAppId       = "1:599792752048:android:0c9d7449fce60754c07275" # Verified Prod App ID
        DartDefines        = "APP_ENV=prod"
        Flavor             = "prod"
        EntryPoint         = "lib/main.dart"
        GoogleServicesPath = "android/app/google-services.prod.json"
    }
}

# --- Defaults ---
if ([string]::IsNullOrWhiteSpace($BuildMode)) {
    if ($Environment -eq "prod") { $BuildMode = "release" } else { $BuildMode = "debug" }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " FinanceManager2026 Build & Deploy" -ForegroundColor Cyan
Write-Host "=================================================="
Write-Host "  Environment : $Environment"
Write-Host "  Platform    : $Platform"
Write-Host "  Build Mode  : $BuildMode"
Write-Host "--------------------------------------------------"

# 1. Clean
if (-not $NoClean) {
    Write-Host "-> Step 1: Cleaning..." -ForegroundColor Yellow
    flutter clean
}

# 2. Version Bump
Write-Host "-> Step 2: Version Bump..." -ForegroundColor Yellow
$PubspecPath = "pubspec.yaml"
$PubspecContent = Get-Content $PubspecPath
$VersionLine = $PubspecContent | Select-String "version:" | Select-Object -First 1
$CurrentVersion = $VersionLine.ToString().Split(":")[1].Trim()
$VersionName = $CurrentVersion.Split("+")[0]
$BuildNumber = [int]$CurrentVersion.Split("+")[1]
$NewBuildNumber = $BuildNumber + 1
$NewVersion = "$VersionName+$NewBuildNumber"

$PubspecContent = $PubspecContent -replace "version: $CurrentVersion", "version: $NewVersion"
Set-Content $PubspecPath $PubspecContent
Write-Host "   Bumped version to $NewVersion" -ForegroundColor Green

# 3. Tests
if ($Environment -eq "prod" -or (-not $BypassTest)) {
    Write-Host "-> Step 3: Running Tests..." -ForegroundColor Yellow
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "Tests failed." }
}
else {
    Write-Host "-> Step 3: Tests Skipped." -ForegroundColor Gray
}

# 3.b Configure Android Google Services
if ($Platform -eq "android" -or $Platform -eq "all") {
    $EnvConfig = $Config[$Environment]
    if (Test-Path $EnvConfig.GoogleServicesPath) {
        Write-Host "-> Configuring Android for $($Environment)..." -ForegroundColor Yellow
        Copy-Item -Path $EnvConfig.GoogleServicesPath -Destination "android/app/google-services.json" -Force
        Write-Host "   Copied $($EnvConfig.GoogleServicesPath) to android/app/google-services.json"
    }
    else {
        Write-Warning "Google Services file not found at $($EnvConfig.GoogleServicesPath)"
    }
}

# 4. Build
Write-Host "-> Step 4: Building..." -ForegroundColor Yellow
$EnvConfig = $Config[$Environment]
# Common Args
$CommonArgs = @(
    "--$BuildMode",
    "-t", $EnvConfig.EntryPoint,
    "--dart-define", $EnvConfig.DartDefines,
    "--build-name", $VersionName,
    "--build-number", $NewBuildNumber.ToString()
)

if ($Platform -eq "web" -or $Platform -eq "all") {
    Write-Host "   Building Web..."
    # Web does not support --flavor
    flutter build web @CommonArgs
    if ($LASTEXITCODE -ne 0) { throw "Web Build Failed" }
}

if ($Platform -eq "android" -or $Platform -eq "all") {
    # Android needs --flavor
    $AndroidArgs = $CommonArgs + @("--flavor", $EnvConfig.Flavor)
    
    if ($BuildMode -eq "release") {
        Write-Host "   Building Android AppBundle..."
        flutter build appbundle @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw "Android AAB Build Failed" }
    }
    else {
        Write-Host "   Building Android APK..."
        flutter build apk @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw "Android APK Build Failed" }
    }
}

if ($NoDeploy) {
    Write-Host "Build Only. process finished." -ForegroundColor Green
    Exit 0
}

# 5. Git Operations
if (-not $NoGit) {
    Write-Host "-> Step 5: Git Operations..." -ForegroundColor Yellow
    git add pubspec.yaml
    git commit -m "chore: bump version to $NewVersion"
    git push
    git tag -a "v$NewVersion" -m "Release $NewVersion ($Environment)"
    git push origin "v$NewVersion"
}
else {
    Write-Host "-> Step 5: Git Operations Skipped (-NoGit)." -ForegroundColor Gray
}

# 6. Deploy
Write-Host "-> Step 6: Deploying..." -ForegroundColor Yellow

# Web Deploy
if ($Platform -eq "web" -or $Platform -eq "all") {
    Write-Host "   Deploying Hosting to $($EnvConfig.ProjectId)..."
    firebase deploy --only hosting --project $EnvConfig.ProjectId
}

# Android Deploy (APK to App Distribution)
if ($Platform -eq "android" -or $Platform -eq "all") {
    if ($BuildMode -eq "debug") {
        $ApkPath = "build/app/outputs/flutter-apk/app-$($EnvConfig.Flavor)-$BuildMode.apk"
        if (Test-Path $ApkPath) {
            Write-Host "   Uploading APK to App Distribution..."
            firebase appdistribution:distribute "$ApkPath" --app $EnvConfig.AndroidAppId --release-notes "Ver $NewVersion" --groups "testers"
        }
    }
    else {
        Write-Host "   Release build: Manual upload to Play Store suggested for AAB."
    }
}

Write-Host "=================================================="
Write-Host " SUCCESS" -ForegroundColor Green
Write-Host "=================================================="
