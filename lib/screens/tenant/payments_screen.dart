// lib/screens/tenant/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/tenant/payment_chip.dart';
import '../../widgets/common/snackbar_helper.dart';
import 'tenant_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedPaymentMethod = 0;
  bool _isRefreshing = false;

  // Payment proof form controllers
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmittingProof = false;

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
    _transactionIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Helper method to open drawer using the parent state
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
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Payments refreshed');
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            title: const Text(
              'Exit App?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kLivinkeyGreen, Color(0xFF7CB342)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kLivinkeyGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    const double navBarClearance = 96.0;

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
          title: const Text(
            'Payments',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                ),
              ),
              onPressed: () => _showPaymentHistory(context),
            ),
            const SizedBox(width: 8),
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
                    32 + navBarClearance + bottomSafeArea,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      _buildPaymentStats(),
                      const SizedBox(height: 28),

                      _buildSectionHeader('Payment Method'),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          PaymentChip(
                            label: 'Pay Online',
                            isSelected: _selectedPaymentMethod == 0,
                            onTap: () => setState(() => _selectedPaymentMethod = 0),
                          ),
                          const SizedBox(width: 10),
                          PaymentChip(
                            label: 'Pay Cash',
                            isSelected: _selectedPaymentMethod == 1,
                            onTap: () => setState(() => _selectedPaymentMethod = 1),
                          ),
                          const SizedBox(width: 10),
                          PaymentChip(
                            label: 'Partial Payment',
                            isSelected: _selectedPaymentMethod == 2,
                            onTap: () => setState(() => _selectedPaymentMethod = 2),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildQRSection(),
                      const SizedBox(height: 16),

                      _buildSectionHeader('Electricity Meter'),
                      const SizedBox(height: 12),
                      _buildMeterCard(),
                      const SizedBox(height: 20),

                      _buildSubmitProofButton(),
                      const SizedBox(height: 8),
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
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: kLivinkeyGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStats() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kLivinkeyGreen.withOpacity(0.1),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kLivinkeyGreen.withOpacity(0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem('Current Rent', '₹8,500', kLivinkeyGreen),
              _buildStatItem('Due Date', '14 Aug, 2026', Colors.orange),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.06), height: 24),
          Row(
            children: [
              _buildStatItem('Fines', '₹0', Colors.red, subtitle: '0 days overdue'),
              _buildStatItem('E-Bill', '₹650', Colors.blue),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.06), height: 24),
          Row(
            children: [
              _buildStatItem('Maintenance Fee', '₹500', Colors.purple),
              _buildStatItem('Total Bill', '₹9,650', Colors.white, isTotal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color, {
    String? subtitle,
    bool isTotal = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isTotal ? kLivinkeyGreen : color,
                fontSize: isTotal ? 21 : 16.5,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    switch (_selectedPaymentMethod) {
      case 0:
        return _buildQRCard(
          title: 'Pay Online',
          subtitle: 'Scan QR to pay via UPI',
          qrColor: kLivinkeyGreen,
        );
      case 1:
        return _buildCashPaymentCard();
      case 2:
        return _buildQRCard(
          title: 'Partial Payment',
          subtitle: 'Scan QR to pay partial amount',
          qrColor: Colors.orange,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQRCard({
    required String title,
    required String subtitle,
    required Color qrColor,
  }) {
    return GestureDetector(
      onTap: () => _showQRPreview(qrColor),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              qrColor.withOpacity(0.1),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: qrColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: qrColor.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: qrColor,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pay by Cash',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact the owner to arrange cash payment',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _launchWhatsApp(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '98783 83497',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Meter Reading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'August 2026',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showMeterPreview(),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1563206767-5b18f218e8de?w=400&h=300&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            SnackbarHelper.show(context, 'Meter image downloaded');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Download',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitProofButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => _showSubmitProofDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: kLivinkeyGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'Submit Payment Proof',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRPreview(Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: color,
                    size: 100,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan to Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SnackbarHelper.show(context, 'QR Code downloaded');
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                  label: const Text(
                    'Download QR',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMeterPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Electricity Meter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1563206767-5b18f218e8de?w=600&h=400&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SnackbarHelper.show(context, 'Meter image downloaded');
                      },
                      icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                      label: const Text(
                        'Download',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLivinkeyGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitProofDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: kLivinkeyGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Submit Payment Proof',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmittingProof ? null : () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _transactionIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Transaction ID',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kLivinkeyGreen,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.receipt_rounded,
                        color: Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (₹)',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kLivinkeyGreen,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.currency_rupee_rounded,
                        color: Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_rounded,
                          color: kLivinkeyGreen.withOpacity(0.6),
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload payment screenshot',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'PNG, JPG up to 5MB',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmittingProof ? null : () {
                            _transactionIdController.clear();
                            _amountController.clear();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmittingProof ? null : () {
                            setDialogState(() => _isSubmittingProof = true);
                            Future.delayed(const Duration(milliseconds: 1200), () {
                              if (context.mounted) {
                                setDialogState(() => _isSubmittingProof = false);
                                Navigator.pop(context);
                                _transactionIdController.clear();
                                _amountController.clear();
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Payment proof submitted successfully!',
                                );
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLivinkeyGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: _isSubmittingProof
                                ? const SizedBox(
                                    key: ValueKey('spinner'),
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Row(
                                    key: ValueKey('label'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Submit Proof',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
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
                    'Payment History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '5 payments',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: 5,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withOpacity(0.05),
                    height: 1,
                  ),
                  itemBuilder: (context, index) => _buildHistoryItem(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(int index) {
    final payments = [
      {
        'amount': '₹8,500',
        'date': '14 Jul, 2026',
        'id': 'TXN-2026-07-14',
        'mode': 'UPI',
        'status': 'paid',
        'statusLabel': 'Paid',
      },
      {
        'amount': '₹8,500',
        'date': '14 Jun, 2026',
        'id': 'TXN-2026-06-14',
        'mode': 'Cash',
        'status': 'paid',
        'statusLabel': 'Paid',
      },
      {
        'amount': '₹8,500',
        'date': '14 May, 2026',
        'id': 'TXN-2026-05-14',
        'mode': 'UPI',
        'status': 'verifying',
        'statusLabel': 'Verifying...',
      },
      {
        'amount': '₹8,500',
        'date': '14 Apr, 2026',
        'id': 'TXN-2026-04-14',
        'mode': 'Bank Transfer',
        'status': 'paid',
        'statusLabel': 'Paid',
      },
      {
        'amount': '₹8,500',
        'date': '14 Mar, 2026',
        'id': 'TXN-2026-03-14',
        'mode': 'UPI',
        'status': 'verifying',
        'statusLabel': 'Verifying...',
      },
    ];

    final payment = payments[index % payments.length];
    final isPaid = payment['status'] == 'paid';
    final statusColor = isPaid ? kLivinkeyGreen : Colors.orange;
    final statusBgColor = isPaid 
        ? kLivinkeyGreen.withOpacity(0.15) 
        : Colors.orange.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: kLivinkeyGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_rounded,
              color: kLivinkeyGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      payment['amount']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment['statusLabel']!,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment['date']} • ${payment['mode']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 12,
                  ),
                ),
                Text(
                  payment['id']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.22),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showReceiptPreview(context, payment),
            style: ElevatedButton.styleFrom(
              backgroundColor: kLivinkeyGreen,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(80, 32),
            ),
            child: const Text(
              'Receipt',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreview(BuildContext context, Map<String, String> payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        child: Container(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Payment Receipt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kLivinkeyGreen.withOpacity(0.1),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kLivinkeyGreen.withOpacity(0.14),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Amount', payment['amount']!),
                    _buildReceiptRow('Date', payment['date']!),
                    _buildReceiptRow('Transaction ID', payment['id']!),
                    _buildReceiptRow('Payment Mode', payment['mode']!),
                    _buildReceiptRow('Status', payment['statusLabel']!, isStatus: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SnackbarHelper.show(context, 'Receipt downloaded');
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                  label: const Text(
                    'Download Receipt',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isStatus ? kLivinkeyGreen : Colors.white,
              fontSize: 13,
              fontWeight: isStatus ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    try {
      if (await canLaunchUrl(Uri.parse(kWhatsAppUrl))) {
        await launchUrl(Uri.parse(kWhatsAppUrl), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}