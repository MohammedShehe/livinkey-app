# V2 update – Flutter app

- **Offers**: ribbon + offer line on PG cards, "Offers" section (with copyable coupon code) in the PG detail sheet.
- **Remember me**: login now keeps email + password in encrypted storage (Android Keystore / iOS Keychain), pre-fills them next time, per account type (tenant / guest). Updated automatically after change/reset password. "Forget" link removes it. OS password-manager save is kept too.
- **Documents**: each document shows In review / Approved / Rejected; tapping a rejected one shows the admin's reason and lets the tenant upload again.
- **Notifications**: tapping a push no longer sends guests to tenant screens; new types (document approved/rejected, offers) handled.
- Bill breakdown shows electricity units when the bill was made from meter readings.
- Guests now receive real push notifications (backend fix). Make sure the backend is deployed and `ENABLE_PUSH_NOTIFICATIONS=true`.

Run `flutter pub get` (no new packages were added).
