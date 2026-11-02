import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.place, required this.heroTag});
  final Place place;
  final String heroTag;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _page = PageController();
  int _idx = 0;
  bool _expanded = false;
  Future<List<Review>>? _reviews;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reviews ??= context.store.api.reviews(widget.place.slug);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url)));
  }

  String get _mapsUrl {
    final p = widget.place;
    if (p.mapsUrl != null && p.mapsUrl!.isNotEmpty) return p.mapsUrl!;
    if (p.hasCoords) return 'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}';
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.name['en'] ?? p.slug)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final c = context.c;
    final l = context.app.lang;
    final api = context.store.api;
    final photos = p.photos;
    final media = MediaQuery.of(context);
    final headerH = media.size.height * .5;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            stretch: true,
            expandedHeight: headerH,
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 0,
            toolbarHeight: 0,
            flexibleSpace: Stack(fit: StackFit.expand, children: [
              if (photos.isEmpty)
                Hero(tag: widget.heroTag, child: PlaceImage(url: null, category: p.category))
              else
                PageView.builder(
                  controller: _page,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _idx = i),
                  itemBuilder: (_, i) {
                    final img = GestureDetector(
                      onTap: () => Navigator.of(context).push(PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, _, _) => _Viewer(photos: photos, start: i, api: api),
                        transitionsBuilder: (_, a, _, ch) => FadeTransition(opacity: a, child: ch),
                      )),
                      child: PlaceImage(url: api.media(photos[i].large), category: p.category),
                    );
                    return i == 0 ? Hero(tag: widget.heroTag, child: img) : img;
                  },
                ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .45), Colors.transparent, Colors.transparent, c.bg.withValues(alpha: .9)], stops: const [0, .25, .7, 1]),
                  ),
                ),
              ),
              Positioned(
                top: media.padding.top + 10,
                left: 14,
                right: 14,
                child: Row(children: [
                  _Glass(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  if (photos.length > 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: Colors.black.withValues(alpha: .35),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_library_rounded, size: 15, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('${_idx + 1}/${photos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              if (photos.length > 1)
                Positioned(
                  bottom: 46,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < photos.length && i < 10; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _idx ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(color: i == _idx ? c.primary : Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(8)),
                      ),
                  ]),
                ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -26),
              child: Container(
                decoration: BoxDecoration(color: c.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FadeSlideIn(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Badge(icon: catIcon(p.category), text: context.cat(p.category)),
                        _Badge(icon: Icons.place_rounded, text: context.reg(p.region)),
                      ]),
                      const SizedBox(height: 14),
                      Text(p.nameOf(l), style: context.tt.displaySmall?.copyWith(fontSize: 30)),
                      const SizedBox(height: 12),
                      p.ratingCount > 0
                          ? Row(children: [
                              Stars(value: p.ratingAvg, size: 20),
                              const SizedBox(width: 8),
                              Text(p.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(width: 6),
                              Text('· ${context.t('reviews_n', {'n': p.ratingCount})}', style: TextStyle(color: c.muted)),
                            ])
                          : Text(context.t('no_rating'), style: TextStyle(color: c.muted)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    index: 1,
                    child: Column(children: [
                      SizedBox(width: double.infinity, child: PrimaryButton(label: context.t('open_maps'), icon: Icons.map_rounded, onTap: () => _open(_mapsUrl))),
                      if (p.hasCoords) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: PrimaryButton(outlined: true, label: context.t('route'), icon: Icons.directions_rounded, onTap: () => _open('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}'))),
                          const SizedBox(width: 10),
                          Expanded(child: PrimaryButton(outlined: true, label: context.t('open_earth'), icon: Icons.public_rounded, onTap: () => _open('https://earth.google.com/web/search/${p.lat},${p.lng}'))),
                        ]),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(index: 2, child: _Description(text: p.descOf(l), expanded: _expanded, onToggle: () => setState(() => _expanded = !_expanded))),
                  FadeSlideIn(index: 3, child: _InfoGrid(place: p)),
                  if (photos.isNotEmpty) FadeSlideIn(index: 4, child: _Credits(photo: photos[_idx.clamp(0, photos.length - 1)])),
                  const SizedBox(height: 28),
                  Text(context.t('reviews'), style: context.tt.headlineMedium?.copyWith(fontSize: 22)),
                  const SizedBox(height: 14),
                  FutureBuilder<List<Review>>(
                    future: _reviews,
                    builder: (_, snap) {
                      if (snap.connectionState != ConnectionState.done) return const Shimmer(height: 90);
                      final list = snap.data ?? [];
                      if (list.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border.withValues(alpha: .7))),
                          child: Row(children: [
                            Icon(Icons.rate_review_outlined, color: c.muted),
                            const SizedBox(width: 12),
                            Text(context.t('no_reviews'), style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                          ]),
                        );
                      }
                      return Column(children: [for (var i = 0; i < list.length; i++) FadeSlideIn(index: i, child: _ReviewTile(r: list[i]))]);
                    },
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(width: 44, height: 44, color: Colors.black.withValues(alpha: .35), child: Icon(icon, color: Colors.white)),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.primary.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: c.primary),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
      ]),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text, required this.expanded, required this.onToggle});
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final long = text.length > 260;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.t('about'), style: context.tt.headlineMedium?.copyWith(fontSize: 22)),
      const SizedBox(height: 12),
      AnimatedSize(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Text(text, maxLines: expanded || !long ? null : 6, overflow: expanded || !long ? TextOverflow.visible : TextOverflow.fade, style: context.tt.bodyLarge?.copyWith(color: c.text.withValues(alpha: .88))),
      ),
      if (long)
        Pressable(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(expanded ? '−' : '+', style: TextStyle(color: c.primary, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(width: 6),
              Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: c.primary),
            ]),
          ),
        ),
    ]);
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final l = context.app.lang;
    final items = <(IconData, String, String)>[
      if ((place.address ?? '').isNotEmpty) (Icons.location_on_rounded, context.t('address'), place.address!),
      if ((place.hours ?? '').isNotEmpty) (Icons.schedule_rounded, context.t('hours'), place.hours!),
      if ((place.price ?? '').isNotEmpty) (Icons.confirmation_number_rounded, context.t('price'), place.price!),
      if ((place.bestOf(l) ?? '').isNotEmpty) (Icons.wb_sunny_rounded, context.t('best_time'), place.bestOf(l)!),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.t('info'), style: context.tt.headlineMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border.withValues(alpha: .7))),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.primary.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)),
                    child: Icon(items[i].$1, size: 20, color: c.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i].$2, style: TextStyle(color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(items[i].$3, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
                    ]),
                  ),
                ]),
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: c.border.withValues(alpha: .6)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Credits extends StatelessWidget {
  const _Credits({required this.photo});
  final PlacePhoto photo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(children: [
        Icon(Icons.photo_camera_outlined, size: 15, color: c.muted),
        const SizedBox(width: 8),
        Expanded(child: Text('${context.t('photo_by')}: ${photo.author} · ${photo.license}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12))),
      ]),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.r});
  final Review r;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = (r.author ?? '').isEmpty ? context.t('tourist') : r.author!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border.withValues(alpha: .7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: c.primary.withValues(alpha: .18), child: Text(name.characters.first.toUpperCase(), style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
          Stars(value: r.rating.toDouble(), size: 16),
        ]),
        if ((r.body ?? '').isNotEmpty) ...[const SizedBox(height: 10), Text(r.body!, style: TextStyle(height: 1.45, color: c.text.withValues(alpha: .9)))],
      ]),
    );
  }
}

/// Просмотр фото на весь экран с зумом и свайпом.
class _Viewer extends StatefulWidget {
  const _Viewer({required this.photos, required this.start, required this.api});
  final List<PlacePhoto> photos;
  final int start;
  final dynamic api;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final PageController _c = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .96),
      body: Stack(children: [
        PageView.builder(
          controller: _c,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(child: CachedNetworkImage(imageUrl: widget.api.media(widget.photos[i].large) as String, fit: BoxFit.contain, imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage, placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 14,
          right: 14,
          child: Row(children: [
            _Glass(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
            const Spacer(),
            Text('${_i + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 18,
          left: 20,
          right: 20,
          child: Text('${widget.photos[_i].author} · ${widget.photos[_i].license}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ),
      ]),
    );
  }
}
