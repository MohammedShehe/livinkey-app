// lib/widgets/guest/pg_card.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/pg_model.dart';
import 'offer_widgets.dart';

class PgCard extends StatefulWidget {
  final PgModel pg;
  final VoidCallback onTap;

  const PgCard({
    super.key,
    required this.pg,
    required this.onTap,
  });

  @override
  State<PgCard> createState() => _PgCardState();
}

class _PgCardState extends State<PgCard> {
  PgModel get pg => widget.pg;
  VoidCallback get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    // FIXED: Use statusText instead of status
    final String statusText = pg.statusText;
    final bool isVacant = statusText == 'Vacant';
    // Count only COMPLETELY empty rooms (not remaining bed spaces)
    // If floors data is missing, fall back to 0 so we never show partial spaces as available
    // (or the number an admin set manually for this PG)
    final int availableRooms = pg.displayVacantRooms;

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
                // Offer ribbon (only when an admin has a live offer on this PG)
                if (pg.hasOffer)
                  Positioned(
                    left: 0,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE8590C), Color(0xFFF59F00)],
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pg.bestOffer!.headline +
                                (pg.liveOffers.length > 1
                                    ? '  +${pg.liveOffers.length - 1}'
                                    : ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
                  if (pg.hasOffer) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59F00).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF59F00).withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        pg.bestOffer!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFB84D),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Live counter, e.g. "Ends in 7h 12m"
                    if (pg.bestOffer!.endsAt != null) ...[
                      const SizedBox(height: 4),
                      OfferCountdown(
                        offer: pg.bestOffer!,
                        // When it hits zero the card redraws without the offer
                        onExpired: () {
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ],
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
                      // Only completely empty rooms are counted as vacant
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
                      // Offer price: old price crossed out, new price shown
                      Flexible(
                        child: pg.offerRent != null
                            ? OfferPrice(
                                original: pg.rent,
                                offer: pg.offerRent!,
                                fontSize: 14,
                              )
                            : Text(
                                '₹${pg.rent.toStringAsFixed(0)}/mo',
                                style: const TextStyle(
                                  color: kLivinkeyGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
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