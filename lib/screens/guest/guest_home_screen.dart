// lib/screens/guest/guest_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/guest/pg_card.dart';
import '../../widgets/guest/pg_detail_modal.dart';
import '../../models/pg_model.dart';
import 'guest_screen.dart';
import '../../services/notification_service.dart';
import '../common/notification_screen.dart';
import '../../widgets/common/snackbar_helper.dart';

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
  final String guestName = 'Guest User';
  bool _isRefreshing = false;

  final List<PgModel> _allPgs = [
    PgModel(
      id: '1',
      name: 'Green Valley PG',
      location: 'Near LPU, Phagwara',
      rating: 4.8,
      totalRooms: 20,
      availableRooms: 5,
      rent: 8500,
      status: 'Vacant',
      imageUrl: 'assets/images/pg1.jpg',
      amenities: ['Wi-Fi', 'AC', 'Parking', 'Security', 'Laundry', 'Gym'],
      comments: [
        UserComment('Rahul K.', 'Great place! Very clean and affordable.'),
        UserComment('Priya S.', 'Good food and friendly staff.'),
        UserComment('Amit R.', 'Nice location, close to university.'),
      ],
      description:
          'Green Valley PG offers comfortable living spaces with modern amenities. Located near LPU, it\'s perfect for students and professionals.',
    ),
    PgModel(
      id: '2',
      name: 'Sunshine PG',
      location: 'Near Lovely Professional University',
      rating: 4.6,
      totalRooms: 15,
      availableRooms: 0,
      rent: 7500,
      status: 'Full Occupied',
      imageUrl: 'assets/images/pg2.jpg',
      amenities: ['Wi-Fi', 'AC', 'Parking', 'Security', 'Food'],
      comments: [
        UserComment('Sneha M.', 'Good food and comfortable rooms.'),
        UserComment('Vikram S.', 'Affordable rent, nice place.'),
      ],
      description:
          'Sunshine PG provides quality accommodation with delicious home-cooked meals.',
    ),
    PgModel(
      id: '3',
      name: 'Royal PG',
      location: 'Phagwara, Punjab',
      rating: 4.9,
      totalRooms: 25,
      availableRooms: 8,
      rent: 9500,
      status: 'Vacant',
      imageUrl: 'assets/images/pg3.jpg',
      amenities: [
        'Wi-Fi',
        'AC',
        'Parking',
        'Security',
        'Laundry',
        'Gym',
        'Swimming Pool'
      ],
      comments: [
        UserComment('Arjun P.', 'Best PG in town! Highly recommended.'),
        UserComment('Neha G.', 'Amazing amenities and service.'),
        UserComment('Rohit K.', 'Great place for students.'),
      ],
      description:
          'Royal PG offers premium accommodation with world-class amenities including a swimming pool.',
    ),
    PgModel(
      id: '4',
      name: 'Cozy Nest PG',
      location: 'Near LPU Gate 1',
      rating: 4.3,
      totalRooms: 12,
      availableRooms: 2,
      rent: 6800,
      status: 'Vacant',
      imageUrl: 'assets/images/pg4.jpg',
      amenities: ['Wi-Fi', 'Parking', 'Security', 'Food'],
      comments: [
        UserComment('Deepak K.', 'Budget-friendly PG with good facilities.'),
      ],
      description:
          'Cozy Nest PG provides affordable accommodation with all essential amenities.',
    ),
    PgModel(
      id: '5',
      name: 'Elite PG',
      location: 'Phagwara City Center',
      rating: 4.7,
      totalRooms: 30,
      availableRooms: 0,
      rent: 10000,
      status: 'Full Occupied',
      imageUrl: 'assets/images/pg5.jpg',
      amenities: [
        'Wi-Fi',
        'AC',
        'Parking',
        'Security',
        'Laundry',
        'Gym',
        'Swimming Pool',
        'Restaurant'
      ],
      comments: [
        UserComment('Ananya R.', 'Luxury living at affordable prices.'),
        UserComment('Karan S.', 'Excellent facilities and service.'),
        UserComment('Meera D.', 'Best PG in Phagwara!'),
      ],
      description: 'Elite PG offers luxury accommodation with premium amenities.',
    ),
  ];

  List<PgModel> get _filteredPgs {
    List<PgModel> filtered = List.from(_allPgs);

    filtered.sort((a, b) {
      if (a.status == 'Vacant' && b.status != 'Vacant') return -1;
      if (a.status != 'Vacant' && b.status == 'Vacant') return 1;
      return 0;
    });

    if (_selectedFilter == 'Vacant') {
      filtered = filtered.where((pg) => pg.status == 'Vacant').toList();
    } else if (_selectedFilter == 'Full Occupied') {
      filtered = filtered.where((pg) => pg.status == 'Full Occupied').toList();
    }

    return filtered;
  }

  int get _vacantCount => _allPgs.where((pg) => pg.status == 'Vacant').length;

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

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Refreshed successfully!');
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
    if (screenWidth >= 600) {
      return 120.0;
    } else if (screenWidth >= 400) {
      return 64.0;
    } else {
      return 50.0;
    }
  }

  // Helper method to open drawer using the parent state
  void _openDrawer() {
    final state = context.findAncestorStateOfType<GuestScreenState>();
    if (state != null) {
      state.openDrawer();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double logoSize = _getLogoSize(context);
    final double bottomNavHeight = 76.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

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
        title: Image.asset(
          kGeneralLogo,
          height: logoSize,
          width: logoSize,
        ),
        centerTitle: false,
        actions: [
          // Notification Bell Icon - Now visible in Guest
          const _NotificationBell(),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withOpacity(0.22),
                  const Color(0xFFFF9800).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(),
                  SizedBox(width: 6),
                  Text(
                    'Guest',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
                            'Good ${getTimeOfDay()}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
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
                            guestName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
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
                      colors: [
                        kLivinkeyGreen.withOpacity(0.14),
                        kLivinkeyGreen.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: kLivinkeyGreen.withOpacity(0.18),
                      width: 1,
                    ),
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
                          gradient: LinearGradient(
                            colors: [kLivinkeyGreen, const Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kLivinkeyGreen.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find your perfect home',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_vacantCount PGs available right now',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                    // FIXED: Reduced bottom padding to give more content area
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      bottomNavHeight + bottomSafeArea + 8, // Reduced from 16 to 8
                    ),
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
                                  'No PGs available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try a different filter',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.2),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(bottom: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [kLivinkeyGreen, Color(0xFF66BB6A)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? kLivinkeyGreen
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kLivinkeyGreen.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.65),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
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
      child: const Icon(Icons.circle, color: Color(0xFFFF9800), size: 8),
    );
  }
}

// Notification Bell Widget - Also used in Tenant
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