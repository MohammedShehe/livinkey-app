import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/guest/pg_card.dart';
import '../../widgets/guest/pg_detail_modal.dart';
import '../../models/pg_model.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../common/notification_screen.dart';
import 'guest_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedFilter = 'All';
  String _guestName = 'Guest User';
  String _greeting = 'Good Morning';
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isTenantViewingAsGuest = false;

  final ApiService _api = ApiService();

  List<PgModel> _allPgs = [];
  List<PgModel> _filteredPgs = [];
  int _totalPGs = 0;
  int _vacantCount = 0;

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
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      try {
        final dashRes = await _api.getGuestDashboard();
        
        if (dashRes['success'] == true) {
          final data = dashRes['data'];
          if (data != null && data is Map<String, dynamic>) {
            _guestName = data['name']?.toString() ?? 
                        data['full_name']?.toString() ?? 
                        'Guest User';
            _greeting = data['greeting']?.toString() ?? getTimeOfDay();
            _totalPGs = data['total_pgs'] ?? 0;
            _isTenantViewingAsGuest = data['is_tenant_viewing_as_guest'] ?? false;
            
          }
        }
      } catch (dashError) {
        _guestName = 'Guest User';
        _greeting = getTimeOfDay();
        _totalPGs = 0;
        _isTenantViewingAsGuest = false;
      }

      try {
        final pgsRes = await _api.getPublicPGs();
        
        if (pgsRes['success'] == true && pgsRes['data'] != null) {
          final data = pgsRes['data'];
          if (data is List) {
            _allPgs = data.map((pg) => PgModel.fromJson(pg)).toList();
            _vacantCount = pgsRes['vacant_count'] ?? 
                           _allPgs.where((pg) => pg.statusText == 'Vacant').length;
            
            if (_totalPGs == 0) {
              _totalPGs = _allPgs.length;
            }
            
            _applyFilter();
          } else {
            if (data is Map<String, dynamic> && data['data'] is List) {
              final innerData = data['data'] as List;
              _allPgs = innerData.map((pg) => PgModel.fromJson(pg)).toList();
              _vacantCount = _allPgs.where((pg) => pg.statusText == 'Vacant').length;
              if (_totalPGs == 0) {
                _totalPGs = _allPgs.length;
              }
              _applyFilter();
            } else {
              _allPgs = [];
              _filteredPgs = [];
              _vacantCount = 0;
              _totalPGs = 0;
            }
          }
        } else {
          _allPgs = [];
          _filteredPgs = [];
          _vacantCount = 0;
          _totalPGs = 0;
        }
      } catch (pgsError) {
        _allPgs = [];
        _filteredPgs = [];
        _vacantCount = 0;
        _totalPGs = 0;
      }

      try {
        await NotificationService().refresh(isTenant: _isTenantViewingAsGuest);
      } catch (notifError) {
      }
      
      if (_allPgs.isEmpty && _totalPGs == 0) {
        SnackbarHelper.showWarning(context, 'No PGs available at the moment. Please try again later.');
      }
      
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredPgs = List.from(_allPgs);
      } else {
        _filteredPgs = _allPgs.where((pg) => pg.statusText == _selectedFilter).toList();
      }
    });
  }

  void _openDrawer() {
    final state = context.findAncestorStateOfType<GuestScreenState>();
    state?.openDrawer();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      if (_allPgs.isNotEmpty) {
        SnackbarHelper.showSuccess(context, 'Refreshed successfully!');
      }
    }
  }

  void _showPgDetail(PgModel pg) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PgDetailModal(pg: pg),
    );
  }

  double _getLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 600) return 120.0;
    if (screenWidth >= 400) return 64.0;
    return 50.0;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double logoSize = _getLogoSize(context);
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
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
        elevation: 0,
        backgroundColor: kLivinkeyBlack,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _openDrawer,
        ),
        title: Image.asset(kGeneralLogo, height: logoSize, width: logoSize),
        centerTitle: false,
        actions: [
          const _NotificationBell(),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isTenantViewingAsGuest 
                      ? kLivinkeyGreen.withOpacity(0.22)
                      : const Color(0xFFFF9800).withOpacity(0.22),
                  _isTenantViewingAsGuest 
                      ? kLivinkeyGreen.withOpacity(0.06)
                      : const Color(0xFFFF9800).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isTenantViewingAsGuest 
                    ? kLivinkeyGreen.withOpacity(0.25)
                    : const Color(0xFFFF9800).withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isTenantViewingAsGuest 
                      ? kLivinkeyGreen.withOpacity(0.12)
                      : const Color(0xFFFF9800).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(isTenantViewingAsGuest: _isTenantViewingAsGuest),
                  const SizedBox(width: 6),
                  Text(
                    _isTenantViewingAsGuest ? 'Tenant (Guest)' : 'Guest',
                    style: TextStyle(
                      color: _isTenantViewingAsGuest 
                          ? kLivinkeyGreen
                          : const Color(0xFFFF9800),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: kLivinkeyGreen,
        backgroundColor: kLivinkeyBlack,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: kLivinkeyGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _greeting,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.85)],
                          ).createShader(bounds),
                          child: Text(
                            _guestName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      if (_isTenantViewingAsGuest)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: kLivinkeyGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kLivinkeyGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: kLivinkeyGreen.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Viewing as Guest',
                                style: TextStyle(
                                  color: kLivinkeyGreen.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kLivinkeyGreen.withOpacity(0.14), kLivinkeyGreen.withOpacity(0.02)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kLivinkeyGreen.withOpacity(0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: kLivinkeyGreen.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kLivinkeyGreen, Color(0xFF66BB6A)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kLivinkeyGreen.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTenantViewingAsGuest 
                                  ? 'Browse PGs as Guest'
                                  : 'Find your perfect home',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _totalPGs > 0 
                                  ? '$_totalPGs PGs available right now'
                                  : 'No PGs available at the moment',
                              style: TextStyle(
                                color: _totalPGs > 0 
                                    ? Colors.white.withOpacity(0.55) 
                                    : Colors.orange.withOpacity(0.7),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_vacantCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kLivinkeyGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kLivinkeyGreen.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$_vacantCount Vacant',
                            style: TextStyle(
                              color: kLivinkeyGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.grid_view_rounded),
                        const SizedBox(width: 10),
                        _buildFilterChip('Vacant', Icons.check_circle_outline_rounded),
                        const SizedBox(width: 10),
                        _buildFilterChip('Full Occupied', Icons.block_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomNavHeight + bottomSafeArea + 8),
                    child: _filteredPgs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.home_work_rounded,
                                    color: Colors.white.withOpacity(0.15),
                                    size: 56,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allPgs.isEmpty ? 'No PGs available' : 'No matching PGs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _allPgs.isEmpty 
                                      ? 'Check back later for new listings' 
                                      : 'Try a different filter',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.2),
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _handleRefresh,
                                  child: Text(
                                    'Refresh',
                                    style: TextStyle(
                                      color: kLivinkeyGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.only(bottom: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _filteredPgs.length,
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 350 + (index * 60)),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 16 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: PgCard(
                                  pg: _filteredPgs[index],
                                  onTap: () => _showPgDetail(_filteredPgs[index]),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilter();
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [kLivinkeyGreen, Color(0xFF66BB6A)])
              : LinearGradient(colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? kLivinkeyGreen : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kLivinkeyGreen.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.black : Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.65),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FIXED: _PulsingDot receives isTenantViewingAsGuest as parameter
// ============================================================
class _PulsingDot extends StatefulWidget {
  final bool isTenantViewingAsGuest;
  
  const _PulsingDot({
    required this.isTenantViewingAsGuest,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(
        Icons.circle, 
        color: widget.isTenantViewingAsGuest ? kLivinkeyGreen : const Color(0xFFFF9800), 
        size: 8
      ),
    );
  }
}

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
    NotificationService().notificationsStream.listen((_) {
      if (mounted) _updateCount();
    });
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
          icon: Icon(Icons.notifications_none_rounded, color: Colors.white.withOpacity(0.8), size: 26),
          onPressed: () {
            hapticFeedback();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            ).then((_) => _updateCount());
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}