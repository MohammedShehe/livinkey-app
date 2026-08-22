import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:livinkey/models/auth_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/livinkey_logo.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../tenant/tenant_screen.dart';
import '../guest/guest_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScaleAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isTenantLogin = true;

  late final TapGestureRecognizer _signUpRecognizer;
  late final TapGestureRecognizer _forgotPasswordRecognizer;

  final ApiService _api = ApiService();

  double _getLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minDimension = screenWidth < screenHeight ? screenWidth : screenHeight;

    if (screenWidth >= 600) {
      return minDimension * 0.25;
    } else if (screenWidth >= 400) {
      return minDimension * 0.18;
    } else {
      return minDimension * 0.14;
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _signUpRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SignUpScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      };

    _forgotPasswordRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ForgotPasswordScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });

    _initializeApi();
  }

  Future<void> _initializeApi() async {
    await _api.init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _signUpRecognizer.dispose();
    _forgotPasswordRecognizer.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // ============================================================
  // FIXED: Login handler with push notification initialization AFTER login
  // ============================================================
  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      SnackbarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      LoginResponse response;

      if (_isTenantLogin) {
        response = await _api.tenantLogin(email, password);
      } else {
        response = await _api.guestLogin(email, password);
      }

      if (!mounted) {
        setState(() => _isLoading = false);
        return;
      }


      // Check if login was successful
      if (!response.success) {
        SnackbarHelper.showError(context, response.message);
        setState(() => _isLoading = false);
        return;
      }

      // Ensure we have a token and user
      if (response.token == null || response.token!.isEmpty) {
        SnackbarHelper.showError(context, 'Invalid login response: Missing token');
        setState(() => _isLoading = false);
        return;
      }

      if (response.user == null) {
        SnackbarHelper.showError(context, 'Invalid login response: Missing user data');
        setState(() => _isLoading = false);
        return;
      }

      // Validate user role
      final String userRole = response.user!.role;

      if (userRole.isEmpty) {
        SnackbarHelper.showError(context, 'Invalid user role: Role is empty');
        setState(() => _isLoading = false);
        return;
      }

      if (userRole != 'tenant' && userRole != 'guest') {
        SnackbarHelper.showError(context, 'Unknown user role: "$userRole"');
        setState(() => _isLoading = false);
        return;
      }

      // Save token and user
      await _api.setToken(response.token!, role: response.user!.role);
      await _api.saveUser(response.user!);

      // ============================================================
      // FIXED: Initialize push notifications AFTER login
      // Now the user is authenticated and FCM token can be saved
      // ============================================================
      final pushService = PushNotificationService();
      await pushService.initialize();
      
      // Retry pending token if any (from earlier failed attempts)
      await pushService.retryPendingToken();

      // Initialize notification service
      final isTenant = response.user!.role == 'tenant';
      await NotificationService().initialize(isTenant: isTenant);

      SnackbarHelper.showSuccess(context, 'Login successful!');

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Check must_change_password FIRST for tenants
      if (response.mustChangePassword && response.user!.role == 'tenant') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
              email: response.user!.email,
              isTenant: true,
            ),
          ),
        );
        return;
      }

      // Role-based navigation
      if (response.user!.role == 'tenant') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TenantScreen()),
        );
      } else if (response.user!.role == 'guest') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuestScreen()),
        );
      } else {
        SnackbarHelper.showError(context, 'Unknown user role: "${response.user!.role}"');
        setState(() => _isLoading = false);
      }

    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
      setState(() => _isLoading = false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Could not open the link.');
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final String url = 'https://wa.me/$kWhatsAppNumber';
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackbarHelper.showError(context, 'Please install WhatsApp to continue.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Could not open WhatsApp.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = _getLogoSize(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF92C24A).withOpacity(0.07),
                  Colors.black,
                  Colors.black,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Top section with logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Sign in to continue your journey',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.5),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              ScaleTransition(
                                scale: _logoScaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Image.asset(
                                    kGeneralLogo,
                                    height: logoSize,
                                    width: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Role toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_isTenantLogin) {
                                        setState(() => _isTenantLogin = true);
                                        hapticFeedback();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isTenantLogin
                                            ? const Color(0xFF92C24A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Tenant',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _isTenantLogin
                                              ? Colors.black
                                              : Colors.white.withOpacity(0.5),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_isTenantLogin) {
                                        setState(() => _isTenantLogin = false);
                                        hapticFeedback();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isTenantLogin
                                            ? Colors.transparent
                                            : const Color(0xFFFF9800),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Guest',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _isTenantLogin
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),

                          const SizedBox(height: 18),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white.withOpacity(0.4),
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                                hapticFeedback();
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Forgot Password?',
                                    style: TextStyle(
                                      color: const Color(0xFF92C24A).withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          const Color(0xFF92C24A).withOpacity(0.3),
                                      decorationThickness: 1.5,
                                    ),
                                    recognizer: _forgotPasswordRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Login Button
                          _buildLoginButton(),

                          const SizedBox(height: 24),

                          // Sign Up Link
                          Center(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: _isTenantLogin
                                          ? const Color(0xFF92C24A)
                                          : const Color(0xFFFF9800),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: (_isTenantLogin
                                              ? const Color(0xFF92C24A)
                                              : const Color(0xFFFF9800))
                                          .withOpacity(0.3),
                                      decorationThickness: 1.5,
                                    ),
                                    recognizer: _signUpRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Social Section
                          _buildSocialSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF92C24A).withOpacity(0.85),
            size: 22,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFF92C24A).withOpacity(0.55),
              width: 2,
            ),
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
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isTenantLogin
              ? [const Color(0xFF92C24A), const Color(0xFF7CB342)]
              : [const Color(0xFFFF9800), const Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isTenantLogin
                    ? const Color(0xFF92C24A)
                    : const Color(0xFFFF9800))
                .withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isTenantLogin ? 'Sign In as Tenant' : 'Sign In as Guest',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.035),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withOpacity(0.08),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Connect with Us',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withOpacity(0.08),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: FontAwesomeIcons.facebookF,
                color: const Color(0xFF1877F2),
                onTap: () {
                  hapticFeedback();
                  _launchUrl(kFacebookUrl);
                },
              ),
              const SizedBox(width: 14),
              _buildSocialButton(
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE4405F),
                onTap: () {
                  hapticFeedback();
                  _launchUrl(kInstagramUrl);
                },
              ),
              const SizedBox(width: 14),
              _buildSocialButton(
                icon: FontAwesomeIcons.google,
                color: const Color(0xFFEA4335),
                onTap: () {
                  hapticFeedback();
                  _launchUrl(kGoogleUrl);
                },
              ),
              const SizedBox(width: 14),
              _buildSocialButton(
                icon: FontAwesomeIcons.whatsapp,
                color: const Color(0xFF25D366),
                onTap: () {
                  hapticFeedback();
                  _launchWhatsApp();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.16),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withOpacity(0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}