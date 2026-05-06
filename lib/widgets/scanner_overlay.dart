import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final double scanAreaSize;
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderThickness;

  const ScannerOverlay({
    super.key,
    this.scanAreaSize = 250.0,
    this.borderColor = Colors.blue,
    this.borderRadius = 12.0,
    this.borderLength = 30.0,
    this.borderThickness = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background with a hole in the middle
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scanner border corners
        Center(
          child: SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: CustomPaint(
              painter: ScannerBorderPainter(
                borderColor: borderColor,
                borderRadius: borderRadius,
                borderLength: borderLength,
                borderThickness: borderThickness,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderThickness;

  ScannerBorderPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness;

    final path = Path();

    // Top-left corner
    path.moveTo(0, borderLength);
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.lineTo(borderLength, 0);

    // Top-right corner
    path.moveTo(size.width - borderLength, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, borderLength);

    // Bottom-right corner
    path.moveTo(size.width, size.height - borderLength);
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - borderRadius,
      size.height,
    );
    path.lineTo(size.width - borderLength, size.height);

    // Bottom-left corner
    path.moveTo(borderLength, size.height);
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, size.height - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
