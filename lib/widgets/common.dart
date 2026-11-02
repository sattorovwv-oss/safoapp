import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';

IconData catIcon(String c) => switch (c) {
  'HISTORICAL' => Icons.account_balance_rounded,
  'NATURE' => Icons.terrain_rounded,
  'RECREATION' => Icons.spa_rounded,
  'TEAHOUSE_RESTAURANT' => Icons.local_cafe_rounded,
  'MARKET_PARK' => Icons.park_rounded,
  _ => Icons.place_rounded,
};

/// Плавное появление снизу с задержкой (для каскадной анимации списков).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 28,
  });
  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: 60 * widget.index.clamp(0, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _a.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _a.value) * widget.offset),
        child: child,
      ),
    ),
  );
}

/// Нажатие с пружинным уменьшением и лёгкой вибрацией.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = .96,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: widget.onTap == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            widget.onTap!();
          },
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Мерцающая заглушка на время загрузки.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, this.height = 100, this.width, this.radius = 22});
  final double height, radius;
  final double? width;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + 3 * _c.value, 0),
            end: Alignment(-.5 + 3 * _c.value, 0),
            colors: [c.surface, c.surface2, c.surface],
          ),
        ),
      ),
    );
  }
}

class PlaceImage extends StatelessWidget {
  const PlaceImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    required this.category,
  });
  final String? url;
  final BoxFit fit;
  final String category;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tone = switch (category) {
      'HISTORICAL' => const [Color(0xFFB45309), Color(0xFF78350F)],
      'NATURE' => const [Color(0xFF0F766E), Color(0xFF134E4A)],
      'RECREATION' => const [Color(0xFF0369A1), Color(0xFF1E3A8A)],
      'TEAHOUSE_RESTAURANT' => const [Color(0xFF15803D), Color(0xFF14532D)],
      _ => const [Color(0xFF4D7C0F), Color(0xFF365314)],
    };
    // Нет реального фото: цветной фон и значок категории
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(22)),
          child: Icon(catIcon(category), size: 38, color: Colors.white),
        ),
      ),
    );
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 380),
      // На вебе <img> обходит CORS-ограничения для картинок
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
      placeholder: (_, _) => Container(color: c.surface2),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

String? firstPhoto(BuildContext context, Place p, {bool large = false}) {
  if (p.photos.isEmpty) return null;
  final ph = p.photos.first;
  return context.store.api.media(large ? ph.large : ph.medium);
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 16});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i - .25
                ? Icons.star_rounded
                : (value >= i - .75
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: c.accent,
          ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: c.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: context.tt.headlineMedium?.copyWith(fontSize: 22),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? c.primary : c.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: .35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: selected ? c.onPrimary : c.muted),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: selected ? c.onPrimary : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingPill extends StatelessWidget {
  const RatingPill(this.p, {super.key});
  final Place p;

  @override
  Widget build(BuildContext context) {
    if (p.ratingCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFBBF24)),
          const SizedBox(width: 4),
          Text(
            p.ratingAvg.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: c.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.tt.titleLarge,
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: outlined ? null : c.brand,
          color: outlined ? c.surface : null,
          borderRadius: BorderRadius.circular(18),
          border: outlined ? Border.all(color: c.border) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: c.primary.withValues(alpha: .32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: outlined ? c.primary : c.onPrimary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: outlined ? c.text : c.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Название региона/категории на текущем языке.
extension LabelX on BuildContext {
  String cat(String c) => t('cat_$c');
  String reg(String r) => t('reg_$r');
}
