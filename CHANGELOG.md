# Changelog

All notable changes to FinanceManager2026 will be documented in this file.

## [Unreleased]

### Added
- **Infrastructure**: Added `build_web.ps1` to auto-increment build number on every build
- **UI**: Added version display (e.g., "v1.0.0 (42)") to the App Shell sidebar
- **Service**: Added `deleteRealAccount` to `AccountService` to clean up accounts, virtual accounts, and transactions

### Fixed
- Fixed `account_models_test.dart` - Updated `toMap` test expectation to include all metadata fields (openingDate, accountNumber, officialName, iban, bic, swift) returned by `RealAccount.toMap()`
- Fixed account card balance visibility in dark mode - Changed `primaryColor` to `colorScheme.onSurface` for proper contrast

### Refactored
- Applied `dart fix --apply` for 35 automatic linting fixes across 13 files

### Documentation
- Added CHANGELOG.md for tracking project changes
