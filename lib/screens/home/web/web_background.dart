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
    return const _GymImageBackground();
  }
}

class _GymImageBackground extends StatelessWidget {
  const _GymImageBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Real gym photo ────────────────────────────────────────────
          Image.network(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
            '?w=1800&q=80&auto=format&fit=crop',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to painted background if image fails to load
              return const _FallbackBackground();
            },
          ),

          // ── Dark overlay so content stays readable ────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEA000000), // 92% black top-left
                  Color(0xE0010801), // 88% very dark green-black
                  Color(0xF0000508), // 94% dark blue-black bottom-right
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Subtle green vignette glow at edges ───────────────────────
          const _EdgeGlow(),

          // ── Scanlines for that gym-screen atmosphere ───────────────────
          const _ScanlineOverlay(),
        ],
      ),
    );
  }
}

// ── Edge glow using CustomPainter ────────────────────────────────────────────
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _EdgeGlowPainter()),
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left green accent glow
    final tlPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E676).withOpacity(0.08),
          const Color(0xFF00E676).withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(Offset.zero, size.width * 0.5, tlPaint);

    // Bottom-right purple accent glow
    final brPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withOpacity(0.06),
          const Color(0xFF7C4DFF).withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width, size.height),
        radius: size.width * 0.55,
      ));
    canvas.drawCircle(
        Offset(size.width, size.height), size.width * 0.55, brPaint);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.025)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 20; i++) {
      final x = size.width * i / 20;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 0; i <= 14; i++) {
      final y = size.height * i / 14;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter old) => false;
}

// ── Scanline overlay ──────────────────────────────────────────────────────────
class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _ScanlinePainter()),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ── Fallback painted background (if image fails) ─────────────────────────────
class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _FallbackPainter()),
    );
  }
}

class _FallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: const [
          Color(0xFF0D0D1A),
          Color(0xFF050508),
        ],
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Corner glows
    _drawCornerGlow(canvas, size, Offset.zero, const Color(0xFF00E676));
    _drawCornerGlow(canvas, size, Offset(size.width, size.height),
        const Color(0xFF7C4DFF));

    // Scan lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.03)
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
  bool shouldRepaint(_FallbackPainter old) => false;
}