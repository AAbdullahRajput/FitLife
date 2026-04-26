import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class WebBackground extends StatefulWidget {
  final Offset cursor;
  const WebBackground({
    super.key,
    this.cursor = const Offset(0.5, 0.5),
  });

  @override
  State<WebBackground> createState() => _WebBackgroundState();
}

class _WebBackgroundState extends State<WebBackground>
    with TickerProviderStateMixin {
  final List<_Orb> _orbs = [];
  final List<_Star> _stars = [];
  late AnimationController _controller;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // ── Deep orbs with 3D depth layers ──────────────────────────────────
    for (int i = 0; i < 10; i++) {
      _orbs.add(_Orb(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        z: 0.2 + _rng.nextDouble() * 0.8,
        size: 120 + _rng.nextDouble() * 300,
        speedX: (_rng.nextDouble() - 0.5) * 0.0003,
        speedY: (_rng.nextDouble() - 0.5) * 0.0003,
        colorIndex: i % 5,
      ));
    }

    // ── Star field for 3D depth ──────────────────────────────────────────
    for (int i = 0; i < 120; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        z: 0.1 + _rng.nextDouble() * 0.9,
        size: 0.5 + _rng.nextDouble() * 1.8,
        twinkleSpeed: 0.01 + _rng.nextDouble() * 0.03,
        twinkleOffset: _rng.nextDouble() * 6.28,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _controller.repeat();
  }

  double _time = 0;

  void _update() {
    setState(() {
      _time += 0.016;

      // Update stars twinkle
      for (final star in _stars) {
        star.brightness =
            0.3 + 0.7 * (0.5 + 0.5 * sin(_time * star.twinkleSpeed * 60 + star.twinkleOffset));
        // Parallax — closer stars move more with cursor
        star.px = star.x + (widget.cursor.dx - 0.5) * star.z * 0.04;
        star.py = star.y + (widget.cursor.dy - 0.5) * star.z * 0.04;
      }

      // Update orbs
      for (final orb in _orbs) {
        final dx = widget.cursor.dx - orb.x;
        final dy = widget.cursor.dy - orb.y;
        final dist = sqrt(dx * dx + dy * dy);
        final pull = orb.z * 0.007;
        if (dist < 0.7) {
          orb.x += dx * pull;
          orb.y += dy * pull;
        }
        orb.x += orb.speedX;
        orb.y += orb.speedY;
        if (orb.x < 0 || orb.x > 1) orb.speedX *= -1;
        if (orb.y < 0 || orb.y > 1) orb.speedY *= -1;
        orb.x = orb.x.clamp(0.0, 1.0);
        orb.y = orb.y.clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Provider.of<ThemeProvider>(context).accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final orbColors = [
      accent,
      const Color(0xFF2979FF),
      const Color(0xFFAA00FF),
      accent.withOpacity(0.5),
      const Color(0xFF00BCD4),
    ];

    return SizedBox.expand(
      child: CustomPaint(
        painter: _BackgroundPainter(
          orbs: _orbs,
          stars: _stars,
          colors: orbColors,
          isDark: isDark,
          cursor: widget.cursor,
          accent: accent,
          time: _time,
        ),
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────
class _Orb {
  double x, y, z, size, speedX, speedY;
  final int colorIndex;
  _Orb({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.colorIndex,
  });
}

class _Star {
  double x, y, z, size, twinkleSpeed, twinkleOffset;
  double brightness = 1.0;
  double px = 0, py = 0;
  _Star({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  }) {
    px = x;
    py = y;
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final List<_Orb> orbs;
  final List<_Star> stars;
  final List<Color> colors;
  final bool isDark;
  final Offset cursor;
  final Color accent;
  final double time;

  _BackgroundPainter({
    required this.orbs,
    required this.stars,
    required this.colors,
    required this.isDark,
    required this.cursor,
    required this.accent,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Deep space base gradient ────────────────────────────────────
    _drawBaseGradient(canvas, size);

    // ── 2. Star field with parallax ────────────────────────────────────
    if (isDark) _drawStars(canvas, size);

    // ── 3. Perspective grid ────────────────────────────────────────────
    if (isDark) _drawGrid(canvas, size);

    // ── 4. Glowing orbs (back to front) ───────────────────────────────
    final sorted = [...orbs]..sort((a, b) => a.z.compareTo(b.z));
    for (final orb in sorted) {
      _drawOrb(canvas, size, orb);
    }

    // ── 5. Cursor spotlight ────────────────────────────────────────────
    _drawSpotlight(canvas, size);

    // ── 6. Scan line effect for futuristic feel ────────────────────────
    if (isDark) _drawScanLines(canvas, size);
  }

  void _drawBaseGradient(Canvas canvas, Size size) {
    if (!isDark) return;
    // Deep space gradient — darker at edges, slightly lighter center
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (cursor.dx - 0.5) * 0.4,
          (cursor.dy - 0.5) * 0.4,
        ),
        colors: [
          const Color(0xFF0D0D1A),
          const Color(0xFF050508),
        ],
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawStars(Canvas canvas, Size size) {
    for (final star in stars) {
      final x = star.px * size.width;
      final y = star.py * size.height;
      final opacity = star.brightness * (0.3 + star.z * 0.7);

      // Closer stars are brighter and bigger
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..maskFilter = star.z > 0.7
            ? MaskFilter.blur(BlurStyle.normal, star.size * 0.8)
            : null;
      canvas.drawCircle(Offset(x, y), star.size * star.z, paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final vanishX = cursor.dx * size.width;
    final vanishY = cursor.dy * size.height;

    // Horizontal perspective lines
    final hPaint = Paint()
      ..color = accent.withOpacity(0.04)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 14; i++) {
      final y = size.height * i / 14;
      final midY = y + (vanishY - y) * 0.1;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(vanishX, midY, size.width, y);
      canvas.drawPath(path, hPaint);
    }

    // Vertical perspective lines
    final vPaint = Paint()
      ..color = accent.withOpacity(0.04)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 18; i++) {
      final x = size.width * i / 18;
      final midX = x + (vanishX - x) * 0.1;
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(midX, vanishY, x, size.height);
      canvas.drawPath(path, vPaint);
    }

    // Bright intersection dots at grid crossings
    final dotPaint = Paint()
      ..color = accent.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i <= 14; i += 2) {
      for (int j = 0; j <= 18; j += 3) {
        final x = size.width * j / 18;
        final y = size.height * i / 14;
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  void _drawOrb(Canvas canvas, Size size, _Orb orb) {
    final color = colors[orb.colorIndex % colors.length];
    final center = Offset(orb.x * size.width, orb.y * size.height);
    final scaledSize = orb.size * orb.z;
    final opacity = isDark
        ? (0.06 + orb.z * 0.14)
        : (0.04 + orb.z * 0.06);

    // Outer soft glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: scaledSize),
      );
    canvas.drawCircle(center, scaledSize, outerPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = color.withOpacity(opacity * 2.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, scaledSize * 0.15);
    canvas.drawCircle(center, scaledSize * 0.12, corePaint);
  }

  void _drawSpotlight(Canvas canvas, Size size) {
    final cursorPos = Offset(cursor.dx * size.width, cursor.dy * size.height);

    // Main spotlight
    final mainPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(isDark ? 0.18 : 0.08),
          accent.withOpacity(isDark ? 0.07 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(
        Rect.fromCircle(center: cursorPos, radius: 350),
      );
    canvas.drawCircle(cursorPos, 350, mainPaint);

    // Inner bright ring around cursor
    final ringPaint = Paint()
      ..color = accent.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(cursorPos, 40, ringPaint);
  }

  void _drawScanLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => true;
}