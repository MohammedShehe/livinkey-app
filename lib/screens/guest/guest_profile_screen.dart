import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/guest/profile_row.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'guest_screen.dart';

class GuestProfileScreen extends StatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  State<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<GuestProfileScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ============================================================
  // Use Map to store real profile data from API
  // ============================================================
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isTenantViewingAsGuest = false;

  final ApiService _api = ApiService();

  // ============================================================
  // Helper methods to safely extract values
  // ============================================================
  String _getString(String key, {String defaultValue = ''}) {
    return _profileData[key]?.toString() ?? defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: kFadeDuration,
      vsync: this,
    );
    _slideController = AnimationController(
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
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIXED: Load profile - works for BOTH guests AND tenants
  // ============================================================
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _api.getGuestProfile();
      print('Guest profile response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _profileData = data;
          _isTenantViewingAsGuest = data['is_tenant_viewing_as_guest'] ?? false;
          _isLoading = false;
        });
      } else {
        // Try to get from local storage as fallback
        final user = await _api.getUser();
        if (user != null) {
          setState(() {
            _profileData = {
              'full_name': user.fullName,
              'email': user.email,
              'nationality': user.nationality,
              'phone': user.phone,
              'country_code': user.countryCode,
              'is_active': user.isActive,
              'role': user.role,
            };
            _isTenantViewingAsGuest = user.role == 'tenant';
            _isLoading = false;
          });
        } else {
          SnackbarHelper.showError(
            context, 
            response['message'] ?? 'Failed to load profile'
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Load profile error: $e');
      // Try to get from local storage as fallback
      final user = await _api.getUser();
      if (user != null) {
        setState(() {
          _profileData = {
            'full_name': user.fullName,
            'email': user.email,
            'nationality': user.nationality,
            'phone': user.phone,
            'country_code': user.countryCode,
            'is_active': user.isActive,
            'role': user.role,
          };
          _isTenantViewingAsGuest = user.role == 'tenant';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, 'Failed to load profile');
          setState(() => _isLoading = false);
        }
      }
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

  // ============================================================
  // FIXED: Edit profile - DISABLED for tenants viewing as guest
  // ============================================================
  void _showEditProfile() {
    // ============================================================
    // FIXED: Block editing if tenant is viewing as guest
    // ============================================================
    if (_isTenantViewingAsGuest) {
      SnackbarHelper.showError(
        context, 
        'Profile editing is disabled when viewing as a guest. Please switch back to tenant mode to edit your profile.'
      );
      return;
    }

    final TextEditingController nameController = 
        TextEditingController(text: _getString('full_name'));
    final TextEditingController emailController = 
        TextEditingController(text: _getString('email'));
    final TextEditingController nationalityController = 
        TextEditingController(text: _getString('nationality'));
    final TextEditingController phoneController = 
        TextEditingController(text: _getString('phone'));
    
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kLivinkeyBlack,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          _buildEditField(
                            label: 'Full Name',
                            controller: nameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildEditField(
                            label: 'Email Address',
                            controller: emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildEditField(
                            label: 'Nationality',
                            controller: nationalityController,
                            icon: Icons.flag_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildEditField(
                            label: 'Phone Number',
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : () async {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final nationality = nationalityController.text.trim();
                                  final phone = phoneController.text.trim();

                                  if (name.isEmpty || email.isEmpty || nationality.isEmpty || phone.isEmpty) {
                                    SnackbarHelper.showError(context, 'All fields are required');
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);

                                  try {
                                    // Get the existing country code from profile
                                    final countryCode = _getString('country_code', defaultValue: '+91');
                                    
                                    final response = await _api.updateGuestProfile({
                                      'full_name': name,
                                      'email': email,
                                      'nationality': nationality,
                                      'country_code': countryCode,
                                      'phone': phone,
                                    });

                                    if (!context.mounted) {
                                      setModalState(() => isSubmitting = false);
                                      return;
                                    }

                                    if (response['success'] == true) {
                                      // Update local data
                                      setState(() {
                                        _profileData['full_name'] = name;
                                        _profileData['email'] = email;
                                        _profileData['nationality'] = nationality;
                                        _profileData['phone'] = phone;
                                      });
                                      
                                      Navigator.pop(context);
                                      SnackbarHelper.showSuccess(
                                        context,
                                        'Profile updated successfully!',
                                      );
                                      await _loadProfile();
                                    } else {
                                      SnackbarHelper.showError(
                                        context,
                                        response['message'] ?? 'Failed to update profile',
                                      );
                                    }
                                  } catch (e) {
                                    SnackbarHelper.showError(
                                      context,
                                      'An error occurred. Please try again.',
                                    );
                                  } finally {
                                    if (mounted) {
                                      setModalState(() => isSubmitting = false);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
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

  // ============================================================
  // FIXED: Change Password - DISABLED for tenants viewing as guest
  // ============================================================
  void _showChangePassword() {
    // ============================================================
    // FIXED: Block password change if tenant is viewing as guest
    // ============================================================
    if (_isTenantViewingAsGuest) {
      SnackbarHelper.showError(
        context, 
        'Changing password is disabled when viewing as a guest. Please switch back to tenant mode to change your password.'
      );
      return;
    }

    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kLivinkeyBlack,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: Colors.blue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          _buildPasswordField(
                            label: 'Current Password',
                            controller: currentPasswordController,
                            obscureText: obscureCurrent,
                            onToggle: () {
                              setModalState(() {
                                obscureCurrent = !obscureCurrent;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            label: 'New Password',
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            onToggle: () {
                              setModalState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            label: 'Confirm Password',
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            onToggle: () {
                              setModalState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : () async {
                                  final currentPass = currentPasswordController.text.trim();
                                  final newPass = newPasswordController.text.trim();
                                  final confirmPass = confirmPasswordController.text.trim();

                                  if (currentPass.isEmpty) {
                                    SnackbarHelper.showError(context, 'Please enter your current password');
                                    return;
                                  }

                                  if (newPass.isEmpty) {
                                    SnackbarHelper.showError(context, 'Please enter a new password');
                                    return;
                                  }

                                  if (newPass.length < 8) {
                                    SnackbarHelper.showError(context, 'Password must be at least 8 characters');
                                    return;
                                  }

                                  if (confirmPass.isEmpty) {
                                    SnackbarHelper.showError(context, 'Please confirm your password');
                                    return;
                                  }

                                  if (newPass != confirmPass) {
                                    SnackbarHelper.showError(context, 'Passwords do not match');
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);

                                  try {
                                    final response = await _api.guestChangePassword(
                                      currentPass,
                                      newPass,
                                      confirmPass,
                                    );

                                    if (!context.mounted) {
                                      setModalState(() => isSubmitting = false);
                                      return;
                                    }

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      SnackbarHelper.showSuccess(
                                        context,
                                        'Password changed successfully!',
                                      );
                                    } else {
                                      SnackbarHelper.showError(
                                        context,
                                        response['message'] ?? 'Failed to change password',
                                      );
                                    }
                                  } catch (e) {
                                    SnackbarHelper.showError(
                                      context,
                                      'An error occurred. Please try again.',
                                    );
                                  } finally {
                                    if (mounted) {
                                      setModalState(() => isSubmitting = false);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Text(
                                        'Change Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
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
              await _api.clearToken();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                SnackbarHelper.showSuccess(context, 'Logged out successfully');
              }
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

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Get the height of the bottom navigation bar (floating tabs)
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
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
          'Profile',
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
                  const _PulsingDot(),
                  const SizedBox(width: 6),
                  Text(
                    _isTenantViewingAsGuest ? 'Tenant (Guest)' : 'Guest',
                    style: TextStyle(
                      color: _isTenantViewingAsGuest 
                          ? kLivinkeyGreen
                          : const Color(0xFFFF9800),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _loadProfile,
            color: const Color(0xFFFF9800),
            backgroundColor: kLivinkeyBlack,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // ============================================================
                  // Profile header uses real data
                  // ============================================================
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  _buildSectionLabel(_isTenantViewingAsGuest ? 'Tenant Details (Guest View)' : 'Guest Details'),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.045),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ProfileRow(
                          label: 'Full Name',
                          value: _getString('full_name', defaultValue: 'Not set'),
                        ),
                        ProfileRow(
                          label: 'Email',
                          value: _getString('email', defaultValue: 'Not set'),
                        ),
                        ProfileRow(
                          label: 'Nationality',
                          value: _getString('nationality', defaultValue: 'Not set'),
                        ),
                        ProfileRow(
                          label: 'Phone',
                          value: '${_getString('country_code', defaultValue: '+91')} ${_getString('phone', defaultValue: '')}',
                        ),
                        ProfileRow(
                          label: 'Status',
                          value: _getString('is_active') == '1' ? 'Active' : 'Inactive',
                        ),
                        ProfileRow(
                          label: 'Role',
                          value: _isTenantViewingAsGuest ? 'Tenant (Viewing as Guest)' : 'Guest',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // FIXED: Edit Profile button - disabled for tenants viewing as guest
                  // ============================================================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _showEditProfile();
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        color: _isTenantViewingAsGuest 
                            ? Colors.grey 
                            : const Color(0xFFFF9800),
                        size: 20,
                      ),
                      label: Text(
                        _isTenantViewingAsGuest ? 'Edit Profile (Disabled)' : 'Edit Profile',
                        style: TextStyle(
                          color: _isTenantViewingAsGuest 
                              ? Colors.grey 
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isTenantViewingAsGuest 
                            ? Colors.grey.withOpacity(0.06)
                            : const Color(0xFFFF9800).withOpacity(0.06),
                        side: BorderSide(
                          color: _isTenantViewingAsGuest 
                              ? Colors.grey.withOpacity(0.3)
                              : const Color(0xFFFF9800).withOpacity(0.35),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ============================================================
                  // FIXED: Change Password button - disabled for tenants viewing as guest
                  // ============================================================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _showChangePassword();
                      },
                      icon: Icon(
                        Icons.lock_outline_rounded,
                        color: _isTenantViewingAsGuest 
                            ? Colors.grey 
                            : Colors.blue,
                        size: 20,
                      ),
                      label: Text(
                        _isTenantViewingAsGuest ? 'Change Password (Disabled)' : 'Change Password',
                        style: TextStyle(
                          color: _isTenantViewingAsGuest 
                              ? Colors.grey 
                              : Colors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isTenantViewingAsGuest 
                            ? Colors.grey.withOpacity(0.06)
                            : Colors.blue.withOpacity(0.06),
                        side: BorderSide(
                          color: _isTenantViewingAsGuest 
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.35),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionLabel('Quick Links'),
                  const SizedBox(height: 12),

                  _buildLinkItem(
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    onTap: () {
                      SnackbarHelper.show(context, 'Terms of Service');
                    },
                  ),
                  _buildLinkItem(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    onTap: () {
                      SnackbarHelper.show(context, 'Privacy Policy');
                    },
                  ),
                  _buildLinkItem(
                    icon: Icons.contact_support_rounded,
                    title: 'Contact Us',
                    onTap: () {
                      _showContactOptions();
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.05),
                        side: BorderSide(color: Colors.red.withOpacity(0.35), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
    );
  }

  // ============================================================
  // Helper methods use real data
  // ============================================================
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final name = _getString('full_name', defaultValue: 'Guest User');
    final email = _getString('email', defaultValue: 'guest@example.com');
    final initials = getInitials(name);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _isTenantViewingAsGuest 
                ? kLivinkeyGreen.withOpacity(0.14)
                : const Color(0xFFFF9800).withOpacity(0.14),
            _isTenantViewingAsGuest 
                ? kLivinkeyGreen.withOpacity(0.02)
                : const Color(0xFFFF9800).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isTenantViewingAsGuest 
              ? kLivinkeyGreen.withOpacity(0.18)
              : const Color(0xFFFF9800).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isTenantViewingAsGuest 
                ? kLivinkeyGreen.withOpacity(0.08)
                : const Color(0xFFFF9800).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isTenantViewingAsGuest 
                    ? [kLivinkeyGreen, Color(0xFF66BB6A)]
                    : [const Color(0xFFFF9800), const Color(0xFFFFA726)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _isTenantViewingAsGuest 
                      ? kLivinkeyGreen.withOpacity(0.4)
                      : const Color(0xFFFF9800).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isTenantViewingAsGuest 
                        ? kLivinkeyGreen.withOpacity(0.16)
                        : const Color(0xFFFF9800).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isTenantViewingAsGuest 
                          ? kLivinkeyGreen.withOpacity(0.2)
                          : const Color(0xFFFF9800).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isTenantViewingAsGuest ? 'Tenant (Guest View)' : 'Guest',
                    style: TextStyle(
                      color: _isTenantViewingAsGuest 
                          ? kLivinkeyGreen
                          : const Color(0xFFFF9800),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFFF9800).withOpacity(0.85),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFFF9800).withOpacity(0.8),
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFFFF9800).withOpacity(0.5),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: const Color(0xFFFF9800).withOpacity(0.8),
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white.withOpacity(0.4),
              size: 22,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFFFF9800).withOpacity(0.5),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kLivinkeyBlack,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactOption(
              icon: Icons.chat_rounded,
              color: const Color(0xFF25D366),
              title: 'WhatsApp',
              subtitle: '+91 98783 83497',
              onTap: () => _launchUrl(kWhatsAppUrl),
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.photo_camera_rounded,
              color: const Color(0xFFE4405F),
              title: 'Instagram',
              subtitle: '@livinkey',
              onTap: () => _launchUrl('https://www.instagram.com/livinkey?igsh=MTc0eWdyeTNvcmFtZA=='),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.02),
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
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 15,
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
      child: Icon(Icons.circle, color: const Color(0xFFFF9800), size: 8),
    );
  }
}