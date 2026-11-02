import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import 'explore.dart';
import 'home.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// Каркас: 4 вкладки и плавающая стеклянная навигация с анимированным индикатором.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  final _visited = <int>{0};
  final _request = ValueNotifier<String?>(null);

  void _go(int i) {
    if (i == _i) return;
    HapticFeedback.selectionClick();
    setState(() {
      _i = i;
      _visited.add(i);
    });
  }

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  Widget _tab(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => HomeScreen(
          onSearch: () {
            _go(1);
            _request.value = '_focus';
          },
          onCategory: (cat) {
            _go(1);
            _request.value = cat;
          },
        ),
      1 => ExploreScreen(categoryRequest: _request),
      2 => const MapScreen(),
      _ => const SettingsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        for (var i = 0; i < 4; i++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: i != _i,
              child: AnimatedOpacity(
                opacity: i == _i ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: i == _i ? Offset.zero : Offset(i < _i ? -.04 : .04, 0),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  child: _tab(i),
                ),
              ),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 14,
          child: _NavBar(
            index: _i,
            onTap: _go,
            items: [
              (Icons.home_rounded, Icons.home_outlined, context.t('nav_home')),
              (Icons.explore_rounded, Icons.explore_outlined, context.t('nav_explore')),
              (Icons.map_rounded, Icons.map_outlined, context.t('nav_map')),
              (Icons.tune_rounded, Icons.tune_rounded, context.t('nav_settings')),
            ],
            color: c,
          ),
        ),
      ]),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap, required this.items, required this.color});
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, IconData, String)> items;
  final SafoColors color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: c.border.withValues(alpha: .8)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: LayoutBuilder(builder: (_, box) {
            final w = box.maxWidth / items.length;
            return Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                left: index * w,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(decoration: BoxDecoration(gradient: c.brand, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .4), blurRadius: 18, offset: const Offset(0, 6))])),
              ),
              Row(children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Column(
                          key: ValueKey('$i-${i == index}'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(i == index ? items[i].$1 : items[i].$2, size: 24, color: i == index ? c.onPrimary : c.muted),
                            const SizedBox(height: 2),
                            Text(items[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: i == index ? c.onPrimary : c.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]),
            ]);
          }),
        ),
      ),
    );
  }
}
