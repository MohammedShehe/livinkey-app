import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:livinkey/screens/tenant/tenant_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../auth/login_screen.dart';
import '../guest/guest_screen.dart';

class TenantDrawer extends StatelessWidget {
  const TenantDrawer({super.key});

  double _getLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minDimension = screenWidth < screenHeight ? screenWidth : screenHeight;

    if (screenWidth >= 600) {
      return minDimension * 0.25;
    } else if (screenWidth >= 400) {
      return minDimension * 0.20;
    } else {
      return minDimension * 0.18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = _getLogoSize(context);

    return Drawer(
      backgroundColor: kLivinkeyBlack,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(logoSize),
            Expanded(
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment_rounded,
                    title: 'Payments',
                    onTap: () {
                      Navigator.pop(context);
                      final state = context.findAncestorStateOfType<TenantScreenState>();
                      state?.navigateToTab(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.build_rounded,
                    title: 'Maintenance',
                    onTap: () {
                      Navigator.pop(context);
                      final state = context.findAncestorStateOfType<TenantScreenState>();
                      state?.navigateToTab(2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.folder_rounded,
                    title: 'Documents',
                    onTap: () {
                      Navigator.pop(context);
                      final state = context.findAncestorStateOfType<TenantScreenState>();
                      state?.navigateToTab(3);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      final state = context.findAncestorStateOfType<TenantScreenState>();
                      state?.navigateToTab(4);
                    },
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  // ============================================================
                  // FIXED: Simple navigation to Guest screen - NO token switching
                  // The tenant stays logged in as tenant, just views guest UI
                  // ============================================================
                  _buildDrawerItem(
                    icon: Icons.switch_account_rounded,
                    title: 'Enter as Guest',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GuestScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    onTap: () => SnackbarHelper.show(context, 'Terms of Service'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    onTap: () => SnackbarHelper.show(context, 'Privacy Policy'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    onTap: () => _showSupportOptions(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: Colors.red,
                    onTap: () => _handleLogout(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: const Text(
                      'A COMPLETE HOME',
                      style: TextStyle(color: kLivinkeyGreen, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double logoSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kLivinkeyGreen.withOpacity(0.15), Colors.transparent],
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Center(
        child: Image.asset(kGeneralLogo, height: logoSize, width: logoSize),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? Colors.white.withOpacity(0.6);
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white.withOpacity(0.8),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
      onTap: onTap,
      hoverColor: kLivinkeyGreen.withOpacity(0.05),
      splashColor: kLivinkeyGreen.withOpacity(0.1),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kLivinkeyBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildSupportOption(
              icon: FontAwesomeIcons.whatsapp,
              color: const Color(0xFF25D366),
              title: 'WhatsApp',
              subtitle: '+91 98783 83497',
              onTap: () => _launchUrl(context, kWhatsAppUrl),
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              icon: FontAwesomeIcons.instagram,
              color: const Color(0xFFE4405F),
              title: 'Instagram',
              subtitle: '@livinkey',
              onTap: () => _launchUrl(context, kInstagramUrl),
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              icon: Icons.email_rounded,
              color: Colors.blue,
              title: 'Email',
              subtitle: 'livinkey@gmail.com',
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Unable to open link');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    const String email = 'livinkey@gmail.com';
    final List<Uri> attempts = [
      Uri(scheme: 'mailto', path: email, query: 'subject=Support%20Inquiry'),
      Uri(scheme: 'mailto', path: email),
    ];

    for (final uri in attempts) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }

    await Clipboard.setData(const ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No email app found. Copied $email to clipboard.'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              SnackbarHelper.showSuccess(context, 'Logged out successfully');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}