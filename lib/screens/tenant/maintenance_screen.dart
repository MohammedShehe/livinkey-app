// lib/screens/tenant/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/tenant/maintenance_item.dart';
import '../../widgets/common/snackbar_helper.dart';
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

  final List<Map<String, String>> _requests = [
    {'type': 'Plumbing', 'date': '12 Aug, 2026', 'time': '10:00 AM', 'desc': 'Leaking pipe in kitchen', 'status': 'Pending'},
    {'type': 'Electrical', 'date': '10 Aug, 2026', 'time': '2:30 PM', 'desc': 'Fan not working', 'status': 'In Progress'},
    {'type': 'AC Service', 'date': '08 Aug, 2026', 'time': '11:00 AM', 'desc': 'Annual AC maintenance', 'status': 'Solved'},
    {'type': 'Painting', 'date': '05 Aug, 2026', 'time': '9:00 AM', 'desc': 'Wall paint in bedroom', 'status': 'Pending'},
    {'type': 'Furniture', 'date': '01 Aug, 2026', 'time': '4:00 PM', 'desc': 'Broken chair in living room', 'status': 'Solved'},
  ];

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

  List<Map<String, String>> get _filteredRequests {
    if (_selectedFilter == 'All') return _requests;
    return _requests.where((r) => r['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double bottomNavHeight = 76.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

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
            'Maintenance',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
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
                    32 + bottomNavHeight + bottomSafeArea + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildMaintenanceStat('Pending', 3, Colors.red),
                          const SizedBox(width: 10),
                          _buildMaintenanceStat('In Progress', 2, Colors.orange),
                          const SizedBox(width: 10),
                          _buildMaintenanceStat('Solved', 5, kLivinkeyGreen),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSectionHeader('Requests'),
                      const SizedBox(height: 14),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('In Progress'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Solved'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredRequests.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withOpacity(0.05),
                          height: 12,
                        ),
                        itemBuilder: (context, index) {
                          return MaintenanceItem(request: _filteredRequests[index]);
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showSubmitRequest(context),
                          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                          label: const Text(
                            'Submit Request',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLivinkeyGreen,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shadowColor: kLivinkeyGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ).copyWith(
                            elevation: WidgetStateProperty.all(0),
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

  Widget _buildMaintenanceStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.14),
              color.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
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
        setState(() {
          _selectedFilter = label;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [kLivinkeyGreen, Color(0xFF66BB6A)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? kLivinkeyGreen
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kLivinkeyGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.65),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showSubmitRequest(BuildContext context) {
    final TextEditingController roomController = TextEditingController(text: '101');
    final TextEditingController typeController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    File? _selectedImage;
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
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
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Submit Maintenance Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          _buildFormField(
                            label: 'Room No',
                            controller: roomController,
                            enabled: false,
                            icon: Icons.meeting_room_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            label: 'Type of Issue',
                            controller: typeController,
                            hint: 'e.g., Plumbing, Electrical, AC',
                            icon: Icons.build_rounded,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            label: 'Description',
                            controller: descController,
                            hint: 'Describe the issue in detail',
                            icon: Icons.description_rounded,
                            maxLines: 3,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 16),

                          _buildImageUploadSection(
                            selectedImage: _selectedImage,
                            onImageSelected: (File? image) {
                              setState(() {
                                _selectedImage = image;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      setState(() => _isSubmitting = true);

                                      await Future.delayed(const Duration(seconds: 2));

                                      if (!context.mounted) return;

                                      Navigator.pop(context);
                                      SnackbarHelper.show(
                                        context,
                                        'Request submitted successfully!${_selectedImage != null ? ' 📸' : ''}',
                                        icon: Icons.check_circle_rounded,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLivinkeyGreen,
                                disabledBackgroundColor: kLivinkeyGreen.withOpacity(0.6),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Text(
                                        'Submit Request',
                                        key: ValueKey('label'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
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

  Widget _buildImageUploadSection({
    required File? selectedImage,
    required Function(File?) onImageSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kLivinkeyWhite.withOpacity(0.05),
            kLivinkeyWhite.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kLivinkeyWhite.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.image_rounded,
                  color: kLivinkeyGreen.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attach Image (Optional)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        onImageSelected(null);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
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
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (pickedFile != null) {
                        onImageSelected(File(pickedFile.path));
                      }
                    },
                    icon: Icon(
                      Icons.photo_library_rounded,
                      color: kLivinkeyGreen,
                      size: 20,
                    ),
                    label: Text(
                      'Gallery',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: kLivinkeyGreen.withOpacity(0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (pickedFile != null) {
                        onImageSelected(File(pickedFile.path));
                      }
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: kLivinkeyGreen,
                      size: 20,
                    ),
                    label: Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: kLivinkeyGreen.withOpacity(0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kLivinkeyWhite.withOpacity(0.05),
            kLivinkeyWhite.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kLivinkeyWhite.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.2),
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: kLivinkeyGreen.withOpacity(0.8),
                  size: 20,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: kLivinkeyGreen.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}