import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class WebBackground extends StatelessWidget {
  final Offset cursor;
  const WebBackground({
    super.key,
    this.cursor = const Offset(0.5, 0.5),
  });

  @override
  Widget build(BuildContext context) {
    final accent = Provider.of<ThemeProvider>(context).accentColor;

    return SizedBox.expand(
      child: CustomPaint(
        painter: _StaticBackgroundPainter(accent: accent),
      ),
    );
  }
}

class _StaticBackgroundPainter extends CustomPainter {
  final Color accent;
  _StaticBackgroundPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFF0D0D1A),
          const Color(0xFF050508),
        ],
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle corner glows
    _drawCornerGlow(canvas, size,
        Offset(0, 0), accent);
    _drawCornerGlow(canvas, size,
        Offset(size.width, size.height), const Color(0xFFAA00FF));

    // Subtle scan lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Subtle grid
    final gridPaint = Paint()
      ..color = accent.withOpacity(0.03)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 18; i++) {
      final x = size.width * i / 18;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 0; i <= 12; i++) {
      final y = size.height * i / 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawCornerGlow(
      Canvas canvas, Size size, Offset center, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.12),
          color.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: 400),
      );
    canvas.drawCircle(center, 400, paint);
  }

  @override
  bool shouldRepaint(_StaticBackgroundPainter old) => false;
}