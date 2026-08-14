// lib/widgets/tenant/document_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DocumentCard extends StatelessWidget {
  final Map<String, String> doc;
  final bool hasPhoto;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.doc,
    required this.hasPhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust card padding based on screen size
    final double horizontalPadding = screenWidth > 600 ? 12 : 10;
    final double verticalPadding = screenWidth > 600 ? 14 : 12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kLivinkeyWhite.withOpacity(0.05),
              kLivinkeyWhite.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kLivinkeyWhite.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available space
            final double shortestSide = math.min(constraints.maxWidth, constraints.maxHeight);
            final double boxSize = (shortestSide * 0.50).clamp(44.0, 80.0);
            final double iconSize = boxSize * 0.5;
            final double fontSize = screenWidth > 600 ? 13 : 12;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPhoto)
                    Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kLivinkeyGreen.withOpacity(0.2),
                            kLivinkeyGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kLivinkeyGreen.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              doc['icon']!,
                              style: TextStyle(fontSize: iconSize.clamp(24.0, 36.0)),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                color: kLivinkeyGreen.withOpacity(0.5),
                                size: iconSize.clamp(20.0, 28.0),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload',
                                style: TextStyle(
                                  color: kLivinkeyGreen.withOpacity(0.4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      doc['label']!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}