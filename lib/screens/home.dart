import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/place_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSearch,
    required this.onCategory,
  });
  final VoidCallback onSearch;
  final void Function(String category) onCategory;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = context.c;
    final capital = store.inRegion('DUSHANBE');
    final others = store.places.where((p) => p.region != 'DUSHANBE').toList();

    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: store.load,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 400,
            stretch: true,
            pinned: false,
            backgroundColor: c.bg,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _Hero(onSearch: onSearch),
            ),
          ),
          if (store.fromCache)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded, color: c.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.t('offline'),
                          style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 62,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                children: [
                  for (final cat in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CategoryChip(
                        label: context.cat(cat),
                        icon: catIcon(cat),
                        selected: false,
                        onTap: () => onCategory(cat),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (store.loading && store.places.isEmpty)
            const SliverToBoxAdapter(child: _Loading())
          else if (store.failed)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: context.t('load_error'),
                action: PrimaryButton(
                  label: context.t('retry'),
                  icon: Icons.refresh_rounded,
                  onTap: store.load,
                ),
              ),
            )
          else ...[
            if (capital.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  context.t('dushanbe'),
                  icon: Icons.location_city_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: _Carousel(places: capital, tag: 'cap'),
              ),
            ],
            if (store.top.any((p) => p.ratingCount > 0)) ...[
              SliverToBoxAdapter(
                child: SectionTitle(context.t('top'), icon: Icons.star_rounded),
              ),
              SliverList.builder(
                itemCount: math.min(5, store.top.length),
                itemBuilder: (_, i) => FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: RowPlaceCard(
                      place: store.top[i],
                      heroTag: 'top-${store.top[i].slug}',
                    ),
                  ),
                ),
              ),
            ],
            if (others.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  context.t('other'),
                  icon: Icons.explore_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    itemCount: math.min(others.length, 16),
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => FadeSlideIn(
                      index: i,
                      child: BigPlaceCard(
                        place: others[i],
                        heroTag: 'oth-${others[i].slug}',
                        width: 250,
                        height: 330,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/hero.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .35),
                Colors.black.withValues(alpha: .05),
                c.bg.withValues(alpha: .65),
                c.bg,
              ],
              stops: const [0, .35, .85, 1],
            ),
          ),
        ),
        Positioned(
          top: top + 14,
          left: 20,
          right: 20,
          child: FadeSlideIn(
            offset: -16,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset('assets/icon.png', width: 40, height: 40),
                ),
                const SizedBox(width: 12),
                Text(
                  context.t('app'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                index: 1,
                child: Text(
                  context.t('hello'),
                  style: context.tt.displaySmall?.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 24, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                index: 2,
                child: Text(
                  context.t('hero_text'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    height: 1.45,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                index: 3,
                child: Pressable(
                  onTap: onSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: c.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.t('search'),
                            style: TextStyle(
                              color: c.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: c.brand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: c.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Карусель с эффектом масштаба и прозрачности соседних карточек.
class _Carousel extends StatefulWidget {
  const _Carousel({required this.places, required this.tag});
  final List<Place> places;
  final String tag;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _c = PageController(viewportFraction: .76);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: _c,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.places.length,
        itemBuilder: (_, i) => AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            var d = 0.0;
            if (_c.position.haveDimensions)
              d = (_c.page! - i).abs().clamp(0.0, 1.0);
            final s = 1 - d * .1;
            return Center(
              child: Opacity(
                opacity: 1 - d * .35,
                child: Transform.scale(scale: s, child: child),
              ),
            );
          },
          child: BigPlaceCard(
            place: widget.places[i],
            heroTag: '${widget.tag}-${widget.places[i].slug}',
            width: 290,
            height: 380,
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
    child: Column(
      children: [
        Shimmer(height: 340, radius: 30),
        SizedBox(height: 16),
        Shimmer(height: 110),
        SizedBox(height: 12),
        Shimmer(height: 110),
      ],
    ),
  );
}
