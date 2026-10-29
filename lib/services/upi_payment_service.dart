// lib/services/upi_payment_service.dart
import 'package:url_launcher/url_launcher.dart';

class UpiApp {
  final String id;
  final String name;
  final String scheme; // used to detect whether the app is installed
  final String Function(String query) buildLink;
  const UpiApp(this.id, this.name, this.scheme, this.buildLink);
}

/// Detects installed UPI apps (PhonePe, Google Pay, Paytm, BHIM / any UPI app)
/// and opens the one the user picks with the amount pre-filled.
class UpiPaymentService {
  static final List<UpiApp> _known = [
    UpiApp('phonepe', 'PhonePe', 'phonepe', (q) => 'phonepe://pay?$q'),
    UpiApp('gpay', 'Google Pay', 'tez', (q) => 'tez://upi/pay?$q'),
    UpiApp('paytm', 'Paytm', 'paytmmp', (q) => 'paytmmp://pay?$q'),
  ];

  /// Extracts the `pa=..&pn=..&am=..` part of a `upi://pay?...` link.
  static String? queryFrom(String? upiLink) {
    if (upiLink == null) return null;
    final i = upiLink.indexOf('?');
    if (i < 0 || i == upiLink.length - 1) return null;
    return upiLink.substring(i + 1);
  }

  /// Apps that are really installed on this phone.
  static Future<List<UpiApp>> installedApps() async {
    final found = <UpiApp>[];
    for (final app in _known) {
      try {
        if (await canLaunchUrl(Uri.parse('${app.scheme}://'))) found.add(app);
      } catch (_) {}
    }
    return found;
  }

  /// Opens a specific app. Returns false if it could not be opened.
  static Future<bool> open(UpiApp app, String query) async {
    try {
      return await launchUrl(Uri.parse(app.buildLink(query)),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens the system chooser listing every UPI app (BHIM, bank apps, etc.).
  static Future<bool> openAny(String query) async {
    try {
      return await launchUrl(Uri.parse('upi://pay?$query'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
