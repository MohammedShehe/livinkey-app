import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/tenant/stat_card.dart';
import '../../widgets/tenant/quick_action.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../common/notification_screen.dart';
import 'tenant_screen.dart';

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
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  final ApiService _api = ApiService();

  // Home data
  String _greeting = '';
  String _tenantName = '';
  String _email = '';
  String _pgName = '';
  String _roomNumber = '';
  String? _profilePicture;
  String _placeholderInitials = '';

  // Rent status
  String _rentStatus = 'unpaid';
  int _dueDays = 0;
  String? _nextPaymentDate;
  int _daysLeft = 0;
  String? _paidFrom;
  String? _paidTill;

  // Current bill
  Map<String, dynamic>? _currentBill;

  // Maintenance stats
  int _maintenanceTotal = 0;
  int _maintenancePending = 0;
  int _maintenanceInProgress = 0;
  int _maintenanceCompleted = 0;

  // ============================================================
  // Safe type conversion helpers
  // ============================================================
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0.0;
      return double.tryParse(trimmed) ?? 0.0;
    }
    if (value is bool) return value ? 1.0 : 0.0;
    return 0.0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadHomeData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _api.getTenantHome();
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Tenant data
        final tenant = data['tenant'] ?? {};
        _greeting = _safeToString(data['greeting']);
        _tenantName = _safeToString(tenant['full_name']);
        _email = _safeToString(tenant['email']);
        _pgName = _safeToString(tenant['pg_name']);
        _roomNumber = _safeToString(tenant['room_number']);
        _profilePicture = tenant['profile_picture'] != null ? _safeToString(tenant['profile_picture']) : null;
        _placeholderInitials = _safeToString(tenant['placeholder_initials']);

        // Rent status
        final rentStatus = data['rent_status'] ?? {};
        _rentStatus = _safeToString(rentStatus['status']);
        _dueDays = _safeToInt(rentStatus['due_days']);
        _nextPaymentDate = rentStatus['next_payment_date'] != null 
            ? _safeToString(rentStatus['next_payment_date']) 
            : null;
        _daysLeft = _safeToInt(rentStatus['days_left']);
        _paidFrom = rentStatus['paid_from'] != null 
            ? _safeToString(rentStatus['paid_from']) 
            : null;
        _paidTill = rentStatus['paid_till'] != null 
            ? _safeToString(rentStatus['paid_till']) 
            : null;

        // Current bill
        _currentBill = data['current_bill'] as Map<String, dynamic>?;
        if (_currentBill != null) {
          _currentBill!['total_amount'] = _safeToDouble(_currentBill!['total_amount']);
          _currentBill!['paid_amount'] = _safeToDouble(_currentBill!['paid_amount']);
          _currentBill!['fine_amount'] = _safeToDouble(_currentBill!['fine_amount']);
        }

        // Maintenance stats
        final maintenance = data['maintenance'] ?? {};
        _maintenanceTotal = _safeToInt(maintenance['total']);
        _maintenancePending = _safeToInt(maintenance['pending']);
        _maintenanceInProgress = _safeToInt(maintenance['in_progress']);
        _maintenanceCompleted = _safeToInt(maintenance['completed']);

        await NotificationService().refresh(isTenant: true);
        
        _hasLoadedOnce = true;
      } else {
        if (!_hasLoadedOnce && mounted) {
          final errorMsg = response['message'] ?? 'Failed to load dashboard data';
          SnackbarHelper.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (!_hasLoadedOnce && mounted) {
        SnackbarHelper.showError(context, 'Failed to load dashboard data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToTab(int index) {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    state?.navigateToTab(index);
  }

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
    
    try {
      final response = await _api.getTenantHome();
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        final tenant = data['tenant'] ?? {};
        _greeting = _safeToString(data['greeting']);
        _tenantName = _safeToString(tenant['full_name']);
        _email = _safeToString(tenant['email']);
        _pgName = _safeToString(tenant['pg_name']);
        _roomNumber = _safeToString(tenant['room_number']);
        _profilePicture = tenant['profile_picture'] != null 
            ? _safeToString(tenant['profile_picture']) 
            : null;
        _placeholderInitials = _safeToString(tenant['placeholder_initials']);

        final rentStatus = data['rent_status'] ?? {};
        _rentStatus = _safeToString(rentStatus['status']);
        _dueDays = _safeToInt(rentStatus['due_days']);
        _nextPaymentDate = rentStatus['next_payment_date'] != null 
            ? _safeToString(rentStatus['next_payment_date']) 
            : null;
        _daysLeft = _safeToInt(rentStatus['days_left']);
        _paidFrom = rentStatus['paid_from'] != null 
            ? _safeToString(rentStatus['paid_from']) 
            : null;
        _paidTill = rentStatus['paid_till'] != null 
            ? _safeToString(rentStatus['paid_till']) 
            : null;

        _currentBill = data['current_bill'] as Map<String, dynamic>?;
        if (_currentBill != null) {
          _currentBill!['total_amount'] = _safeToDouble(_currentBill!['total_amount']);
          _currentBill!['paid_amount'] = _safeToDouble(_currentBill!['paid_amount']);
          _currentBill!['fine_amount'] = _safeToDouble(_currentBill!['fine_amount']);
        }

        final maintenance = data['maintenance'] ?? {};
        _maintenanceTotal = _safeToInt(maintenance['total']);
        _maintenancePending = _safeToInt(maintenance['pending']);
        _maintenanceInProgress = _safeToInt(maintenance['in_progress']);
        _maintenanceCompleted = _safeToInt(maintenance['completed']);

        await NotificationService().refresh(isTenant: true);
        
        _hasLoadedOnce = true;
        
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Dashboard refreshed');
        }
      } else {
        if (mounted && !_hasLoadedOnce) {
          final errorMsg = response['message'] ?? 'Failed to load dashboard data';
          SnackbarHelper.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted && !_hasLoadedOnce) {
        SnackbarHelper.showError(context, 'Failed to load dashboard data');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  double _getLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 600) {
      return 160.0;
    } else if (screenWidth >= 400) {
      return 100.0;
    } else {
      return 80.0;
    }
  }

  String _formatRentStatus() {
    if (_rentStatus == 'paid') {
      return 'Paid ✓';
    } else if (_rentStatus == 'unpaid') {
      return 'Unpaid ⚠️';
    }
    return _rentStatus;
  }

  String _getRentStatusSubtitle() {
    if (_rentStatus == 'paid') {
      return 'Paid till ${_paidTill ?? 'N/A'}';
    } else {
      return 'Overdue by $_dueDays days';
    }
  }

  Color _getRentStatusColor() {
    return _rentStatus == 'paid' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double logoSize = _getLogoSize(context);
    final bool isWide = MediaQuery.of(context).size.width >= 600;

    final double bottomNavHeight = 76.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: kLivinkeyGreen, size: 7),
                const SizedBox(width: 6),
                const Text(
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

                    // Profile header with profile picture
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
                                  '$_greeting',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tenantName.isNotEmpty ? _tenantName : 'Tenant',
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
                                      _pgName,
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
                                      _roomNumber,
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
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: kLivinkeyGreen.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              image: _profilePicture != null && _profilePicture!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_profilePicture!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: _profilePicture == null || _profilePicture!.isEmpty
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [kLivinkeyGreen, Color(0xFF66BB6A)],
                                    )
                                  : null,
                            ),
                            child: (_profilePicture == null || _profilePicture!.isEmpty)
                                ? Center(
                                    child: Text(
                                      _placeholderInitials.isNotEmpty
                                          ? _placeholderInitials
                                          : getInitials(_tenantName),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : null,
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
                          value: _formatRentStatus(),
                          subtitle: _getRentStatusSubtitle(),
                          color: _getRentStatusColor(),
                          onTap: () => _navigateToTab(1),
                        ),
                        StatCard(
                          icon: Icons.calendar_today_rounded,
                          title: 'Next Payment',
                          value: _nextPaymentDate != null
                              ? DateFormat('dd MMM, yyyy').format(DateTime.parse(_nextPaymentDate!))
                              : 'N/A',
                          subtitle: _daysLeft > 0 ? '$_daysLeft days left' : 'Due soon',
                          color: _daysLeft > 3 ? Colors.orange : Colors.red,
                          onTap: () => _navigateToTab(1),
                        ),
                        StatCard(
                          icon: Icons.build_rounded,
                          title: 'Maintenance',
                          value: '$_maintenancePending Req',
                          subtitle: '$_maintenanceInProgress in progress',
                          color: Colors.blue,
                          onTap: () => _navigateToTab(2),
                        ),
                        StatCard(
                          icon: Icons.receipt_rounded,
                          title: 'Current Bill',
                          value: _currentBill != null
                              ? fmtINR(_currentBill!['total_amount'] ?? 0)
                              : 'No Bill',
                          subtitle: _currentBill?['status'] ?? 'N/A',
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
    );
  }
}

// Notification Bell Widget
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unreadCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _updateCount();
    _notificationService.notificationsStream.listen((_) {
      if (mounted) {
        _updateCount();
      }
    });
  }

  void _updateCount() {
    setState(() {
      _unreadCount = _notificationService.unreadCount;
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

// Helper function for INR formatting
String fmtINR(dynamic amount) {
  final num = amount is double ? amount : (amount ?? 0).toDouble();
  return '₹${NumberFormat('#,##,##0.00', 'en_IN').format(num)}';
}