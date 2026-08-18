import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../models/pg_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/snackbar_helper.dart';

class PgDetailModal extends StatefulWidget {
  final PgModel pg;

  const PgDetailModal({
    super.key,
    required this.pg,
  });

  @override
  State<PgDetailModal> createState() => _PgDetailModalState();
}

class _PgDetailModalState extends State<PgDetailModal> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isLoading = false;
  PgModel? _fullPg;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadFullDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIXED: Merge detail data with list data to preserve room counts
  // ============================================================
  Future<void> _loadFullDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getPublicPGDetails(widget.pg.id);
      if (response['success'] == true && response['data'] != null) {
        final detailPg = PgModel.fromJson(response['data']);
        _fullPg = _mergeWithListData(detailPg, widget.pg);
      } else {
        _fullPg = widget.pg;
      }
    } catch (e) {
      _fullPg = widget.pg;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // FIXED: Prefer detail values, but fall back to list values
  // for room counts (which we already know are correct)
  // ============================================================
  PgModel _mergeWithListData(PgModel detail, PgModel listVersion) {
    return PgModel(
      id: detail.id,
      name: detail.name.isNotEmpty ? detail.name : listVersion.name,
      location: detail.location.isNotEmpty ? detail.location : listVersion.location,
      rating: detail.rating > 0 ? detail.rating : listVersion.rating,
      totalRooms: detail.totalRooms > 0 ? detail.totalRooms : listVersion.totalRooms,
      totalCapacity: detail.totalCapacity > 0 ? detail.totalCapacity : listVersion.totalCapacity,
      totalOccupied: detail.totalOccupied > 0 ? detail.totalOccupied : listVersion.totalOccupied,
      rent: detail.rent > 0 ? detail.rent : listVersion.rent,
      securityFee: detail.securityFee > 0 ? detail.securityFee : listVersion.securityFee,
      numberOfFloors: detail.numberOfFloors > 0 ? detail.numberOfFloors : listVersion.numberOfFloors,
      isActive: detail.isActive,
      coverImage: detail.coverImage ?? listVersion.coverImage,
      images: detail.images.isNotEmpty ? detail.images : listVersion.images,
      amenityNames: detail.amenityNames.isNotEmpty ? detail.amenityNames : listVersion.amenityNames,
      statusText: detail.statusText.isNotEmpty ? detail.statusText : listVersion.statusText,
      occupancyPercentage: detail.occupancyPercentage > 0 ? detail.occupancyPercentage : listVersion.occupancyPercentage,
      floors: detail.floors.isNotEmpty ? detail.floors : listVersion.floors,
      reviews: detail.reviews.isNotEmpty ? detail.reviews : listVersion.reviews,
    );
  }

  List<String> get _images {
    if (_fullPg != null && _fullPg!.images.isNotEmpty) {
      return _fullPg!.images;
    }
    if (widget.pg.images.isNotEmpty) {
      return widget.pg.images;
    }
    return [];
  }

  List<String> get _amenities {
    if (_fullPg != null && _fullPg!.amenityNames.isNotEmpty) {
      return _fullPg!.amenityNames;
    }
    return widget.pg.amenityNames;
  }

  List<ReviewModel> get _reviews {
    if (_fullPg != null && _fullPg!.reviews.isNotEmpty) {
      return _fullPg!.reviews;
    }
    return widget.pg.reviews;
  }

  PgModel get _pg => _fullPg ?? widget.pg;

  Future<void> _bookNow() async {
    final String message =
        'Hello Livinkey! I would like to book a PG.\n'
        'PG Name: ${_pg.name}\n'
        'Location: ${_pg.location}\n'
        'Rent: ₹${_pg.rent}/month\n'
        'Please provide more details.';

    final String url = 'https://wa.me/919878383497?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        SnackbarHelper.showError(context, 'Could not open WhatsApp. Please install WhatsApp.');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Could not open WhatsApp.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kLivinkeyBlack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSlider(),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _pg.statusText == 'Vacant'
                                        ? kLivinkeyGreen
                                        : _pg.statusText == 'Full Occupied'
                                            ? Colors.red
                                            : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _pg.statusText,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _pg.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Text(
                              _pg.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _pg.location,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(12),
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
                                  color: kLivinkeyGreen.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Rent per month',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${_pg.rent.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: kLivinkeyGreen,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ============================================================
                            // FIXED: Now shows correct room counts because _pg has
                            // the merged data (list values preserved)
                            // ============================================================
                            Row(
                              children: [
                                _buildRoomInfo(
                                  icon: Icons.meeting_room_rounded,
                                  label: 'Total Rooms',
                                  value: _pg.totalRooms.toString(),
                                ),
                                _buildRoomInfo(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Available',
                                  value: (_pg.totalCapacity - _pg.totalOccupied).toString(),
                                  color: _pg.totalCapacity - _pg.totalOccupied > 0
                                      ? kLivinkeyGreen
                                      : Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'About this PG',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _pg.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_amenities.isNotEmpty) ...[
                              const Text(
                                'Amenities',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _amenities.map((amenity) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          kLivinkeyGreen.withOpacity(0.12),
                                          kLivinkeyGreen.withOpacity(0.04),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: kLivinkeyGreen.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      amenity,
                                      style: TextStyle(
                                        color: kLivinkeyGreen.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],

                            if (_reviews.isNotEmpty) ...[
                              const Text(
                                'Reviews',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._reviews.map((comment) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.03),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            kLivinkeyGreen.withOpacity(0.2),
                                        child: Text(
                                          comment.name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: kLivinkeyGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              comment.comment,
                                              style: TextStyle(
                                                color:
                                                    Colors.white.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _bookNow,
                                icon: const Icon(
                                  Icons.chat_rounded,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Book Now on WhatsApp',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    final images = _images;

    if (images.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kLivinkeyGreen.withOpacity(0.2), kLivinkeyGreen.withOpacity(0.05)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_work_rounded, color: Colors.white38, size: 60),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kLivinkeyGreen.withOpacity(0.2),
                            kLivinkeyGreen.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.home_work_rounded, color: Colors.white38, size: 60),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index
                    ? kLivinkeyGreen
                    : Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfo({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.03),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? Colors.white.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}