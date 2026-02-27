<#
.SYNOPSIS
    Build and Deploy script for FinanceManager2026.
.DESCRIPTION
    Handles version bumping, building (APK/AppBundle/Web), and deploying to Firebase.
    Adapted from example/build_deploy.sh.
.PARAMETER Environment
    Target environment: 'develop', 'staging' or 'prod'. Default is 'staging'.
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
    [ValidateSet("develop", "staging", "prod")]
    [string]$Environment = "staging",

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
    develop = @{
        ProjectId          = "finance-manager-2026-dev"
        AndroidAppId       = "" # Note: Create dev project in Firebase to fill this
        DartDefines        = "APP_ENV=develop"
        Flavor             = "dev" # Default flavor for non-prod
        EntryPoint         = "lib/main_dev.dart" # Might need another entry point eventually
        GoogleServicesPath = "android/app/google-services.dev.json"
    }
    staging = @{
        ProjectId          = "finance-manager-2026-stg"
        AndroidAppId       = "1:420654277416:android:4b750e6abdb68a7150661d" # Verified Staging App ID
        DartDefines        = "APP_ENV=staging"
        Flavor             = "dev"
        EntryPoint         = "lib/main_dev.dart"
        GoogleServicesPath = "android/app/google-services.staging.json"
    }
    prod    = @{
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

# 2. Extract Version and Calculate Build Number
Write-Host "-> Step 2: Version Logic..." -ForegroundColor Yellow
$PubspecPath = "pubspec.yaml"
$PubspecContent = Get-Content $PubspecPath
$VersionLine = $PubspecContent | Select-String "version:" | Select-Object -First 1
$CurrentVersion = $VersionLine.ToString().Split(":")[1].Trim()
# We use the version name (e.g., 1.0.2) from pubspec.yaml
$VersionName = $CurrentVersion.Split("+")[0]
# We use Git commit count as the Build Number
$NewBuildNumber = (git rev-list --count HEAD).Trim()
$NewVersion = "$VersionName+$NewBuildNumber"

Write-Host "   Version: $VersionName" -ForegroundColor Green
Write-Host "   Build Number (Git): $NewBuildNumber" -ForegroundColor Green

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
    # Note: We no longer commit pubspec.yaml changes here as build number is dynamic.
    
    # Check if tag already exists to avoid failure
    $TagExists = git tag -l "v$NewVersion"
    if (-not $TagExists) {
        Write-Host "   Tagging v$NewVersion..."
        git tag -a "v$NewVersion" -m "Release $NewVersion ($Environment)"
        git push origin "v$NewVersion"
    }
    else {
        Write-Host "   Tag v$NewVersion already exists. Skipping tagging." -ForegroundColor Gray
    }
}
else {
    Write-Host "-> Step 5: Git Operations Skipped (-NoGit)." -ForegroundColor Gray
}

# 6. Deploy
Write-Host "-> Step 6: Deploying..." -ForegroundColor Yellow

# Web Deploy
if ($Platform -eq "web" -or $Platform -eq "all") {
    Write-Host "   Deploying Hosting and Firestore to $($EnvConfig.ProjectId)..."
    firebase deploy --only "hosting,firestore" --project $EnvConfig.ProjectId
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
