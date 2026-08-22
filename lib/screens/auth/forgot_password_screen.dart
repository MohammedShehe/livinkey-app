// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:livinkey/models/auth_models.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/snackbar_helper.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _email = '';
  String? _resetToken;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  late final TapGestureRecognizer _backToLoginRecognizer;

  final ApiService _api = ApiService();
  bool _isTenantLogin = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
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

    _backToLoginRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        _navigateBackToLogin();
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
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _backToLoginRecognizer.dispose();
    super.dispose();
  }

  void _navigateBackToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
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
  }

  void _nextStep() {
    hapticFeedback();
    setState(() {
      _currentStep++;
    });
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _previousStep() {
    hapticFeedback();
    setState(() {
      _currentStep--;
    });
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSendOTP() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      SnackbarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _email = email;
    });

    try {
      Map<String, dynamic> response;

      if (_isTenantLogin) {
        response = await _api.tenantForgotPassword(email);
      } else {
        response = await _api.guestForgotPassword(email);
      }

      if (!mounted) return;

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'OTP sent to $email');
        _nextStep();
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOTP() async {
    if (_email.isEmpty) {
      SnackbarHelper.showError(context, 'Email not found. Please go back.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (_isTenantLogin) {
        response = await _api.tenantForgotPassword(_email);
      } else {
        response = await _api.guestForgotPassword(_email);
      }

      if (!mounted) return;

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'OTP resent to $_email');
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    final String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter the OTP');
      return;
    }

    if (otp.length < 4) {
      SnackbarHelper.showError(context, 'Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      OtpResponse response;

      if (_isTenantLogin) {
        response = await _api.tenantVerifyOTP(_email, otp);
      } else {
        response = await _api.guestVerifyOTP(_email, otp);
      }

      if (!mounted) return;

      if (response.success) {
        _resetToken = response.resetToken;
        SnackbarHelper.showSuccess(context, 'OTP verified successfully!');
        _nextStep();
      } else {
        SnackbarHelper.showError(context, response.message);
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter a new password');
      return;
    }

    if (newPassword.length < 6) {
      SnackbarHelper.showError(context, 'Password must be at least 6 characters');
      return;
    }

    if (confirmPassword.isEmpty) {
      SnackbarHelper.showError(context, 'Please confirm your password');
      return;
    }

    if (newPassword != confirmPassword) {
      SnackbarHelper.showError(context, 'Passwords do not match');
      return;
    }

    if (_resetToken == null) {
      SnackbarHelper.showError(context, 'Reset token not found. Please verify OTP again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (_isTenantLogin) {
        response = await _api.tenantResetPassword(_resetToken!, newPassword, confirmPassword);
      } else {
        response = await _api.guestResetPassword(_resetToken!, newPassword, confirmPassword);
      }

      if (!mounted) return;

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'Password reset successful!');

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateBackToLogin();
        }
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password';
      case 1:
        return 'Verify OTP';
      case 2:
        return 'Create New Password';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your registered email to receive OTP';
      case 1:
        return 'Enter the OTP sent to your email';
      case 2:
        return 'Create a strong new password';
      default:
        return '';
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.mail_lock_rounded;
      case 1:
        return Icons.pin_rounded;
      case 2:
        return Icons.password_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: _navigateBackToLogin,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white.withOpacity(0.75),
                                size: 22,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

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

                          _buildProgressIndicator(),
                          const SizedBox(height: 24),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF92C24A), const Color(0xFF66BB6A)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF92C24A).withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getStepIcon(),
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStepTitle(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStepSubtitle(),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.5),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildStepContent(),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  const TextSpan(text: 'Remember your password? '),
                                  TextSpan(
                                    text: 'Back to Login',
                                    style: TextStyle(
                                      color: const Color(0xFF92C24A),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          const Color(0xFF92C24A).withOpacity(0.3),
                                    ),
                                    recognizer: _backToLoginRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
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

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        bool isCurrent = index == _currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFF92C24A), Color(0xFF66BB6A)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF92C24A), Color(0xFF66BB6A)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.06),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF92C24A)
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xFF92C24A).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isActive && index < _currentStep
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 16,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 2,
                  width: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: const Color(0xFF92C24A),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOTPStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email_step'),
      children: [
        Container(
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
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSendOTP(),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: const Color(0xFF92C24A).withOpacity(0.7),
                size: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF92C24A).withOpacity(0.5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          onPressed: _handleSendOTP,
          label: 'Send OTP',
          icon: Icons.send_rounded,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      key: const ValueKey('otp_step'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF92C24A).withOpacity(0.1),
                const Color(0xFF92C24A).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF92C24A).withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF92C24A).withOpacity(0.06),
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
                  color: const Color(0xFF92C24A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: const Color(0xFF92C24A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OTP sent to',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleResendOTP,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF92C24A),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Resend',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
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
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _otpController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleVerifyOTP(),
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              counterText: '',
              prefixIcon: Icon(
                Icons.pin_outlined,
                color: const Color(0xFF92C24A).withOpacity(0.7),
                size: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF92C24A).withOpacity(0.5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // FIXED: Use MainAxisAlignment.spaceEvenly with smaller spacer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 1,
              child: _buildActionButton(
                onPressed: _previousStep,
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                isLoading: false,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: _buildActionButton(
                onPressed: _handleVerifyOTP,
                label: 'Verify',
                icon: Icons.check_circle_rounded,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey('password_step'),
      children: [
        Container(
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
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: const Color(0xFF92C24A).withOpacity(0.7),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withOpacity(0.5),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                  hapticFeedback();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF92C24A).withOpacity(0.5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: const Color(0xFF92C24A).withOpacity(0.7),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withOpacity(0.5),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                  hapticFeedback();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF92C24A).withOpacity(0.5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.3),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'Password must be at least 6 characters',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // FIXED: Use MainAxisAlignment.spaceEvenly with smaller spacer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 1,
              child: _buildActionButton(
                onPressed: _previousStep,
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                isLoading: false,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: _buildActionButton(
                onPressed: _handleResetPassword,
                label: 'Reset Password',
                icon: Icons.check_circle_rounded,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isLoading,
    bool isOutlined = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52, // Reduced from 56 to save space
      decoration: isOutlined
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
            )
          : BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF92C24A), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF92C24A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF92C24A).withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isOutlined ? Colors.white : Colors.black,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: isOutlined
              ? BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                )
              : BorderSide.none,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined ? Colors.white : Colors.black,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isOutlined ? Colors.white : Colors.black,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isOutlined ? Colors.white : Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}