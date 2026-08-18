import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/tenant/profile_row.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../auth/login_screen.dart';
import '../guest/guest_screen.dart';
import '../common/notification_screen.dart';
import 'tenant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _hasSubmittedFeedback = false;

  final ApiService _api = ApiService();

  Map<String, dynamic> _profileData = {};
  String _tenantName = '';
  String _tenantEmail = '';
  String _pgName = '';
  String _roomNumber = '';
  String _nationality = '';
  String _gender = '';
  double _rent = 0;
  double _securityFee = 0;
  int _paymentDate = 1;
  String _arrivalDate = '';
  String _paidTill = '';
  String? _profilePicture;
  String _residency = '';

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
      _loadProfile();
      _checkFeedbackStatus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAFE PARSING HELPERS
  // ============================================================
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0.0;
      return double.tryParse(trimmed) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    if (value is num) return value.toInt();
    return 0;
  }

  String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // ============================================================
  // FIXED: Format date - correctly handles ISO datetime with timezone
  // ============================================================
  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      
      DateTime date;
      
      if (dateStr.contains('T')) {
        // ISO datetime: parse and convert to local timezone
        date = DateTime.parse(dateStr).toLocal();
      } else {
        // YYYY-MM-DD format: parse directly
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          date = DateTime.utc(year, month, day);
        } else {
          date = DateTime.parse(dateStr);
        }
      }
      
      return '${date.day} ${_monthName(date.month)}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatPaymentDate(int day) {
    if (day <= 0 || day > 31) return '1st';
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _api.getTenantProfile();
      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        _profileData = data;
        
        _tenantName = _parseString(data['full_name']);
        _tenantEmail = _parseString(data['email']);
        _pgName = _parseString(data['pg_name']);
        _roomNumber = _parseString(data['room_number']);
        _nationality = _parseString(data['nationality']);
        _gender = _parseString(data['gender']);
        _residency = _parseString(data['residency']);
        _profilePicture = data['profile_picture'];

        // Parse numeric values from tenant_details
        _rent = _parseDouble(data['rent']);
        _securityFee = _parseDouble(data['security_fee']);
        _paymentDate = _parseInt(data['payment_date']);
        _arrivalDate = _parseString(data['arrival_date']);
        _paidTill = _parseString(data['paid_till']);
        
        print('Profile loaded: rent=$_rent, security_fee=$_securityFee, payment_date=$_paymentDate');
        print('Arrival date raw: $_arrivalDate');
      }
      if (mounted) {
        await NotificationService().refresh(isTenant: true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkFeedbackStatus() async {
    try {
      final response = await _api.checkFeedbackStatus();
      if (response['success']) {
        _hasSubmittedFeedback = response['has_submitted'] ?? false;
        setState(() {});
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _openDrawer() {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    state?.openDrawer();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await _loadProfile();
    await _checkFeedbackStatus();
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Profile refreshed');
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            title: const Text('Exit App?', style: TextStyle(color: Colors.white)),
            content: Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kLivinkeyGreen, Color(0xFF7CB342)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Text('Exit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _getInitials() {
    if (_tenantName.isEmpty) return '';
    final parts = _tenantName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
              Text('Loading profile...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kLivinkeyBlack,
        appBar: AppBar(
          backgroundColor: kLivinkeyBlack,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
            onPressed: _openDrawer,
          ),
          title: const Text('Profile', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
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
                colors: [kLivinkeyGreen.withOpacity(0.05), kLivinkeyBlack, kLivinkeyBlack],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + bottomNavHeight + bottomSafeArea + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      _buildProfileHeader(),
                      const SizedBox(height: 26),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white.withOpacity(0.035), Colors.white.withOpacity(0.015)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Column(
                          children: [
                            ProfileRow(label: 'Name', value: _tenantName),
                            ProfileRow(label: 'Email', value: _tenantEmail),
                            ProfileRow(label: 'PG', value: _pgName),
                            ProfileRow(label: 'Room No', value: _roomNumber),
                            ProfileRow(
                              label: 'Rent', 
                              value: '₹${_rent.toStringAsFixed(2)}/month'
                            ),
                            ProfileRow(
                              label: 'Security Fee', 
                              value: '₹${_securityFee.toStringAsFixed(2)}'
                            ),
                            ProfileRow(label: 'Nationality', value: _nationality),
                            ProfileRow(label: 'Gender', value: _gender.isNotEmpty ? _gender : 'Not specified'),
                            ProfileRow(
                              label: 'Payment Date', 
                              value: '${_formatPaymentDate(_paymentDate)} of every month'
                            ),
                            if (_arrivalDate.isNotEmpty)
                              ProfileRow(label: 'Arrival Date', value: _formatDate(_arrivalDate)),
                            if (_paidTill.isNotEmpty)
                              ProfileRow(label: 'Paid Till', value: _formatDate(_paidTill)),
                            if (_residency.isNotEmpty)
                              ProfileRow(label: 'Residency', value: _residency),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            hapticFeedback();
                            try {
                              final success = await _api.switchToRole('guest');
                              if (success) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const GuestScreen()),
                                );
                                SnackbarHelper.showInfo(context, 'Switched to Guest mode');
                              } else {
                                SnackbarHelper.showError(context, 'Failed to switch to guest');
                              }
                            } catch (e) {
                              SnackbarHelper.showError(context, 'Error switching to guest');
                            }
                          },
                          icon: Icon(Icons.switch_account_rounded, color: kLivinkeyGreen, size: 20),
                          label: Text(
                            'Enter as Guest',
                            style: TextStyle(color: kLivinkeyGreen, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            backgroundColor: kLivinkeyGreen.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: kLivinkeyGreen.withOpacity(0.15)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      _buildSectionHeader('Quick Links'),
                      const SizedBox(height: 12),

                      _buildLinkItem('Terms of Service', Icons.description_rounded),
                      _buildLinkItem('Privacy Policy', Icons.privacy_tip_rounded),

                      const SizedBox(height: 22),

                      _buildFeedbackButton(),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.withOpacity(0.6), width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kLivinkeyGreen.withOpacity(0.12), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLivinkeyGreen.withOpacity(0.16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kLivinkeyGreen, Color(0xFF66BB6A)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kLivinkeyGreen.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenantName,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_pgName • $_roomNumber',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                  decoration: BoxDecoration(
                    color: kLivinkeyGreen.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kLivinkeyGreen.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Tenant',
                    style: TextStyle(color: kLivinkeyGreen, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.035), Colors.white.withOpacity(0.015)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLivinkeyGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kLivinkeyGreen.withOpacity(0.85), size: 20),
        ),
        title: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14.5)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.25), size: 20),
        onTap: () {
          hapticFeedback();
          SnackbarHelper.showInfo(context, title);
        },
      ),
    );
  }

  Widget _buildFeedbackButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _hasSubmittedFeedback ? _showThankYouDialog : _showFeedbackModal,
        icon: Icon(
          _hasSubmittedFeedback ? Icons.thumb_up_rounded : Icons.feedback_rounded,
          color: Colors.black,
          size: 22,
        ),
        label: Text(
          _hasSubmittedFeedback ? 'Feedback Submitted ✓' : 'Give Feedback',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasSubmittedFeedback ? Colors.grey[600] : kLivinkeyGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kLivinkeyGreen.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.thumb_up_rounded, color: kLivinkeyGreen, size: 56),
              ),
              const SizedBox(height: 22),
              const Text('Thank You!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'We appreciate your valuable feedback! Your input helps us improve the Livinkey experience for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackModal() {
    final List<Map<String, dynamic>> categories = [
      {'label': 'Living Experience', 'value': 6.0},
      {'label': 'Maintenance Handling', 'value': 4.0},
      {'label': 'Communication', 'value': 7.0},
      {'label': 'Amenities', 'value': 7.0},
      {'label': 'Technology Handling', 'value': 7.0},
    ];

    final TextEditingController commentController = TextEditingController();
    final List<double> ratings = List.generate(5, (index) => categories[index]['value'].toDouble());
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rate Your Experience',
                        style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Help us improve by rating each category (0-10)',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          ...List.generate(categories.length, (index) {
                            return _buildRatingItem(
                              label: categories[index]['label'],
                              value: ratings[index],
                              onChanged: (newValue) {
                                setState(() {
                                  ratings[index] = newValue;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 16),
                          _buildCommentField(commentController),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      setState(() => _isSubmitting = true);

                                      try {
                                        final response = await _api.submitFeedback({
                                          'living_experience_rating': ratings[0],
                                          'maintenance_handling_rating': ratings[1],
                                          'communication_rating': ratings[2],
                                          'amenities_rating': ratings[3],
                                          'technology_handling_rating': ratings[4],
                                          'comment': commentController.text.trim().isNotEmpty
                                              ? commentController.text.trim()
                                              : null,
                                        });

                                        if (response['success']) {
                                          Navigator.pop(context);
                                          setState(() => _hasSubmittedFeedback = true);
                                          SnackbarHelper.showSuccess(context, 'Thank you for your feedback! 🎉');
                                          Future.delayed(const Duration(milliseconds: 300), () {
                                            if (mounted) _showThankYouDialog();
                                          });
                                        } else {
                                          SnackbarHelper.showError(context, response['message'] ?? 'Failed to submit feedback');
                                        }
                                      } catch (e) {
                                        SnackbarHelper.showError(context, 'An error occurred. Please try again.');
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isSubmitting = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLivinkeyGreen,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
                                  : const Text(
                                      'Submit Feedback',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingItem({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kLivinkeyGreen.withOpacity(0.2)),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: kLivinkeyGreen, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: kLivinkeyGreen,
                    inactiveTrackColor: Colors.white.withOpacity(0.15),
                    thumbColor: kLivinkeyGreen,
                    overlayColor: kLivinkeyGreen.withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('/10', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Additional Comments (Optional)',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
          hintText: 'Share your thoughts, suggestions, or concerns...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: kLivinkeyGreen.withOpacity(0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white.withOpacity(0.65))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _api.clearToken();
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