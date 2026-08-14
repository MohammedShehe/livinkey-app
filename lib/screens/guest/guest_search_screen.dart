// lib/screens/guest/guest_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/guest/pg_card.dart';
import '../../widgets/guest/pg_detail_modal.dart';
import '../../models/pg_model.dart';
import 'guest_screen.dart';

class GuestSearchScreen extends StatefulWidget {
  const GuestSearchScreen({super.key});

  @override
  State<GuestSearchScreen> createState() => _GuestSearchScreenState();
}

class _GuestSearchScreenState extends State<GuestSearchScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isFocused = false;
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
      description: 'Green Valley PG offers comfortable living spaces with modern amenities.',
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
      description: 'Sunshine PG provides quality accommodation with delicious home-cooked meals.',
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
      amenities: ['Wi-Fi', 'AC', 'Parking', 'Security', 'Laundry', 'Gym', 'Swimming Pool'],
      comments: [
        UserComment('Arjun P.', 'Best PG in town! Highly recommended.'),
        UserComment('Neha G.', 'Amazing amenities and service.'),
        UserComment('Rohit K.', 'Great place for students.'),
      ],
      description: 'Royal PG offers premium accommodation with world-class amenities.',
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
      description: 'Cozy Nest PG provides affordable accommodation with all essential amenities.',
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
      amenities: ['Wi-Fi', 'AC', 'Parking', 'Security', 'Laundry', 'Gym', 'Swimming Pool', 'Restaurant'],
      comments: [
        UserComment('Ananya R.', 'Luxury living at affordable prices.'),
        UserComment('Karan S.', 'Excellent facilities and service.'),
        UserComment('Meera D.', 'Best PG in Phagwara!'),
      ],
      description: 'Elite PG offers luxury accommodation with premium amenities.',
    ),
  ];

  List<PgModel> get _searchResults {
    if (_searchQuery.isEmpty) return _allPgs;
    
    final query = _searchQuery.toLowerCase();
    return _allPgs.where((pg) {
      return pg.name.toLowerCase().contains(query) ||
          pg.location.toLowerCase().contains(query) ||
          pg.status.toLowerCase().contains(query) ||
          pg.rent.toString().contains(query) ||
          pg.amenities.any((a) => a.toLowerCase().contains(query)) ||
          pg.comments.any((c) => c.text.toLowerCase().contains(query));
    }).toList();
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
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final double bottomNavHeight = 76.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kLivinkeyBlack,
        surfaceTintColor: Colors.transparent,
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
        title: const Text(
          'Search PGs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
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
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isFocused
                            ? [
                                kLivinkeyGreen.withOpacity(0.10),
                                kLivinkeyGreen.withOpacity(0.03),
                              ]
                            : [
                                Colors.white.withOpacity(0.05),
                                Colors.white.withOpacity(0.02),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isFocused
                            ? kLivinkeyGreen.withOpacity(0.45)
                            : Colors.white.withOpacity(0.08),
                        width: _isFocused ? 1.5 : 1,
                      ),
                      boxShadow: _isFocused
                          ? [
                              BoxShadow(
                                color: kLivinkeyGreen.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name, location, rent, amenities...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _isFocused
                              ? kLivinkeyGreen
                              : kLivinkeyGreen.withOpacity(0.6),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 14,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                  HapticFeedback.selectionClick();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 13,
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_searchResults.length} PG${_searchResults.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      bottomNavHeight + bottomSafeArea + 16,
                    ),
                    child: _searchResults.isEmpty
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
                                    Icons.search_off_rounded,
                                    color: Colors.white.withOpacity(0.15),
                                    size: 56,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No PGs found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting your search',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.2),
                                    fontSize: 12.5,
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 14 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: PgCard(
                                  pg: _searchResults[index],
                                  onTap: () => _showPgDetail(_searchResults[index]),
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