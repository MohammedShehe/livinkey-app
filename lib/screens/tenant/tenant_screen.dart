import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import 'home_screen.dart';
import 'payments_screen.dart';
import 'maintenance_screen.dart';
import 'documents_screen.dart';
import 'profile_screen.dart';
import 'tenant_drawer.dart';
import '../common/notification_screen.dart';
import '../auth/login_screen.dart';
import '../guest/guest_screen.dart';
import '../../widgets/common/snackbar_helper.dart';

class TenantScreen extends StatefulWidget {
  const TenantScreen({super.key});

  @override
  TenantScreenState createState() => TenantScreenState();
}

class TenantScreenState extends State<TenantScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationService _notificationService = NotificationService();
  final ApiService _api = ApiService();
  int _unreadCount = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    PaymentsScreen(),
    MaintenanceScreen(),
    DocumentsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _notificationService.initialize(isTenant: true);
    _updateUnreadCount();

    // ============================================================
    // FIXED: Ensure push notifications are initialized when tenant screen loads
    // ============================================================
    _initializePushNotifications();

    _notificationService.notificationsStream.listen((_) {
      if (mounted) {
        _updateUnreadCount();
      }
    });
  }

  // ============================================================
  // FIXED: Initialize push notifications with retry
  // ============================================================
  Future<void> _initializePushNotifications() async {
    try {
      final pushService = PushNotificationService();
      await pushService.initialize();
      await pushService.retryPendingToken();
      print('✅ Push notifications initialized on tenant screen');
    } catch (e) {
      print('⚠️ Push notification init on tenant screen: $e');
      // Don't block UI if push fails
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = _notificationService.unreadCount;
    });
  }

  int get selectedIndex => _selectedIndex;

  void navigateToTab(int index) {
    if (_selectedIndex != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
    HapticFeedback.lightImpact();
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  IconData _getIcon(int index) {
    const icons = [
      Icons.home_rounded,
      Icons.payment_rounded,
      Icons.build_rounded,
      Icons.folder_rounded,
      Icons.person_rounded,
    ];
    return icons[index];
  }

  String _getLabel(int index) {
    const labels = ['Home', 'Payments', 'Maintenance', 'Documents', 'Profile'];
    return labels[index];
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kLivinkeyBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // ============================================================
            // FIXED: Simple navigation to Guest screen - NO token switching
            // The tenant stays logged in as tenant, just views guest UI
            // ============================================================
            _buildQuickActionItem(
              icon: Icons.switch_account_rounded,
              color: const Color(0xFFFF9800),
              label: 'Enter as Guest',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GuestScreen()),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.logout_rounded,
              color: Colors.red,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
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
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FIXED: Logout with push token cleanup
  // ============================================================
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
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
            const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // NEW: Remove FCM token before logout
              final pushService = PushNotificationService();
              await pushService.removeToken();
              
              await _api.clearToken();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              SnackbarHelper.showSuccess(context, 'Logged out successfully');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback? onLongPress,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: label == 'Profile' ? onLongPress : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$isSelected'),
                  color: isSelected ? kLivinkeyGreen : Colors.white.withOpacity(0.38),
                  size: isSelected ? 26 : 22,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isSelected ? kLivinkeyGreen : Colors.white.withOpacity(0.38),
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            title: const Text(
              'Exit App?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kLivinkeyGreen, Color(0xFF7CB342)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kLivinkeyBlack,
        drawer: const TenantDrawer(),
        extendBody: true,
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kLivinkeyGreen.withOpacity(0.16),
                      kLivinkeyGreen.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kLivinkeyGreen.withOpacity(0.10),
                      kLivinkeyGreen.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                if (index == 4) {
                  _updateUnreadCount();
                }
              },
              children: _screens,
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 30,
                      offset: const Offset(0, -6),
                    ),
                    BoxShadow(
                      color: kLivinkeyGreen.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_screens.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return _buildFloatingTab(
                      icon: _getIcon(index),
                      label: _getLabel(index),
                      isSelected: isSelected,
                      onTap: () => navigateToTab(index),
                      onLongPress: index == 4 ? _showQuickActions : null,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}