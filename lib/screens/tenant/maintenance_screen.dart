// lib/screens/tenant/maintenance_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';
import '../common/notification_screen.dart';
import 'tenant_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  bool _isLoading = true;

  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic> _stats = {};

  int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    if (value is bool) return value ? 1 : 0;
    return 0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadMaintenanceData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final requestsRes = await _api.getMyMaintenanceRequests();
      if (requestsRes['success'] && requestsRes['data'] != null) {
        final data = requestsRes['data'];
        if (data is List) {
          _requests = List<Map<String, dynamic>>.from(data);
        }
      }

      final statsRes = await _api.getMaintenanceStats();
      if (statsRes['success'] && statsRes['data'] != null) {
        _stats = statsRes['data'];
      }

      if (mounted) {
        await NotificationService().refresh(isTenant: true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load maintenance data');
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
    await _loadMaintenanceData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Maintenance requests refreshed');
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

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'All') return _requests;
    return _requests.where((r) => r['status'] == _selectedFilter).toList();
  }

  int get _pendingCount => _parseIntSafe(_stats['pending']);
  int get _inProgressCount => _parseIntSafe(_stats['in_progress']);
  int get _completedCount => _parseIntSafe(_stats['completed']);

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
              Text('Loading maintenance...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
          title: const Text('Maintenance', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
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

                      Row(
                        children: [
                          _buildMaintenanceStat('Pending', _pendingCount, Colors.red),
                          const SizedBox(width: 10),
                          _buildMaintenanceStat('In Progress', _inProgressCount, Colors.orange),
                          const SizedBox(width: 10),
                          _buildMaintenanceStat('Completed', _completedCount, kLivinkeyGreen),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Requests', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text(
                            '${_filteredRequests.length}',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('in_progress'),
                            const SizedBox(width: 8),
                            _buildFilterChip('completed'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      _filteredRequests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(Icons.build_rounded, color: Colors.white.withOpacity(0.1), size: 64),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No maintenance requests',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap "Submit Request" to create one',
                                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredRequests.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 12,
                              ),
                              itemBuilder: (context, index) {
                                return _buildMaintenanceItem(_filteredRequests[index]);
                              },
                            ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showSubmitRequest(),
                          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                          label: const Text(
                            'Submit Request',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLivinkeyGreen,
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

  Widget _buildMaintenanceStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.14), color.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18), width: 1),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [kLivinkeyGreen, Color(0xFF66BB6A)])
              : LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kLivinkeyGreen : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: kLivinkeyGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Text(
          label == 'All' ? 'All' : label.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.65),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final statusColor = status == 'pending' ? Colors.red : status == 'in_progress' ? Colors.orange : kLivinkeyGreen;
    final statusLabel = status == 'pending' ? 'Pending' : status == 'in_progress' ? 'In Progress' : 'Completed';

    final issueType = request['issue_type'] ?? 'Other';
    final iconMap = {
      'Electrician': Icons.electrical_services_rounded,
      'Plumber': Icons.plumbing_rounded,
      'Carpenter': Icons.handyman_rounded,
      'RO': Icons.water_drop_rounded,
      'AC': Icons.ac_unit_rounded,
      'WiFi': Icons.wifi_rounded,
      'Cleaning': Icons.cleaning_services_rounded,
      'C-Form': Icons.description_rounded,
      'Check-out': Icons.logout_rounded,
      'Others': Icons.build_rounded,
    };
    final icon = iconMap[issueType] ?? Icons.build_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor.withOpacity(0.06), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      issueType,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Text(
                  request['service_date'] != null
                      ? '${_formatDate(request['service_date'])} • ${request['free_time'] ?? 'Any time'}'
                      : 'No date set',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
                if (request['description'] != null)
                  Text(
                    request['description'],
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (request['image_url'] != null)
            GestureDetector(
              onTap: () => _showImagePreview(request['image_url']),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(request['image_url']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_monthName(date.month)}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    height: 300,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.6))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIXED: Submit Request with cross-platform image handling
  // ============================================================
  void _showSubmitRequest() {
    final TextEditingController descController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String? _selectedImagePath;
    bool _isSubmitting = false;

    final List<String> issueTypes = ['Electrician', 'Plumber', 'Carpenter', 'RO', 'AC', 'WiFi', 'Cleaning', 'C-Form', 'Check-out', 'Others'];
    String selectedType = issueTypes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
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
                        height: 18,
                        decoration: BoxDecoration(color: kLivinkeyGreen, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Submit Maintenance Request',
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              dropdownColor: const Color(0xFF1A1A1A),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Issue Type',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.build_rounded, color: kLivinkeyGreen.withOpacity(0.8), size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: kLivinkeyGreen.withOpacity(0.4)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: issueTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setModalState(() => selectedType = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: descController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.description_rounded, color: kLivinkeyGreen.withOpacity(0.8), size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: kLivinkeyGreen.withOpacity(0.4)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: dateController,
                              style: const TextStyle(color: Colors.white),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: kLivinkeyGreen,
                                          onPrimary: Colors.black,
                                          surface: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setModalState(() {
                                    dateController.text =
                                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Service Date *',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.calendar_today_rounded, color: kLivinkeyGreen.withOpacity(0.8), size: 20),
                                suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Colors.white.withOpacity(0.5)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: kLivinkeyGreen.withOpacity(0.4)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: timeController,
                              style: const TextStyle(color: Colors.white),
                              readOnly: true,
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: kLivinkeyGreen,
                                          onPrimary: Colors.black,
                                          surface: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setModalState(() {
                                    timeController.text = time.format(context);
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Preferred Time (Optional)',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.access_time_rounded, color: kLivinkeyGreen.withOpacity(0.8), size: 20),
                                suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Colors.white.withOpacity(0.5)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: kLivinkeyGreen.withOpacity(0.4)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ============================================================
                          // FIXED: Image Upload with cross-platform support
                          // ============================================================
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.image_rounded, color: kLivinkeyGreen.withOpacity(0.8), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Attach Image (Optional)',
                                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedImagePath != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Stack(
                                      children: [
                                        _buildImagePreview(_selectedImagePath!),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setModalState(() => _selectedImagePath = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final picker = ImagePicker();
                                            final XFile? pickedFile = await picker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 80,
                                              maxWidth: 1024,
                                              maxHeight: 1024,
                                            );
                                            if (pickedFile != null) {
                                              String fileData;
                                              if (kIsWeb) {
                                                final bytes = await pickedFile.readAsBytes();
                                                final base64Image = base64Encode(bytes);
                                                fileData = 'data:image/jpeg;base64,$base64Image';
                                              } else {
                                                fileData = pickedFile.path;
                                              }
                                              setModalState(() => _selectedImagePath = fileData);
                                            }
                                          },
                                          icon: Icon(Icons.photo_library_rounded, color: kLivinkeyGreen, size: 20),
                                          label: Text('Gallery', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: kLivinkeyGreen.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final picker = ImagePicker();
                                            final XFile? pickedFile = await picker.pickImage(
                                              source: ImageSource.camera,
                                              imageQuality: 80,
                                              maxWidth: 1024,
                                              maxHeight: 1024,
                                            );
                                            if (pickedFile != null) {
                                              String fileData;
                                              if (kIsWeb) {
                                                final bytes = await pickedFile.readAsBytes();
                                                final base64Image = base64Encode(bytes);
                                                fileData = 'data:image/jpeg;base64,$base64Image';
                                              } else {
                                                fileData = pickedFile.path;
                                              }
                                              setModalState(() => _selectedImagePath = fileData);
                                            }
                                          },
                                          icon: Icon(Icons.camera_alt_rounded, color: kLivinkeyGreen, size: 20),
                                          label: Text('Camera', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: kLivinkeyGreen.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : () async {
                                final date = dateController.text.trim();
                                if (date.isEmpty) {
                                  SnackbarHelper.showError(context, 'Please select a service date');
                                  return;
                                }

                                setModalState(() => _isSubmitting = true);

                                try {
                                  final response = await _api.createMaintenanceRequest(
                                    issueType: selectedType,
                                    description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                                    serviceDate: date,
                                    freeTime: timeController.text.trim().isNotEmpty ? timeController.text.trim() : null,
                                    imagePath: _selectedImagePath,
                                  );

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (response['success']) {
                                    Navigator.pop(context);
                                    SnackbarHelper.showSuccess(context, 'Request submitted successfully!');
                                    await _loadMaintenanceData();
                                  } else {
                                    SnackbarHelper.showError(context, response['message'] ?? 'Failed to submit request');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackbarHelper.showError(context, 'An error occurred. Please try again.');
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setModalState(() => _isSubmitting = false);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLivinkeyGreen,
                                disabledBackgroundColor: kLivinkeyGreen.withOpacity(0.6),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(height: 22, width: 22, child: LoadingIndicator(size: 22, color: Colors.black))
                                  : const Text(
                                      'Submit Request',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
  // FIXED: Web-compatible image preview with base64 support
  // ============================================================
  Widget _buildImagePreview(String path) {
    if (kIsWeb && path.startsWith('data:image')) {
      // Web base64 image
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kLivinkeyGreen.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(path.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                color: Colors.white.withOpacity(0.05),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
                ),
              );
            },
          ),
        ),
      );
    } else if (!kIsWeb) {
      // Mobile/Desktop file
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              color: Colors.white.withOpacity(0.05),
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
              ),
            );
          },
        ),
      );
    } else {
      // Fallback
      return Container(
        height: 100,
        width: double.infinity,
        color: kLivinkeyGreen.withOpacity(0.1),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: kLivinkeyGreen, size: 24),
              SizedBox(height: 4),
              Text('Image selected', style: TextStyle(color: kLivinkeyGreen, fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }
}