import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/tenant/payment_chip.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/auth_models.dart';
import '../../models/bill_model.dart';
import '../common/notification_screen.dart';
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
  bool _isLoading = true;

  final ApiService _api = ApiService();

  BillModel? _currentBill;
  PaymentHistory? _paymentHistory;

  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmittingProof = false;
  String? _paymentScreenshotPath;

  bool _isDownloadingReceipt = false;
  int? _downloadingReceiptId;

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
      _loadPaymentData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transactionIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final billResponse = await _api.getCurrentBill();
      if (billResponse['success'] && billResponse['data'] != null) {
        final billData = billResponse['data']['bill'];
        if (billData != null) {
          _currentBill = BillModel.fromJson(billData);
        }
      }

      final historyResponse = await _api.getPaymentHistory();
      if (historyResponse['success'] && historyResponse['data'] != null) {
        _paymentHistory = PaymentHistory.fromJson(historyResponse['data']);
      }

      if (mounted) {
        await NotificationService().refresh(isTenant: true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load payment data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openDrawer() {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    state?.openDrawer();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await _loadPaymentData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Payments refreshed');
    }
  }

  double _getTotalDue() {
    if (_currentBill == null) return 0;
    final total = _currentBill!.totalAmount + _currentBill!.fineAmount - _currentBill!.paidAmount;
    return total > 0 ? total : 0;
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM, yyyy').format(date);
  }

  Future<void> _pickPaymentScreenshot() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          setState(() {
            _paymentScreenshotPath = 'data:image/jpeg;base64,$base64Image';
          });
        } else {
          setState(() {
            _paymentScreenshotPath = pickedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to pick image');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    const double navBarClearance = 96.0;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen)),
              const SizedBox(height: 16),
              Text('Loading payments...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
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
        title: const Text('Payments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.8), size: 22),
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
                padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + navBarClearance + bottomSafeArea),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    _buildPaymentStats(),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
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

                    if (_currentBill?.hasMeterImages == true)
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (_currentBill!.meterImageUrls.length > 1)
                                    ? 'Electricity Meter Images'
                                    : 'Electricity Meter',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildMeterCard(),
                          const SizedBox(height: 20),
                        ],
                      ),

                    _buildSubmitProofButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStats() {
    final totalDue = _getTotalDue();
    final isPaid = _currentBill?.status == 'paid';
    final isPartiallyPaid = _currentBill?.status == 'partially_paid';
    final hasBill = _currentBill != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kLivinkeyGreen.withOpacity(0.1), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLivinkeyGreen.withOpacity(0.14)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem('Total Due', totalDue > 0 ? fmtINR(totalDue) : '₹0', totalDue > 0 ? Colors.red : kLivinkeyGreen),
              _buildStatItem('Status', _currentBill?.status ?? 'No Bill', 
                isPaid ? kLivinkeyGreen : (isPartiallyPaid ? Colors.orange : Colors.red)),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.06), height: 24),
          Row(
            children: [
              _buildStatItem('Valid Until', _currentBill != null ? _getFormattedDate(_currentBill!.validUntil) : 'N/A', Colors.blue),
              _buildStatItem('Overdue', _currentBill?.isOverdue == true ? 'Yes' : 'No', _currentBill?.isOverdue == true ? Colors.red : kLivinkeyGreen),
            ],
          ),
          if (hasBill && (_currentBill!.billingMonth != null && _currentBill!.billingMonth!.isNotEmpty)) ...[
            Divider(color: Colors.white.withOpacity(0.06), height: 24),
            Row(
              children: [
                _buildStatItem('Billing Month', _currentBill!.billingMonth!, Colors.teal),
                _buildStatItem(
                  'Period',
                  (_currentBill!.periodFrom != null && _currentBill!.periodTill != null)
                      ? '${_getFormattedDate(_currentBill!.periodFrom!)} – ${_getFormattedDate(_currentBill!.periodTill!)}'
                      : 'N/A',
                  Colors.tealAccent,
                ),
              ],
            ),
          ],
          if (hasBill) Divider(color: Colors.white.withOpacity(0.06), height: 24),
          if (hasBill)
            Column(
              children: [
                Row(
                  children: [
                    _buildStatItem('Rent', fmtINR(_currentBill!.rentAmount), Colors.white),
                    _buildStatItem('Electricity', fmtINR(_currentBill!.electricityAmount), Colors.yellow),
                  ],
                ),
                if (_currentBill!.maintenanceAmount > 0 || _currentBill!.otherCharges > 0)
                  Row(
                    children: [
                      if (_currentBill!.maintenanceAmount > 0)
                        _buildStatItem('Maintenance', fmtINR(_currentBill!.maintenanceAmount), Colors.cyan),
                      if (_currentBill!.otherCharges > 0)
                        _buildStatItem('Other', fmtINR(_currentBill!.otherCharges), Colors.purple),
                    ],
                  ),
                if (_currentBill!.fineAmount > 0)
                  Row(
                    children: [
                      _buildStatItem('Late Fee', fmtINR(_currentBill!.fineAmount), Colors.red),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    switch (_selectedPaymentMethod) {
      case 0:
        final qrUrl = _currentBill?.adminQr ?? _currentBill?.paymentQr;
        final isAdminQr = _currentBill?.adminQr != null;
        
        return _buildQRCard(
          title: isAdminQr ? 'Admin Payment QR' : 'Pay Online',
          subtitle: isAdminQr 
              ? 'QR code provided by admin' 
              : 'Scan QR to pay via UPI',
          qrColor: kLivinkeyGreen,
          qrUrl: qrUrl,
          amount: _getTotalDue(),
          isPartial: false,
        );
        
      case 1:
        return _buildCashPaymentCard();
        
      case 2:
        final partialAmount = _getTotalDue() * 0.5;
        
        return _buildQRCard(
          title: 'Partial Payment (50%)',
          subtitle: 'Scan QR to pay partial amount',
          qrColor: Colors.orange,
          qrUrl: _currentBill?.partialPaymentQr,
          amount: partialAmount,
          isPartial: true,
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQRCard({
    required String title,
    required String subtitle,
    required Color qrColor,
    String? qrUrl,
    double? amount,
    bool isPartial = false,
  }) {
    final displayAmount = amount ?? _getTotalDue();

    if (qrUrl == null || qrUrl.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [qrColor.withOpacity(0.08), Colors.white.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: qrColor.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: qrColor.withOpacity(0.4), size: 64),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'No QR code available yet. Please contact admin.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showQRPreview(qrColor, qrUrl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [qrColor.withOpacity(0.1), Colors.white.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: qrColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: qrColor.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  qrUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.qr_code_scanner_rounded, color: qrColor, size: 60),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            if (displayAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isPartial 
                      ? 'Amount: ${fmtINR(displayAmount)} (50%)'
                      : 'Amount: ${fmtINR(displayAmount)}',
                  style: TextStyle(color: qrColor, fontSize: 16, fontWeight: FontWeight.w700),
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
          colors: [Colors.green.withOpacity(0.1), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.attach_money_rounded, color: Colors.green, size: 48),
          ),
          const SizedBox(height: 14),
          const Text('Pay by Cash', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Contact the owner to arrange cash payment',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
                  SizedBox(width: 8),
                  Text('98783 83497', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard() {
    final urls = _currentBill?.meterImageUrls ?? [];
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.withOpacity(0.08), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
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
                child: const Icon(Icons.electric_bolt_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urls.length > 1 ? 'Meter Readings' : 'Current Meter Reading',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      urls.length > 1
                          ? 'Tap an image to view full size'
                          : 'Tap to view full size',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (urls.length == 1)
            GestureDetector(
              onTap: () => _showMeterFullScreen(urls[0], label: 'Meter Reading'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    urls[0],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < urls.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMeterFullScreen(urls[i], label: 'Meter Image ${i + 1}'),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                urls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white10,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Image ${i + 1}',
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showMeterFullScreen(String url, {String label = 'Meter Reading'}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitProofButton() {
    final isPaid = _currentBill?.status == 'paid';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: isPaid ? null : () => _showSubmitProofDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPaid ? Colors.grey : kLivinkeyGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded, size: 20, color: isPaid ? Colors.grey : Colors.black),
            const SizedBox(width: 10),
            Text(
              isPaid ? 'Bill Already Paid' : 'Submit Payment Proof',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isPaid ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRPreview(Color color, String qrUrl) {
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
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.qr_code_scanner_rounded, color: color, size: 100),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Scan to Pay', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => SnackbarHelper.show(context, 'QR Code ready'),
                  icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                  label: const Text('View QR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMeterPreview() {
    final urls = _currentBill?.meterImageUrls ?? [];
    if (urls.isEmpty) return;

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
              Text(
                urls.length > 1 ? 'Electricity Meter Images' : 'Electricity Meter',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...urls.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(bottom: e.key < urls.length - 1 ? 12 : 0),
                  child: GestureDetector(
                    onTap: () => _showMeterFullScreen(e.value, label: 'Meter Image ${e.key + 1}'),
                    child: Container(
                      width: double.infinity,
                      height: urls.length > 1 ? 180 : 280,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        image: DecorationImage(
                          image: NetworkImage(e.value),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitProofDialog() {
    _transactionIdController.clear();
    _amountController.clear();
    setState(() => _paymentScreenshotPath = null);

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
                        child: const Icon(Icons.upload_file_rounded, color: kLivinkeyGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Submit Payment Proof',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
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
                          child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _transactionIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Transaction ID *',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kLivinkeyGreen),
                      ),
                      prefixIcon: Icon(Icons.receipt_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (₹) *',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kLivinkeyGreen),
                      ),
                      prefixIcon: Icon(Icons.currency_rupee_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Screenshot Upload
                  GestureDetector(
                    onTap: _pickPaymentScreenshot,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentScreenshotPath != null ? kLivinkeyGreen : Colors.white.withOpacity(0.1),
                          width: _paymentScreenshotPath != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_paymentScreenshotPath != null)
                            _buildScreenshotPreview(_paymentScreenshotPath!)
                          else ...[
                            Icon(Icons.image_rounded, color: kLivinkeyGreen.withOpacity(0.6), size: 32),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to upload payment screenshot',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                            Text(
                              'PNG, JPG up to 5MB',
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_paymentScreenshotPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: kLivinkeyGreen, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Screenshot attached',
                            style: TextStyle(color: kLivinkeyGreen.withOpacity(0.7), fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setDialogState(() => _paymentScreenshotPath = null),
                            child: Icon(Icons.close_rounded, color: Colors.red.withOpacity(0.7), size: 16),
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
                            setState(() => _paymentScreenshotPath = null);
                            Navigator.pop(context);
                          },
                          child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmittingProof ? null : () async {
                            final transactionId = _transactionIdController.text.trim();
                            final amount = double.tryParse(_amountController.text.trim());

                            if (transactionId.isEmpty) {
                              SnackbarHelper.showError(context, 'Please enter Transaction ID');
                              return;
                            }

                            if (amount == null || amount <= 0) {
                              SnackbarHelper.showError(context, 'Please enter a valid amount');
                              return;
                            }

                            if (_paymentScreenshotPath == null || _paymentScreenshotPath!.isEmpty) {
                              SnackbarHelper.showError(context, 'Please upload a payment screenshot');
                              return;
                            }

                            setDialogState(() => _isSubmittingProof = true);

                            try {
                              final response = await _api.submitPaymentProof(
                                billId: _currentBill?.id ?? 0,
                                transactionId: transactionId,
                                amountPaid: amount,
                                paymentScreenshot: _paymentScreenshotPath!,
                              );

                              if (!context.mounted) return;

                              if (response['success'] == true) {
                                Navigator.pop(context);
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Payment proof submitted successfully!',
                                );
                                await _loadPaymentData();
                              } else {
                                SnackbarHelper.showError(
                                  context,
                                  response['message'] ?? 'Failed to submit proof',
                                );
                              }
                            } catch (e) {
                              SnackbarHelper.showError(
                                context,
                                'An error occurred. Please try again.',
                              );
                            } finally {
                              if (mounted) {
                                setDialogState(() => _isSubmittingProof = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLivinkeyGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: _isSubmittingProof
                                ? const SizedBox(
                                    key: ValueKey('spinner'),
                                    height: 20,
                                    width: 20,
                                    child: LoadingIndicator(size: 20, color: Colors.black),
                                  )
                                : const Row(
                                    key: ValueKey('label'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Submit Proof', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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

  Widget _buildScreenshotPreview(String path) {
    if (kIsWeb && path.startsWith('data:image')) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kLivinkeyGreen.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(path.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: kLivinkeyGreen.withOpacity(0.1),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
                      SizedBox(height: 4),
                      Text('Preview not available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (!kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              color: Colors.white.withOpacity(0.05),
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 120,
        width: double.infinity,
        color: kLivinkeyGreen.withOpacity(0.1),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: kLivinkeyGreen, size: 32),
              SizedBox(height: 4),
              Text('Image selected', style: TextStyle(color: kLivinkeyGreen, fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  // ============================================================
  // FIXED: showPaymentHistory with correct amounts and rejection reason
  // ============================================================
  void _showPaymentHistory(BuildContext context) {
    List<PaymentRecord> allPayments = [];
    
    if (_paymentHistory != null) {
      // Add online payments
      for (final p in _paymentHistory!.onlinePayments) {
        allPayments.add(PaymentRecord(
          id: p.id,
          billId: p.billId,
          amount: p.amount,
          paymentMethod: p.paymentMethod,
          transactionId: p.transactionId,
          status: p.status,
          createdAt: p.createdAt,
          type: 'online',
          billTotal: p.billTotal,
          adminNotes: p.adminNotes,
        ));
      }
      
      // Add cash payments
      for (final p in _paymentHistory!.cashPayments) {
        allPayments.add(PaymentRecord(
          id: p.id,
          billId: p.billId,
          amount: p.amount,
          paymentMethod: 'cash',
          transactionId: p.transactionId,
          status: p.status,
          createdAt: p.createdAt,
          type: 'cash',
          billTotal: p.billTotal,
          adminNotes: p.adminNotes,
        ));
      }
      
      // Add payment proofs
      for (final p in _paymentHistory!.paymentProofs) {
        allPayments.add(PaymentRecord(
          id: p.id,
          billId: p.billId,
          amount: p.amount,
          paymentMethod: 'proof',
          transactionId: p.transactionId,
          status: p.status,
          createdAt: p.createdAt,
          type: 'proof',
          billTotal: p.billTotal,
          adminNotes: p.adminNotes,
        ));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                    decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Payment History', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    '${allPayments.length} payments',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: allPayments.isEmpty
                    ? Center(
                        child: Text(
                          'No payment history',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: allPayments.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                        itemBuilder: (context, index) {
                          final payment = allPayments[index];
                          final isPaid = payment.status == 'verified' || payment.status == 'success' || payment.status == 'paid';
                          final isRejected = payment.status == 'rejected';
                          final isPending = payment.status == 'pending';
                          final statusColor = isPaid ? kLivinkeyGreen : (isRejected ? Colors.red : Colors.orange);
                          
                          String statusLabel = payment.status;
                          if (statusLabel == 'verified') statusLabel = 'Verified';
                          else if (statusLabel == 'success') statusLabel = 'Success';
                          else if (statusLabel == 'paid') statusLabel = 'Paid';
                          else if (statusLabel == 'rejected') statusLabel = 'Rejected';
                          else if (statusLabel == 'pending') statusLabel = 'Pending';

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check_circle_rounded : (isRejected ? Icons.cancel_rounded : Icons.pending_rounded),
                                    color: statusColor,
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
                                            fmtINR(payment.amount),
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLabel.toUpperCase(),
                                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormat('dd MMM, yyyy').format(payment.createdAt)} • ${payment.paymentMethod}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 12),
                                      ),
                                      if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
                                        Text(
                                          payment.transactionId!,
                                          style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 10),
                                        ),
                                      // ============================================================
                                      // FIXED: Show rejection reason when status is rejected
                                      // ============================================================
                                      if (isRejected && payment.adminNotes != null && payment.adminNotes!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.info_outline, color: Colors.red, size: 14),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Reason: ${payment.adminNotes}',
                                                  style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                ElevatedButton(
                  onPressed: _isDownloadingReceipt && _downloadingReceiptId == payment.id
                      ? null
                      : () => _handleDownloadReceipt(context, payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(80, 32),
                  ),
                  child: _isDownloadingReceipt && _downloadingReceiptId == payment.id
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text('Receipt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIXED: Receipt download with token as query parameter
  // The backend authMiddleware supports token from query params
  // ============================================================
  Future<void> _handleDownloadReceipt(BuildContext context, PaymentRecord payment) async {
  if (_isDownloadingReceipt) return;
  
  setState(() {
    _isDownloadingReceipt = true;
    _downloadingReceiptId = payment.id;
  });

  try {
    String type = 'online';
    if (payment.type == 'cash' || payment.paymentMethod == 'cash') {
      type = 'cash';
    } else if (payment.type == 'proof' || payment.paymentMethod == 'proof') {
      type = 'proof';
    }

    final token = await _api.getToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    // ============================================================
    // FIXED: Use TENANT receipt endpoint, not admin endpoint
    // The tenant routes use tenantAuthMiddleware which accepts tenant tokens
    // ============================================================
    final encodedToken = Uri.encodeComponent(token);
    final receiptUrl = '${kApiBaseUrl}/tenant-payments/receipt/$type/${payment.id}/download?token=$encodedToken';
    

    final uri = Uri.parse(receiptUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      SnackbarHelper.showSuccess(context, 'Receipt opened successfully');
    } else {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        } else {
          SnackbarHelper.showError(context, 'Could not open receipt. Please check your internet connection.');
        }
      } catch (e) {
        SnackbarHelper.showError(context, 'Could not open receipt: ${e.toString()}');
      }
    }
  } catch (e) {
    SnackbarHelper.showError(context, 'Failed to open receipt');
  } finally {
    if (mounted) {
      setState(() {
        _isDownloadingReceipt = false;
        _downloadingReceiptId = null;
      });
    }
  }
}

  void _showReceiptPreview(BuildContext context, PaymentRecord payment) {
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
              const Text('Payment Receipt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kLivinkeyGreen.withOpacity(0.1), Colors.white.withOpacity(0.02)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLivinkeyGreen.withOpacity(0.14)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Amount', fmtINR(payment.amount)),
                    _buildReceiptRow('Date', DateFormat('dd MMM, yyyy').format(payment.createdAt)),
                    if (payment.transactionId != null) _buildReceiptRow('Transaction ID', payment.transactionId!),
                    _buildReceiptRow('Payment Mode', payment.paymentMethod),
                    _buildReceiptRow('Status', payment.status, isStatus: true),
                    if (payment.status == 'rejected' && payment.adminNotes != null && payment.adminNotes!.isNotEmpty)
                      _buildReceiptRow('Rejection Reason', payment.adminNotes!, isStatus: true, isRejectionReason: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleDownloadReceipt(context, payment),
                  icon: _isDownloadingReceipt && _downloadingReceiptId == payment.id
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                  label: Text(
                    _isDownloadingReceipt && _downloadingReceiptId == payment.id
                        ? 'Downloading...'
                        : 'Download Receipt',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIXED: _buildReceiptRow - NO icon or child parameters
  // ============================================================
  Widget _buildReceiptRow(String label, String value, {bool isStatus = false, bool isRejectionReason = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isStatus 
                  ? (value.toLowerCase().contains('rejected') ? Colors.red : kLivinkeyGreen) 
                  : (isRejectionReason ? Colors.red : Colors.white),
              fontSize: 13,
              fontWeight: isStatus || isRejectionReason ? FontWeight.w700 : FontWeight.w600,
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

String fmtINR(double amount) {
  return '₹${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}';
}