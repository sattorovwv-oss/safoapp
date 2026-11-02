import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/auth.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import 'chat_screen.dart';
import 'cleaner_home.dart';
import 'report_screen.dart';
import 'subbotniks_screen.dart';
import 'explore.dart';
import 'home.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

enum _Tab { home, explore, map, report, subbotniks, chat, work, profile }

/// Каркас: вкладки и плавающая стеклянная навигация. Вкладка «Работа» видна только тозакунанда.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  _Tab _cur = _Tab.home;
  final _visited = <_Tab>{_Tab.home};
  final _request = ValueNotifier<String?>(null);

  void _go(_Tab t) {
    if (t == _cur) return;
    HapticFeedback.selectionClick();
    setState(() {
      _cur = t;
      _visited.add(t);
    });
  }

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  List<_Tab> _tabs = const [];

  /// Если вкладки «Поиск» нет у роли (житель, председатель) — открываем её отдельным экраном.
  void _openExplore(String request) {
    if (_tabs.contains(_Tab.explore)) {
      _go(_Tab.explore);
      _request.value = request;
      return;
    }
    final req = ValueNotifier<String?>(request);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Stack(
            children: [
              ExploreScreen(categoryRequest: req),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(_Tab t) {
    if (!_visited.contains(t)) return const SizedBox.shrink();
    return switch (t) {
      _Tab.home => HomeScreen(
        onSearch: () => _openExplore('_focus'),
        onCategory: _openExplore,
      ),
      _Tab.explore => ExploreScreen(categoryRequest: _request),
      _Tab.map => const MapScreen(),
      _Tab.report => const ReportScreen(),
      _Tab.subbotniks => const SubbotniksScreen(),
      _Tab.chat => const ChatScreen(),
      _Tab.work => const CleanerHomeScreen(),
      _Tab.profile => SettingsScreen(
        onSignedIn: () {
          final a = context.auth;
          _go(
            a.isCleaner
                ? _Tab.work
                : (a.isResident || a.isChairman)
                ? _Tab.subbotniks
                : _Tab.home,
          );
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final dark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    final List<_Tab> tabs = auth.isResident
        ? [_Tab.home, _Tab.subbotniks, _Tab.report, _Tab.chat, _Tab.profile]
        : auth.isChairman
        ? [_Tab.home, _Tab.subbotniks, _Tab.chat, _Tab.profile]
        : auth.isCleaner
        ? [_Tab.home, _Tab.explore, _Tab.map, _Tab.work, _Tab.profile]
        : [_Tab.home, _Tab.explore, _Tab.map, _Tab.report, _Tab.profile];
    _tabs = tabs;
    // Если вкладка исчезла (выход из аккаунта) — возвращаемся на главную
    final cur = tabs.contains(_cur) ? _cur : _Tab.home;
    final labels = {
      _Tab.home: (
        Icons.home_rounded,
        Icons.home_outlined,
        context.t('nav_home'),
      ),
      _Tab.explore: (
        Icons.explore_rounded,
        Icons.explore_outlined,
        context.t('nav_explore'),
      ),
      _Tab.map: (Icons.map_rounded, Icons.map_outlined, context.t('nav_map')),
      _Tab.report: (
        Icons.add_a_photo_rounded,
        Icons.add_a_photo_outlined,
        context.t('nav_report'),
      ),
      _Tab.subbotniks: (
        Icons.event_available_rounded,
        Icons.event_available_outlined,
        context.t('nav_subbotniks'),
      ),
      _Tab.chat: (
        Icons.forum_rounded,
        Icons.forum_outlined,
        context.t('nav_chat'),
      ),
      _Tab.work: (
        Icons.cleaning_services_rounded,
        Icons.cleaning_services_outlined,
        context.t('nav_work'),
      ),
      _Tab.profile: (
        Icons.person_rounded,
        Icons.person_outline_rounded,
        context.t('account'),
      ),
    };

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          for (final t in _Tab.values)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: t != cur,
                child: AnimatedOpacity(
                  opacity: t == cur ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: t == cur
                        ? Offset.zero
                        : Offset(t.index < cur.index ? -.04 : .04, 0),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    child: t == _Tab.work && !auth.isCleaner
                        ? const SizedBox.shrink()
                        : _page(t),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: _NavBar(
              index: tabs.indexOf(cur),
              onTap: (i) => _go(tabs[i]),
              items: [for (final t in tabs) labels[t]!],
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.onTap,
    required this.items,
    required this.color,
  });
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (_, box) {
              final w = box.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    left: index * w,
                    width: w,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: c.brand,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: .4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
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
                                  Icon(
                                    i == index ? items[i].$1 : items[i].$2,
                                    size: 24,
                                    color: i == index ? c.onPrimary : c.muted,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    items[i].$3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: i == index ? c.onPrimary : c.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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
