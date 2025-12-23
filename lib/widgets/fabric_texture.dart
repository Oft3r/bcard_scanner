import 'package:flutter/material.dart';

class FabricTexture extends StatelessWidget {
  final Color color;
  final double opacity;
  final double spacing;

  const FabricTexture({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.15, // Slightly visible
    this.spacing = 3.0, // Tight weave
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FabricPainter(
        color: color.withOpacity(opacity),
        spacing: spacing,
      ),
    );
  }
}

class _FabricPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _FabricPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      // Vary opacity slightly for more natural look?
      // Keep it simple for now.
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
