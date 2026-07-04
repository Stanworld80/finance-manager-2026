#!/usr/bin/env pwsh
# run_integration_tests.ps1
# Runs all Finance Manager 2026 integration & E2E tests against the staging environment
# Prerequisites: Chrome must be installed and in PATH, Flutter SDK configured
#
# Usage:
#   .\run_integration_tests.ps1                    # Run all tests
#   .\run_integration_tests.ps1 -Target auth       # Run only auth tests
#   .\run_integration_tests.ps1 -Target accounts   # Run only accounts tests

param(
    [string]$Target = "all",
    [string]$Device = "chrome"
)

$PROJECT_ROOT = $PSScriptRoot
$DRIVER = "$PROJECT_ROOT/test_driver/integration_test.dart"

$TEST_FILES = @{
    "auth"         = "integration_test/features/auth_flow_test.dart"
    "accounts"     = "integration_test/features/accounts_e2e_test.dart"
    "transactions" = "integration_test/features/transactions_full_e2e_test.dart"
    "resume"       = "integration_test/features/resume_e2e_test.dart"
    "navigation"   = "integration_test/features/navigation_e2e_test.dart"
    "projects"     = "integration_test/features/projects_e2e_test.dart"
    "import"       = "integration_test/features/import_e2e_test.dart"
    "help"         = "integration_test/features/help_preferences_e2e_test.dart"
    "recurring"    = "integration_test/features/recurring_flow_test.dart"
}

function Run-Test {
    param([string]$Name, [string]$File)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Running: $Name" -ForegroundColor Yellow
    Write-Host "  File:    $File" -ForegroundColor Gray
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    $cmd = "flutter drive --driver=$DRIVER --target=$File -d $Device --verbose"
    Write-Host "  CMD: $cmd" -ForegroundColor DarkGray
    Invoke-Expression $cmd
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host "  ✅ PASSED: $Name" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FAILED: $Name (exit code: $exitCode)" -ForegroundColor Red
    }
    return $exitCode
}

# Header
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  Finance Manager 2026 – Integration Test Suite  ║" -ForegroundColor Blue
Write-Host "║  Target: staging (dev environment)              ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Blue

Set-Location $PROJECT_ROOT

$failed = 0
$passed = 0
$startTime = Get-Date

if ($Target -eq "all") {
    foreach ($entry in $TEST_FILES.GetEnumerator() | Sort-Object Key) {
        $result = Run-Test -Name $entry.Key -File $entry.Value
        if ($result -eq 0) { $passed++ } else { $failed++ }
    }
} elseif ($TEST_FILES.ContainsKey($Target)) {
    $result = Run-Test -Name $Target -File $TEST_FILES[$Target]
    if ($result -eq 0) { $passed++ } else { $failed++ }
} else {
    Write-Host "Unknown target: $Target" -ForegroundColor Red
    Write-Host "Available targets: $($TEST_FILES.Keys -join ', '), all"
    exit 1
}

$elapsed = (Get-Date) - $startTime

# Summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                   SUMMARY                       ║" -ForegroundColor Blue
Write-Host "╟──────────────────────────────────────────────────╢" -ForegroundColor Blue
Write-Host "║  ✅ Passed: $passed  ❌ Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "║  ⏱  Duration: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Blue

exit $failed
