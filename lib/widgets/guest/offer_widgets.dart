// lib/widgets/guest/offer_widgets.dart
//
// Shared pieces for showing offers:
//   * OfferCountdown – live "Ends in 7h 12m" counter that ticks every second
//   * OfferPrice     – old price crossed out + new price
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/pg_model.dart';
import '../../utils/constants.dart';

/// Live countdown for an offer that has an end time.
/// Renders nothing when the offer has no end time or has already ended.
/// [onExpired] fires once, the moment the counter reaches zero, so the parent
/// can drop the offer / remove the crossed-out price.
class OfferCountdown extends StatefulWidget {
  final PgOffer offer;
  final VoidCallback? onExpired;
  final double fontSize;
  final bool filled;

  const OfferCountdown({
    super.key,
    required this.offer,
    this.onExpired,
    this.fontSize = 10,
    this.filled = true,
  });

  @override
  State<OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<OfferCountdown> {
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant OfferCountdown old) {
    super.didUpdateWidget(old);
    if (old.offer.endsAt != widget.offer.endsAt) {
      _fired = false;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.offer.endsAt == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.offer.isExpired) {
        _timer?.cancel();
        if (!_fired) {
          _fired = true;
          widget.onExpired?.call();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    if (o.endsAt == null || o.isExpired) return const SizedBox.shrink();
    final left = o.timeLeft ?? Duration.zero;
    // Turns red in the last hour to create urgency.
    final urgent = left.inHours < 1;
    final color = urgent ? const Color(0xFFFF6B6B) : const Color(0xFFFFB84D);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.filled ? 6 : 0, vertical: widget.filled ? 3 : 0),
      decoration: widget.filled
          ? BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.35)),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: widget.fontSize + 2, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              'Ends in ${o.countdownText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// New price with the old price crossed out next to it.
class OfferPrice extends StatelessWidget {
  final double original;
  final double offer;
  final double fontSize;
  final String suffix;

  const OfferPrice({
    super.key,
    required this.original,
    required this.offer,
    this.fontSize = 14,
    this.suffix = '/mo',
  });

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    // Indian digit grouping: 12,34,567
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          '₹${_fmt(offer)}$suffix',
          style: TextStyle(
            color: kLivinkeyGreen,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '₹${_fmt(original)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.redAccent,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}
