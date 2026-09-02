import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: size > 30 ? 3.0 : 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? kLivinkeyGreen,
        ),
      ),
    );

    if (message == null || message!.isEmpty) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (color ?? kLivinkeyGreen).withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: (color ?? kLivinkeyGreen).withOpacity(0.15),
            ),
          ),
          child: indicator,
        ),
        const SizedBox(height: 16),
        Text(
          message!,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}