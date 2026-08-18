// lib/widgets/guest/pg_card.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/pg_model.dart';

class PgCard extends StatelessWidget {
  final PgModel pg;
  final VoidCallback onTap;

  const PgCard({
    super.key,
    required this.pg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: Use statusText instead of status
    final String statusText = pg.statusText;
    final bool isVacant = statusText == 'Vacant';
    final int availableRooms = pg.totalCapacity - pg.totalOccupied;

    return GestureDetector(
      onTap: onTap,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge
            Stack(
              children: [
                // FIXED: Use coverImage if available, otherwise show placeholder
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: pg.coverImage != null
                      ? Image.network(
                          pg.coverImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              width: double.infinity,
                              color: kLivinkeyGreen.withOpacity(0.1),
                              child: Icon(
                                Icons.home_work_rounded,
                                color: kLivinkeyGreen.withOpacity(0.3),
                                size: 48,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: kLivinkeyGreen.withOpacity(0.1),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: kLivinkeyGreen.withOpacity(0.3),
                            size: 48,
                          ),
                        ),
                ),
                // FIXED: Use statusText instead of status
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isVacant ? kLivinkeyGreen : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Rating
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          pg.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pg.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pg.location,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${pg.totalRooms} rooms',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      // FIXED: Use availableRooms calculated from totalCapacity - totalOccupied
                      Text(
                        '$availableRooms vacant',
                        style: TextStyle(
                          color: availableRooms > 0
                              ? kLivinkeyGreen.withOpacity(0.7)
                              : Colors.red.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${pg.rent.toStringAsFixed(0)}/mo',
                        style: const TextStyle(
                          color: kLivinkeyGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            color: kLivinkeyGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}