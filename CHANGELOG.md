# Changelog

All notable changes to FinanceManager2026 will be documented in this file.

## [Unreleased]

### Added
- **AI**: Added "Coach Financier" conversational assistant (UI + Service)
- **UI**: Added FAB in AppShell to access AI Assistant
- **Infrastructure**: Added `build_web.ps1` to auto-increment build number on every build
- **UI**: Added version display (e.g., "v1.0.0 (42)") to the App Shell sidebar
- **Service**: Added `deleteRealAccount` to `AccountService` to clean up accounts, virtual accounts, and transactions
- **UX**: Added flexible number input handling (comma/dot support, space removal) to Transaction forms

### Fixed
- Fixed `account_models_test.dart` - Updated `toMap` test expectation to include all metadata fields (openingDate, accountNumber, officialName, iban, bic, swift) returned by `RealAccount.toMap()`
- Fixed account card balance visibility in dark mode - Changed `primaryColor` to `colorScheme.onSurface` for proper contrast
- Fixed `AiChatScreen` syntax errors and improved state management

### Refactored
- Applied `dart fix --apply` for 35 automatic linting fixes across 13 files
- Implemented `AiService` using Riverpod `AsyncNotifier` for better testability

### Documentation
- Added CHANGELOG.md for tracking project changes
