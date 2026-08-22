// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/snackbar_helper.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _searchNationalityController =
      TextEditingController();
  final TextEditingController _searchCountryCodeController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedNationality = 'Indian';
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  bool _isNationalityDropdownOpen = false;
  bool _isCountryCodeDropdownOpen = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScaleAnimation;

  late final TapGestureRecognizer _backToLoginRecognizer;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  final ApiService _api = ApiService();

  final List<String> _allNationalities = [
    'Afghan', 'Albanian', 'Algerian', 'American', 'Andorran', 'Angolan',
    'Antiguan', 'Argentinian', 'Armenian', 'Australian', 'Austrian', 'Azerbaijani',
    'Bahamian', 'Bahraini', 'Bangladeshi', 'Barbadian', 'Barbudan', 'Belarusian',
    'Belgian', 'Belizean', 'Beninese', 'Bhutanese', 'Bolivian', 'Bosnian',
    'Botswanan', 'Brazilian', 'British', 'Bruneian', 'Bulgarian', 'Burkinabe',
    'Burmese', 'Burundian', 'Cambodian', 'Cameroonian', 'Canadian', 'Cape Verdean',
    'Central African', 'Chadian', 'Chilean', 'Chinese', 'Colombian', 'Comorian',
    'Congolese', 'Costa Rican', 'Croatian', 'Cuban', 'Cypriot', 'Czech', 'Danish',
    'Djiboutian', 'Dominican', 'Dutch', 'Ecuadorian', 'Egyptian', 'Emirati',
    'Equatorial Guinean', 'Eritrean', 'Estonian', 'Ethiopian', 'Fijian', 'Filipino',
    'Finnish', 'French', 'Gabonese', 'Gambian', 'Georgian', 'German', 'Ghanaian',
    'Greek', 'Grenadian', 'Guatemalan', 'Guinean', 'Guyanese', 'Haitian',
    'Honduran', 'Hungarian', 'Icelandic', 'Indian', 'Indonesian', 'Iranian',
    'Iraqi', 'Irish', 'Israeli', 'Italian', 'Jamaican', 'Japanese', 'Jordanian',
    'Kazakh', 'Kenyan', 'Kittitian', 'Kuwaiti', 'Kyrgyz', 'Laotian', 'Latvian',
    'Lebanese', 'Liberian', 'Libyan', 'Liechtensteiner', 'Lithuanian',
    'Luxembourgish', 'Malagasy', 'Malawian', 'Malaysian', 'Maldivian', 'Malian',
    'Maltese', 'Marshallese', 'Mauritanian', 'Mauritian', 'Mexican', 'Micronesian',
    'Moldovan', 'Monacan', 'Mongolian', 'Montenegrin', 'Moroccan', 'Mozambican',
    'Namibian', 'Nauruan', 'Nepali', 'New Zealander', 'Nicaraguan', 'Nigerian',
    'North Korean', 'Norwegian', 'Omani', 'Pakistani', 'Palauan', 'Panamanian',
    'Papua New Guinean', 'Paraguayan', 'Peruvian', 'Polish', 'Portuguese',
    'Qatari', 'Romanian', 'Russian', 'Rwandan', 'Salvadoran', 'Samoan',
    'Sao Tomean', 'Saudi', 'Senegalese', 'Serbian', 'Seychellois',
    'Sierra Leonean', 'Singaporean', 'Slovak', 'Slovenian', 'Solomon Islander',
    'Somali', 'South African', 'South Korean', 'South Sudanese', 'Spanish',
    'Sri Lankan', 'Sudanese', 'Surinamese', 'Swazi', 'Swedish', 'Swiss', 'Syrian',
    'Taiwanese', 'Tajik', 'Tanzanian', 'Thai', 'Timorese', 'Togolese', 'Tongan',
    'Trinidadian', 'Tunisian', 'Turkish', 'Turkmen', 'Tuvaluan', 'Ugandan',
    'Ukrainian', 'Uruguayan', 'Uzbek', 'Vanuatuan', 'Vatican', 'Venezuelan',
    'Vietnamese', 'Yemeni', 'Zambian', 'Zimbabwean',
  ];

  List<String> _filteredNationalities = [];

  final List<Map<String, String>> _allCountryCodes = [
    {'code': '+93', 'country': 'Afghanistan'},
    {'code': '+355', 'country': 'Albania'},
    {'code': '+213', 'country': 'Algeria'},
    {'code': '+376', 'country': 'Andorra'},
    {'code': '+244', 'country': 'Angola'},
    {'code': '+1-268', 'country': 'Antigua and Barbuda'},
    {'code': '+54', 'country': 'Argentina'},
    {'code': '+374', 'country': 'Armenia'},
    {'code': '+61', 'country': 'Australia'},
    {'code': '+43', 'country': 'Austria'},
    {'code': '+994', 'country': 'Azerbaijan'},
    {'code': '+1-242', 'country': 'Bahamas'},
    {'code': '+973', 'country': 'Bahrain'},
    {'code': '+880', 'country': 'Bangladesh'},
    {'code': '+1-246', 'country': 'Barbados'},
    {'code': '+375', 'country': 'Belarus'},
    {'code': '+32', 'country': 'Belgium'},
    {'code': '+501', 'country': 'Belize'},
    {'code': '+229', 'country': 'Benin'},
    {'code': '+975', 'country': 'Bhutan'},
    {'code': '+591', 'country': 'Bolivia'},
    {'code': '+387', 'country': 'Bosnia and Herzegovina'},
    {'code': '+267', 'country': 'Botswana'},
    {'code': '+55', 'country': 'Brazil'},
    {'code': '+673', 'country': 'Brunei'},
    {'code': '+359', 'country': 'Bulgaria'},
    {'code': '+226', 'country': 'Burkina Faso'},
    {'code': '+257', 'country': 'Burundi'},
    {'code': '+855', 'country': 'Cambodia'},
    {'code': '+237', 'country': 'Cameroon'},
    {'code': '+1', 'country': 'Canada'},
    {'code': '+238', 'country': 'Cape Verde'},
    {'code': '+236', 'country': 'Central African Republic'},
    {'code': '+235', 'country': 'Chad'},
    {'code': '+56', 'country': 'Chile'},
    {'code': '+86', 'country': 'China'},
    {'code': '+57', 'country': 'Colombia'},
    {'code': '+269', 'country': 'Comoros'},
    {'code': '+242', 'country': 'Congo'},
    {'code': '+506', 'country': 'Costa Rica'},
    {'code': '+385', 'country': 'Croatia'},
    {'code': '+53', 'country': 'Cuba'},
    {'code': '+357', 'country': 'Cyprus'},
    {'code': '+420', 'country': 'Czech Republic'},
    {'code': '+45', 'country': 'Denmark'},
    {'code': '+253', 'country': 'Djibouti'},
    {'code': '+1-767', 'country': 'Dominica'},
    {'code': '+1-809', 'country': 'Dominican Republic'},
    {'code': '+670', 'country': 'East Timor'},
    {'code': '+593', 'country': 'Ecuador'},
    {'code': '+20', 'country': 'Egypt'},
    {'code': '+503', 'country': 'El Salvador'},
    {'code': '+240', 'country': 'Equatorial Guinea'},
    {'code': '+291', 'country': 'Eritrea'},
    {'code': '+372', 'country': 'Estonia'},
    {'code': '+251', 'country': 'Ethiopia'},
    {'code': '+679', 'country': 'Fiji'},
    {'code': '+358', 'country': 'Finland'},
    {'code': '+33', 'country': 'France'},
    {'code': '+241', 'country': 'Gabon'},
    {'code': '+220', 'country': 'Gambia'},
    {'code': '+995', 'country': 'Georgia'},
    {'code': '+49', 'country': 'Germany'},
    {'code': '+233', 'country': 'Ghana'},
    {'code': '+30', 'country': 'Greece'},
    {'code': '+1-473', 'country': 'Grenada'},
    {'code': '+502', 'country': 'Guatemala'},
    {'code': '+224', 'country': 'Guinea'},
    {'code': '+245', 'country': 'Guinea-Bissau'},
    {'code': '+592', 'country': 'Guyana'},
    {'code': '+509', 'country': 'Haiti'},
    {'code': '+504', 'country': 'Honduras'},
    {'code': '+36', 'country': 'Hungary'},
    {'code': '+354', 'country': 'Iceland'},
    {'code': '+91', 'country': 'India'},
    {'code': '+62', 'country': 'Indonesia'},
    {'code': '+98', 'country': 'Iran'},
    {'code': '+964', 'country': 'Iraq'},
    {'code': '+353', 'country': 'Ireland'},
    {'code': '+972', 'country': 'Israel'},
    {'code': '+39', 'country': 'Italy'},
    {'code': '+1-876', 'country': 'Jamaica'},
    {'code': '+81', 'country': 'Japan'},
    {'code': '+962', 'country': 'Jordan'},
    {'code': '+7', 'country': 'Kazakhstan'},
    {'code': '+254', 'country': 'Kenya'},
    {'code': '+686', 'country': 'Kiribati'},
    {'code': '+82', 'country': 'South Korea'},
    {'code': '+850', 'country': 'North Korea'},
    {'code': '+965', 'country': 'Kuwait'},
    {'code': '+996', 'country': 'Kyrgyzstan'},
    {'code': '+856', 'country': 'Laos'},
    {'code': '+371', 'country': 'Latvia'},
    {'code': '+961', 'country': 'Lebanon'},
    {'code': '+266', 'country': 'Lesotho'},
    {'code': '+231', 'country': 'Liberia'},
    {'code': '+218', 'country': 'Libya'},
    {'code': '+423', 'country': 'Liechtenstein'},
    {'code': '+370', 'country': 'Lithuania'},
    {'code': '+352', 'country': 'Luxembourg'},
    {'code': '+389', 'country': 'North Macedonia'},
    {'code': '+261', 'country': 'Madagascar'},
    {'code': '+265', 'country': 'Malawi'},
    {'code': '+60', 'country': 'Malaysia'},
    {'code': '+960', 'country': 'Maldives'},
    {'code': '+223', 'country': 'Mali'},
    {'code': '+356', 'country': 'Malta'},
    {'code': '+692', 'country': 'Marshall Islands'},
    {'code': '+222', 'country': 'Mauritania'},
    {'code': '+230', 'country': 'Mauritius'},
    {'code': '+52', 'country': 'Mexico'},
    {'code': '+691', 'country': 'Micronesia'},
    {'code': '+373', 'country': 'Moldova'},
    {'code': '+377', 'country': 'Monaco'},
    {'code': '+976', 'country': 'Mongolia'},
    {'code': '+382', 'country': 'Montenegro'},
    {'code': '+212', 'country': 'Morocco'},
    {'code': '+258', 'country': 'Mozambique'},
    {'code': '+95', 'country': 'Myanmar'},
    {'code': '+264', 'country': 'Namibia'},
    {'code': '+674', 'country': 'Nauru'},
    {'code': '+977', 'country': 'Nepal'},
    {'code': '+31', 'country': 'Netherlands'},
    {'code': '+64', 'country': 'New Zealand'},
    {'code': '+505', 'country': 'Nicaragua'},
    {'code': '+227', 'country': 'Niger'},
    {'code': '+234', 'country': 'Nigeria'},
    {'code': '+47', 'country': 'Norway'},
    {'code': '+968', 'country': 'Oman'},
    {'code': '+92', 'country': 'Pakistan'},
    {'code': '+680', 'country': 'Palau'},
    {'code': '+970', 'country': 'Palestine'},
    {'code': '+507', 'country': 'Panama'},
    {'code': '+675', 'country': 'Papua New Guinea'},
    {'code': '+595', 'country': 'Paraguay'},
    {'code': '+51', 'country': 'Peru'},
    {'code': '+63', 'country': 'Philippines'},
    {'code': '+48', 'country': 'Poland'},
    {'code': '+351', 'country': 'Portugal'},
    {'code': '+974', 'country': 'Qatar'},
    {'code': '+40', 'country': 'Romania'},
    {'code': '+7', 'country': 'Russia'},
    {'code': '+250', 'country': 'Rwanda'},
    {'code': '+1-869', 'country': 'Saint Kitts and Nevis'},
    {'code': '+1-758', 'country': 'Saint Lucia'},
    {'code': '+1-784', 'country': 'Saint Vincent'},
    {'code': '+685', 'country': 'Samoa'},
    {'code': '+378', 'country': 'San Marino'},
    {'code': '+239', 'country': 'Sao Tome'},
    {'code': '+966', 'country': 'Saudi Arabia'},
    {'code': '+221', 'country': 'Senegal'},
    {'code': '+381', 'country': 'Serbia'},
    {'code': '+248', 'country': 'Seychelles'},
    {'code': '+232', 'country': 'Sierra Leone'},
    {'code': '+65', 'country': 'Singapore'},
    {'code': '+421', 'country': 'Slovakia'},
    {'code': '+386', 'country': 'Slovenia'},
    {'code': '+677', 'country': 'Solomon Islands'},
    {'code': '+252', 'country': 'Somalia'},
    {'code': '+27', 'country': 'South Africa'},
    {'code': '+211', 'country': 'South Sudan'},
    {'code': '+34', 'country': 'Spain'},
    {'code': '+94', 'country': 'Sri Lanka'},
    {'code': '+249', 'country': 'Sudan'},
    {'code': '+597', 'country': 'Suriname'},
    {'code': '+46', 'country': 'Sweden'},
    {'code': '+41', 'country': 'Switzerland'},
    {'code': '+963', 'country': 'Syria'},
    {'code': '+886', 'country': 'Taiwan'},
    {'code': '+992', 'country': 'Tajikistan'},
    {'code': '+255', 'country': 'Tanzania'},
    {'code': '+66', 'country': 'Thailand'},
    {'code': '+228', 'country': 'Togo'},
    {'code': '+676', 'country': 'Tonga'},
    {'code': '+1-868', 'country': 'Trinidad and Tobago'},
    {'code': '+216', 'country': 'Tunisia'},
    {'code': '+90', 'country': 'Turkey'},
    {'code': '+993', 'country': 'Turkmenistan'},
    {'code': '+688', 'country': 'Tuvalu'},
    {'code': '+256', 'country': 'Uganda'},
    {'code': '+380', 'country': 'Ukraine'},
    {'code': '+971', 'country': 'United Arab Emirates'},
    {'code': '+44', 'country': 'United Kingdom'},
    {'code': '+1', 'country': 'United States'},
    {'code': '+598', 'country': 'Uruguay'},
    {'code': '+998', 'country': 'Uzbekistan'},
    {'code': '+678', 'country': 'Vanuatu'},
    {'code': '+379', 'country': 'Vatican City'},
    {'code': '+58', 'country': 'Venezuela'},
    {'code': '+84', 'country': 'Vietnam'},
    {'code': '+967', 'country': 'Yemen'},
    {'code': '+260', 'country': 'Zambia'},
    {'code': '+263', 'country': 'Zimbabwe'},
  ];

  List<Map<String, String>> _filteredCountryCodes = [];

  @override
  void initState() {
    super.initState();
    _filteredNationalities = List.from(_allNationalities);
    _filteredCountryCodes = List.from(_allCountryCodes);

    _initializeAnimations();
    _initializeRecognizers();
    _initializeApi();
  }

  Future<void> _initializeApi() async {
    await _api.init();
  }

  void _initializeAnimations() {
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

    _logoScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutBack,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  void _initializeRecognizers() {
    _backToLoginRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        _navigateBackToLogin();
      };

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        SnackbarHelper.show(context, 'Terms of Services');
      };

    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        hapticSelection();
        SnackbarHelper.show(context, 'Privacy Policy');
      };
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _searchNationalityController.dispose();
    _searchCountryCodeController.dispose();
    _backToLoginRecognizer.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
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

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return phone.length >= 5 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  void _filterNationalities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNationalities = List.from(_allNationalities);
      } else {
        _filteredNationalities = _allNationalities
            .where((nationality) =>
                nationality.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterCountryCodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountryCodes = List.from(_allCountryCodes);
      } else {
        _filteredCountryCodes = _allCountryCodes
            .where((country) =>
                country['country']!
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                country['code']!.contains(query))
            .toList();
      }
    });
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      SnackbarHelper.showError(context, 'Please agree to the Terms of Services');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _api.guestRegister({
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'nationality': _selectedNationality,
        'country_code': _selectedCountryCode,
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'confirm_password': _confirmPasswordController.text.trim(),
      });

      if (!mounted) return;

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(
            context, 'Account created successfully! Please login.');

        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          _navigateBackToLogin();
        }
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildBackButton(),
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildGuestBadge(),
                          const SizedBox(height: 24),
                          _buildFullNameField(),
                          const SizedBox(height: 16),
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildNationalityDropdown(),
                          const SizedBox(height: 16),
                          _buildPhoneField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 16),
                          _buildConfirmPasswordField(),
                          const SizedBox(height: 6),
                          _buildPasswordHint(),
                          const SizedBox(height: 20),
                          _buildTermsAndConditions(),
                          const SizedBox(height: 24),
                          _buildSignUpButton(),
                          const SizedBox(height: 20),
                          _buildSignInLink(),
                          const SizedBox(height: 16),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _navigateBackToLogin,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.85)],
                ).createShader(bounds),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join the Livinkey community',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.45),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ScaleTransition(
          scale: _logoScaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Image.asset(
              kGeneralLogo,
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9800).withOpacity(0.16),
            const Color(0xFFFF9800).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            'Guest Account',
            style: TextStyle(
              color: const Color(0xFFFF9800).withOpacity(0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Fixed Role',
              style: TextStyle(
                color: const Color(0xFFFF9800).withOpacity(0.65),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullNameField() {
    return _buildTextField(
      controller: _fullNameController,
      label: 'Full Name',
      icon: Icons.person_outline,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      label: 'Email Address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email address';
        }
        if (!_isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildNationalityDropdown() {
    return _buildCustomDropdown<String>(
      label: 'Nationality',
      icon: Icons.flag_outlined,
      selectedValue: _selectedNationality,
      items: _filteredNationalities,
      searchController: _searchNationalityController,
      onSearchChanged: _filterNationalities,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedNationality = value;
            _searchNationalityController.clear();
            _filterNationalities('');
            _isNationalityDropdownOpen = false;
          });
          hapticSelection();
        }
      },
      isOpen: _isNationalityDropdownOpen,
      onToggle: () {
        setState(() {
          _isNationalityDropdownOpen = !_isNationalityDropdownOpen;
          if (!_isNationalityDropdownOpen) {
            _searchNationalityController.clear();
            _filterNationalities('');
          }
        });
      },
      buildItem: (item) => Text(
        item,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      buildSelectedItem: (item) => Text(
        item,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your nationality';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          fit: FlexFit.loose,
          child: _buildCustomDropdown<String>(
            label: 'Code',
            icon: Icons.phone_outlined,
            selectedValue: _selectedCountryCode,
            items:
                _filteredCountryCodes.map((item) => item['code']!).toList(),
            searchController: _searchCountryCodeController,
            onSearchChanged: _filterCountryCodes,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCountryCode = value;
                  _searchCountryCodeController.clear();
                  _filterCountryCodes('');
                  _isCountryCodeDropdownOpen = false;
                });
                hapticSelection();
              }
            },
            isOpen: _isCountryCodeDropdownOpen,
            onToggle: () {
              setState(() {
                _isCountryCodeDropdownOpen = !_isCountryCodeDropdownOpen;
                if (!_isCountryCodeDropdownOpen) {
                  _searchCountryCodeController.clear();
                  _filterCountryCodes('');
                }
              });
            },
            buildItem: (item) {
              final code = item as String;
              final country = _allCountryCodes.firstWhere(
                (c) => c['code'] == code,
                orElse: () => {'code': code, 'country': 'Unknown'},
              );
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF92C24A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xFF92C24A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      country['country']!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
            buildSelectedItem: (item) {
              final code = item as String;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF92C24A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFF92C24A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Select code';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 5,
          fit: FlexFit.loose,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: _phoneController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: const Color(0xFF92C24A).withOpacity(0.8),
                  size: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF92C24A).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (!_isValidPhone(value)) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      label: 'Password',
      icon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white.withOpacity(0.4),
          size: 18,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
          hapticFeedback();
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildTextField(
      controller: _confirmPasswordController,
      label: 'Confirm Password',
      icon: Icons.lock_outline,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white.withOpacity(0.4),
          size: 18,
        ),
        onPressed: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
          hapticFeedback();
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            'Password must be at least 6 characters',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Theme(
            data: ThemeData(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => const Color(0xFF92C24A),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              unselectedWidgetColor: Colors.white.withOpacity(0.3),
            ),
            child: Checkbox(
              value: _agreeToTerms,
              onChanged: (value) {
                setState(() {
                  _agreeToTerms = value!;
                });
                hapticSelection();
              },
              activeColor: const Color(0xFF92C24A),
              checkColor: Colors.black,
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Services',
                    style: TextStyle(
                      color: const Color(0xFF92C24A).withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          const Color(0xFF92C24A).withOpacity(0.3),
                      decorationThickness: 1.5,
                    ),
                    recognizer: _termsRecognizer,
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: const Color(0xFF92C24A).withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          const Color(0xFF92C24A).withOpacity(0.3),
                      decorationThickness: 1.5,
                    ),
                    recognizer: _privacyRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: _agreeToTerms
            ? const LinearGradient(
                colors: [
                  Color(0xFF92C24A),
                  Color(0xFF7CB342),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _agreeToTerms
            ? [
                BoxShadow(
                  color: const Color(0xFF92C24A).withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF92C24A).withOpacity(0.15),
                  blurRadius: 50,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor:
              _agreeToTerms ? Colors.black : Colors.white.withOpacity(0.3),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading || !_agreeToTerms ? null : _handleSignUp,
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.black,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _agreeToTerms
                          ? Colors.black
                          : Colors.white.withOpacity(0.3),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _agreeToTerms
                        ? Colors.black
                        : Colors.white.withOpacity(0.3),
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: const Color(0xFF92C24A),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF92C24A).withOpacity(0.3),
                decorationThickness: 1.5,
              ),
              recognizer: _backToLoginRecognizer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDropdown<T>({
    required String label,
    required IconData icon,
    required T selectedValue,
    required List<T> items,
    required TextEditingController searchController,
    required Function(String) onSearchChanged,
    required Function(T?) onChanged,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget Function(T) buildItem,
    required Widget Function(T) buildSelectedItem,
    required String? Function(T?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOpen
                    ? [
                        const Color(0xFF92C24A).withOpacity(0.08),
                        const Color(0xFF92C24A).withOpacity(0.02),
                      ]
                    : [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? const Color(0xFF92C24A).withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
                width: isOpen ? 2 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF92C24A).withOpacity(0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 1),
                        buildSelectedItem(selectedValue),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search ${label.toLowerCase()}...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF92C24A).withOpacity(0.6),
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF92C24A).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      isDense: true,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                Divider(
                  color: Colors.white.withOpacity(0.08),
                  height: 1,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 180,
                  ),
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: Colors.white.withOpacity(0.2),
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = item == selectedValue;
                            return InkWell(
                              onTap: () {
                                onChanged(item);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF92C24A)
                                          .withOpacity(0.1)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: buildItem(item)),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color:
                                            const Color(0xFF92C24A).withOpacity(0.85),
                                        size: 14,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        if (validator(selectedValue) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              validator(selectedValue)!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
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
    String? Function(String?)? validator,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF92C24A).withOpacity(0.8),
            size: 18,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF92C24A).withOpacity(0.5),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          errorStyle: TextStyle(
            color: Colors.red.shade300,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: validator,
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
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFFFF9800),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}