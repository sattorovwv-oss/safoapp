import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../screens/place_detail.dart';
import 'common.dart';

void openPlace(BuildContext context, Place p, String heroTag) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => PlaceDetailScreen(place: p, heroTag: heroTag),
    transitionsBuilder: (_, a, _, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(opacity: curved, child: child);
    },
  ));
}

/// Большая карточка для каруселей.
class BigPlaceCard extends StatelessWidget {
  const BigPlaceCard({super.key, required this.place, required this.heroTag, this.width = 270, this.height = 340});
  final Place place;
  final String heroTag;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.app.lang;
    return Pressable(
      onTap: () => openPlace(context, place, heroTag),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 24, offset: const Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(fit: StackFit.expand, children: [
            Hero(tag: heroTag, child: PlaceImage(url: firstPhoto(context, place), category: place.category)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Color(0xE6000000)], stops: [0, .45, 1]),
              ),
            ),
            Positioned(top: 14, left: 14, child: _Tag(icon: catIcon(place.category), text: context.cat(place.category))),
            Positioned(top: 14, right: 14, child: RatingPill(place)),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(place.nameOf(l), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.place_rounded, size: 14, color: c.primary),
                  const SizedBox(width: 4),
                  Text(context.reg(place.region), style: const TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ),
        ]),
      );
}

/// Горизонтальная строка для списков.
class RowPlaceCard extends StatelessWidget {
  const RowPlaceCard({super.key, required this.place, required this.heroTag});
  final Place place;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.app.lang;
    return Pressable(
      onTap: () => openPlace(context, place, heroTag),
      scale: .975,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border.withValues(alpha: .7)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(width: 92, height: 92, child: Hero(tag: heroTag, child: PlaceImage(url: firstPhoto(context, place), category: place.category))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place.nameOf(l), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium?.copyWith(height: 1.2)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(catIcon(place.category), size: 14, color: c.primary),
                const SizedBox(width: 5),
                Expanded(child: Text('${context.cat(place.category)} · ${context.reg(place.region)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              place.ratingCount > 0
                  ? Row(children: [
                      Stars(value: place.ratingAvg, size: 15),
                      const SizedBox(width: 6),
                      Text(place.ratingAvg.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: c.text)),
                    ])
                  : Text(context.t('no_rating'), style: TextStyle(color: c.muted, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ]),
      ),
    );
  }
}
