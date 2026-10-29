// lib/widgets/tenant/upi_app_sheet.dart
import 'package:flutter/material.dart';
import '../../services/upi_payment_service.dart';
import '../../utils/constants.dart';

/// Bottom sheet that lets the tenant choose which UPI app to pay with.
/// Returns true if a payment app was opened.
class UpiAppSheet {
  static Future<bool> show(
    BuildContext context, {
    required String upiQuery,
    required String amountLabel,
  }) async {
    final installed = await UpiPaymentService.installedApps();
    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Future<void> pick(Future<bool> Function() open) async {
          final ok = await open();
          if (ctx.mounted) Navigator.of(ctx).pop(ok);
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Pay with',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Amount to pay: $amountLabel',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13.5)),
                  const SizedBox(height: 16),
                  for (final app in installed)
                    _tile(app.name, 'Open ${app.name} with the amount filled in',
                        Icons.account_balance_wallet_rounded, () => pick(() => UpiPaymentService.open(app, upiQuery))),
                  _tile(
                    installed.isEmpty ? 'Choose a UPI app' : 'Other UPI apps',
                    'BHIM, bank apps and any other UPI app on your phone',
                    Icons.apps_rounded,
                    () => pick(() => UpiPaymentService.openAny(upiQuery)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'After paying, come back to Livinkey. Your payment will be confirmed once the property team verifies it. You can also upload a screenshot as proof.',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result == true;
  }

  static Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kLivinkeyGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kLivinkeyGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
