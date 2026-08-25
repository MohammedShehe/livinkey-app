// lib/screens/guest/guest_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../models/pg_model.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';

class GuestFeedbackScreen extends StatefulWidget {
  const GuestFeedbackScreen({super.key});

  @override
  State<GuestFeedbackScreen> createState() => _GuestFeedbackScreenState();
}

class _GuestFeedbackScreenState extends State<GuestFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ApiService _api = ApiService();
  final List<PgModel> _pgs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  Map<String, dynamic>? _existingFeedback;

  int? _selectedPgId;
  String _selectedPgName = 'Select a PG';

  // Ratings (0-10)
  double _livingExperienceRating = 5.0;
  double _maintenanceHandlingRating = 5.0;
  double _communicationRating = 5.0;
  double _amenitiesRating = 5.0;
  double _technologyHandlingRating = 5.0;

  final TextEditingController _commentController = TextEditingController();

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
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIXED: Helper to safely parse rating from any type
  // ============================================================
  double _safeParseRating(dynamic value) {
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Check if guest has already submitted feedback
      final statusRes = await _api.checkGuestFeedbackStatus();
      if (statusRes['success'] && statusRes['has_submitted'] == true) {
        // Load existing feedback
        final feedbackRes = await _api.getMyGuestFeedback();
        if (feedbackRes['success'] && feedbackRes['data'] != null) {
          setState(() {
            _hasSubmitted = true;
            _existingFeedback = feedbackRes['data'];
            _isLoading = false;
          });
          return;
        }
      }

      // Load PGs for selection
      final pgsRes = await _api.getPublicPGs();
      if (pgsRes['success'] && pgsRes['data'] != null) {
        final data = pgsRes['data'];
        if (data is List) {
          _pgs.clear();
          _pgs.addAll(data.map((pg) => PgModel.fromJson(pg)).toList());
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load data');
        setState(() => _isLoading = false);
      }
    }
  }

  double _getOverallRating() {
    final sum = _livingExperienceRating +
        _maintenanceHandlingRating +
        _communicationRating +
        _amenitiesRating +
        _technologyHandlingRating;
    return (sum / 5);
  }

  Future<void> _submitFeedback() async {
    if (_selectedPgId == null) {
      SnackbarHelper.showError(context, 'Please select a PG');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _api.submitGuestFeedback({
        'pg_id': _selectedPgId,
        'living_experience_rating': _livingExperienceRating,
        'maintenance_handling_rating': _maintenanceHandlingRating,
        'communication_rating': _communicationRating,
        'amenities_rating': _amenitiesRating,
        'technology_handling_rating': _technologyHandlingRating,
        'comment': _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      });

      if (!mounted) return;

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'Thank you for your feedback! 🎉');
        Navigator.pop(context);
      } else {
        SnackbarHelper.showError(
          context,
          response['message'] ?? 'Failed to submit feedback',
        );
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // FIXED: _buildAlreadySubmitted with safe rating parsing
  // ============================================================
  Widget _buildAlreadySubmitted() {
    final f = _existingFeedback;
    final date = f?['created_at'] != null
        ? DateFormat('dd MMM, yyyy').format(DateTime.parse(f!['created_at']))
        : '';

    // FIXED: Use _safeParseRating instead of direct .toStringAsFixed()
    final overallRating = _safeParseRating(f?['overall_rating']);

    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        backgroundColor: kLivinkeyBlack,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: kLivinkeyGreen,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thank You!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have already submitted your feedback.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (date.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Submitted on $date',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // ============================================================
              // FIXED: Use overallRating (already parsed as double)
              // ============================================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kLivinkeyGreen.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kLivinkeyGreen.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rating: ${overallRating.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLivinkeyGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasSubmitted) {
      return _buildAlreadySubmitted();
    }

    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        backgroundColor: kLivinkeyBlack,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Give Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // PG Selector
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
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedPgId,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Select PG *',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.home_rounded,
                        color: kLivinkeyGreen.withOpacity(0.8),
                        size: 22,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: kLivinkeyGreen.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Select a PG...'),
                      ),
                      ..._pgs.map((pg) {
                        return DropdownMenuItem<int>(
                          value: pg.id,
                          child: Text(
                            '${pg.name} - ₹${pg.rent.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPgId = value;
                        if (value != null) {
                          final pg = _pgs.firstWhere((p) => p.id == value);
                          _selectedPgName = pg.name;
                        }
                      });
                      hapticFeedback();
                    },
                  ),
                ),

                const SizedBox(height: 24),

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
                            hapticFeedback();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Rate Your Experience',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildRatingSlider(
                  label: 'Living Experience',
                  value: _livingExperienceRating,
                  onChanged: (value) => setState(() => _livingExperienceRating = value),
                  icon: Icons.home_rounded,
                ),
                const SizedBox(height: 12),
                _buildRatingSlider(
                  label: 'Maintenance Handling',
                  value: _maintenanceHandlingRating,
                  onChanged: (value) => setState(() => _maintenanceHandlingRating = value),
                  icon: Icons.build_rounded,
                ),
                const SizedBox(height: 12),
                _buildRatingSlider(
                  label: 'Communication',
                  value: _communicationRating,
                  onChanged: (value) => setState(() => _communicationRating = value),
                  icon: Icons.chat_rounded,
                ),
                const SizedBox(height: 12),
                _buildRatingSlider(
                  label: 'Amenities',
                  value: _amenitiesRating,
                  onChanged: (value) => setState(() => _amenitiesRating = value),
                  icon: Icons.weekend_rounded,
                ),
                const SizedBox(height: 12),
                _buildRatingSlider(
                  label: 'Technology Handling',
                  value: _technologyHandlingRating,
                  onChanged: (value) => setState(() => _technologyHandlingRating = value),
                  icon: Icons.phone_android_rounded,
                ),

                const SizedBox(height: 20),

                // Overall Rating Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kLivinkeyGreen.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kLivinkeyGreen.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Rating',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kLivinkeyGreen.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getOverallRating().toStringAsFixed(1),
                          style: const TextStyle(
                            color: kLivinkeyGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Comment Field
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
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Additional Comments (Optional)',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14,
                      ),
                      hintText: 'Share your thoughts, suggestions, or concerns...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: kLivinkeyGreen.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kLivinkeyGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: LoadingIndicator(size: 24, color: Colors.black),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit Feedback',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.send_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: kLivinkeyGreen.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kLivinkeyGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: kLivinkeyGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '/10',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}