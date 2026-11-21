import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Падающий снег поверх приложения. Не перехватывает нажатия;
/// выключается, если в телефоне включено «уменьшение анимации».
class Snowfall extends StatefulWidget {
  const Snowfall({super.key});

  @override
  State<Snowfall> createState() => _SnowfallState();
}

class _Flake {
  _Flake(math.Random r, Size s, {bool anyY = true}) {
    reset(r, s, anyY: anyY);
  }
  late double x, y, radius, speed, drift, phase, alpha;

  void reset(math.Random r, Size s, {bool anyY = false}) {
    x = r.nextDouble() * s.width;
    y = anyY ? r.nextDouble() * s.height : -8;
    radius = .8 + r.nextDouble() * 2.2;
    speed = 20 + r.nextDouble() * 45; // пикселей в секунду
    drift = -8 + r.nextDouble() * 16;
    phase = r.nextDouble() * math.pi * 2;
    alpha = .55 + r.nextDouble() * .4;
  }
}

class _SnowfallState extends State<Snowfall> with SingleTickerProviderStateMixin {
  final _rnd = math.Random();
  final _flakes = <_Flake>[];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  final _repaint = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 0.016 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size.isEmpty) return;
    for (final f in _flakes) {
      f.phase += dt * .8;
      f.y += f.speed * dt;
      f.x += (f.drift + math.sin(f.phase) * 12) * dt;
      if (f.y > _size.height + 8) f.reset(_rnd, _size);
      if (f.x < -8) f.x = _size.width + 8;
      if (f.x > _size.width + 8) f.x = -8;
    }
    _repaint.value++;
  }

  void _ensure(Size s) {
    if (s == _size) return;
    _size = s;
    final n = (s.width / 9).clamp(30, 70).round();
    _flakes
      ..clear()
      ..addAll(List.generate(n, (_) => _Flake(_rnd, s)));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      _ticker.stop();
      return const SizedBox.shrink();
    }
    if (!_ticker.isActive) _ticker.start();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          _ensure(box.biggest);
          return RepaintBoundary(
            child: CustomPaint(size: box.biggest, painter: _SnowPainter(_flakes, _repaint)),
          );
        },
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.flakes, Listenable repaint) : super(repaint: repaint);
  final List<_Flake> flakes;
  final _paint = Paint();
  final _glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      _glow.color = const Color(0xFF8CB4DC).withValues(alpha: f.alpha * .5);
      canvas.drawCircle(Offset(f.x, f.y), f.radius + .6, _glow);
      _paint.color = Colors.white.withValues(alpha: f.alpha);
      canvas.drawCircle(Offset(f.x, f.y), f.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) => false;
}
