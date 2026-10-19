Livinkey app fixes

Changes:
1. Shared notification screen now accepts an isTenant flag. Guest home opens it with isTenant=false, so guest mark-read, mark-all-read, refresh, and delete operations use /guest-notifications instead of /tenant-notifications.
2. NotificationService now checks API success responses for mark-as-read and mark-all-read. API failures are surfaced to the UI rather than silently treated as success.
3. Login fields use platform autofill hints inside AutofillGroup. After successful authentication, Flutter finishes the autofill context with shouldSave=true so supported Android/iOS password managers can offer to save and later autofill credentials.

Notes:
- No credentials are stored by the app itself; saving is handled by the user's OS/password manager.
- Backend routes and DB schema did not require changes for these client-side issues.
- Flutter SDK was not available in this environment, so `flutter analyze`, `dart format`, and device builds could not be run. Please run these locally and test guest notifications against the deployed API.
