import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'shell.dart';

/// Заставка: логотип «вырастает», вокруг расходятся кольца, затем плавный переход на главный экран.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final store = context.store;
    WidgetsBinding.instance.addPostFrameCallback((_) => store.load());
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, _, _) => const Shell(),
          transitionsBuilder: (_, a, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(
                begin: 1.04,
                end: 1.0,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.2),
            radius: 1.1,
            colors: [c.primary.withValues(alpha: .22), c.bg],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = _c.value;
              final pop = Curves.elasticOut.transform(
                (t / .55).clamp(0.0, 1.0),
              );
              final text = Curves.easeOutCubic.transform(
                ((t - .35) / .4).clamp(0.0, 1.0),
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Builder(
                            builder: (_) {
                              final p = ((t * 1.4 - i * .18)).clamp(0.0, 1.0);
                              return Opacity(
                                opacity: (1 - p) * .5,
                                child: Container(
                                  width: 110 + p * 150,
                                  height: 110 + p * 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        Transform.rotate(
                          angle: (1 - pop) * -math.pi / 6,
                          child: Transform.scale(
                            scale: pop,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.primary.withValues(alpha: .5),
                                    blurRadius: 50,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 116,
                                  height: 116,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, (1 - text) * 18),
                      child: Column(
                        children: [
                          Text(
                            context.t('app'),
                            style: context.tt.displaySmall?.copyWith(
                              fontSize: 42,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.t('tagline'),
                            style: TextStyle(
                              color: c.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
