// lib/screens/tenant/home_screen.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/tenant/stat_card.dart';
import '../../widgets/tenant/quick_action.dart';
import '../../widgets/common/snackbar_helper.dart';
import 'tenant_screen.dart';
import '../../services/notification_service.dart';
import '../common/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: kFadeDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    state?.navigateToTab(index);
  }

  // Helper method to open drawer using the parent state
  void _openDrawer() {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    if (state != null) {
      state.openDrawer();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Dashboard refreshed');
    }
  }

  double _getLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 600) {
      return 120.0;
    } else if (screenWidth >= 400) {
      return 64.0;
    } else {
      return 50.0;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
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
                color: Colors.white.withOpacity(0.65),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kLivinkeyGreen, Color(0xFF7CB342)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kLivinkeyGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const tenantName = 'John Doe';
    const pgName = 'Green Valley PG';
    const roomNumber = 'Room 204';

    final double logoSize = _getLogoSize(context);
    final bool isWide = MediaQuery.of(context).size.width >= 600;
    
    final double bottomNavHeight = 76.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kLivinkeyBlack,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: kLivinkeyBlack,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 80,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
            onPressed: _openDrawer,
          ),
          title: Image.asset(
            kGeneralLogo,
            height: logoSize,
            width: logoSize,
          ),
          actions: [
            // ADDED: Notification Bell Icon for Tenant
            const _NotificationBell(),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kLivinkeyGreen.withOpacity(0.22),
                    kLivinkeyGreen.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kLivinkeyGreen.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: kLivinkeyGreen, size: 7),
                  SizedBox(width: 6),
                  Text(
                    'Tenant',
                    style: TextStyle(
                      color: kLivinkeyGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: kLivinkeyGreen,
          backgroundColor: kLivinkeyBlack,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kLivinkeyGreen.withOpacity(0.05),
                  kLivinkeyBlack,
                  kLivinkeyBlack,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    32 + bottomNavHeight + bottomSafeArea + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.035),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${getTimeOfDay()}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tenantName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.home_rounded,
                                        color: kLivinkeyGreen.withOpacity(0.8),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        pgName,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Icon(
                                        Icons.meeting_room_rounded,
                                        color: kLivinkeyGreen.withOpacity(0.8),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        roomNumber,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [kLivinkeyGreen, Color(0xFF66BB6A)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: kLivinkeyGreen.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  getInitials(tenantName),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: kLivinkeyGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.15 : 1.02,
                        children: [
                          StatCard(
                            icon: Icons.warning_rounded,
                            title: 'Rent Status',
                            value: 'Unpaid',
                            subtitle: 'Due in 3 days',
                            color: Colors.red,
                            onTap: () => _navigateToTab(1),
                          ),
                          StatCard(
                            icon: Icons.calendar_today_rounded,
                            title: 'Upcoming Payment',
                            value: '14 Aug, 2026',
                            subtitle: '3 days left',
                            color: Colors.orange,
                            onTap: () => _navigateToTab(1),
                          ),
                          StatCard(
                            icon: Icons.build_rounded,
                            title: 'Maintenance',
                            value: '5 Req',
                            subtitle: '2 in progress',
                            color: Colors.blue,
                            onTap: () => _navigateToTab(2),
                          ),
                          StatCard(
                            icon: Icons.receipt_rounded,
                            title: 'Bills',
                            value: '₹12,500',
                            subtitle: 'This month',
                            color: kLivinkeyGreen,
                            onTap: () => _navigateToTab(1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: kLivinkeyGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: QuickAction(
                              icon: Icons.payment_rounded,
                              label: 'Pay Rent',
                              color: kLivinkeyGreen,
                              onTap: () => _navigateToTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickAction(
                              icon: Icons.build_rounded,
                              label: 'Request Maintenance',
                              color: Colors.blue,
                              onTap: () => _navigateToTab(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickAction(
                              icon: Icons.folder_rounded,
                              label: 'View Documents',
                              color: Colors.orange,
                              onTap: () => _navigateToTab(3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Notification Bell Widget for Tenant
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCount();
  }

  void _updateCount() {
    setState(() {
      _unreadCount = NotificationService().unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white.withOpacity(0.8),
            size: 26,
          ),
          onPressed: () {
            hapticFeedback();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ).then((_) => _updateCount());
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}