import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class WebCursorEffects extends StatelessWidget {
  final Widget child;
  const WebCursorEffects({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TILT CARD — 3D tilt on hover
// ═══════════════════════════════════════════════════════════════════════════
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  const TiltCard({super.key, required this.child, this.maxTilt = 6.0});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rotX = 0;
  double _rotY = 0;
  double _scale = 1.0;

  void _onHover(PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final x = (e.localPosition.dx / size.width) - 0.5;
    final y = (e.localPosition.dy / size.height) - 0.5;
    setState(() {
      _rotY = x * widget.maxTilt * 2;
      _rotX = -y * widget.maxTilt * 2;
      _scale = 1.02;
    });
  }

  void _onExit(PointerEvent e) {
    setState(() {
      _rotX = 0;
      _rotY = 0;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotX * 3.14159 / 180)
          ..rotateY(_rotY * 3.14159 / 180)
          ..scale(_scale),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAGNETIC WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class MagneticWidget extends StatefulWidget {
  final Widget child;
  final double strength;
  const MagneticWidget({
    super.key,
    required this.child,
    this.strength = 0.25,
  });

  @override
  State<MagneticWidget> createState() => _MagneticWidgetState();
}

class _MagneticWidgetState extends State<MagneticWidget> {
  double _dx = 0;
  double _dy = 0;

  void _onHover(PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = e.localPosition - center;
    setState(() {
      _dx = delta.dx * widget.strength;
      _dy = delta.dy * widget.strength;
    });
  }

  void _onExit(PointerEvent e) {
    setState(() {
      _dx = 0;
      _dy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_dx, _dy, 0),
        child: widget.child,
      ),
    );
  }
}