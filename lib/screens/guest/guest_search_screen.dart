import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../widgets/guest/pg_card.dart';
import '../../widgets/guest/pg_detail_modal.dart';
import '../../models/pg_model.dart';
import '../../widgets/common/snackbar_helper.dart';
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
  bool _isLoading = true;

  final ApiService _api = ApiService();

  List<PgModel> _allPgs = [];
  List<PgModel> _searchResults = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadPGs();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPGs({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getPublicPGs(search: search);
      if (response['success'] && response['data'] != null) {
        final data = response['data'] as List;
        _allPgs = data.map((pg) => PgModel.fromJson(pg)).toList();
        _searchResults = _allPgs;
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Failed to load PGs');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to load PGs');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openDrawer() {
    final state = context.findAncestorStateOfType<GuestScreenState>();
    state?.openDrawer();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadPGs(search: _searchQuery.isNotEmpty ? _searchQuery : null);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = _allPgs;
      } else {
        final q = query.toLowerCase();
        _searchResults = _allPgs.where((pg) {
          return pg.name.toLowerCase().contains(q) ||
              pg.location.toLowerCase().contains(q) ||
              pg.amenityNames.any((a) => a.toLowerCase().contains(q)) ||
              pg.rent.toString().contains(q);
        }).toList();
      }
    });
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen)),
              const SizedBox(height: 16),
              Text('Loading PGs...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

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
                            ? [kLivinkeyGreen.withOpacity(0.10), kLivinkeyGreen.withOpacity(0.03)]
                            : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isFocused ? kLivinkeyGreen.withOpacity(0.45) : Colors.white.withOpacity(0.08),
                        width: _isFocused ? 1.5 : 1,
                      ),
                      boxShadow: _isFocused
                          ? [BoxShadow(color: kLivinkeyGreen.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))]
                          : [],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search by name, location, rent, amenities...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13.5),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _isFocused ? kLivinkeyGreen : kLivinkeyGreen.withOpacity(0.6),
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
                                  _performSearch('');
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _performSearch(value);
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
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomNavHeight + bottomSafeArea + 16),
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
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting your search',
                                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12.5),
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
      child: const Icon(Icons.circle, color: Color(0xFFFF9800), size: 8),
    );
  }
}