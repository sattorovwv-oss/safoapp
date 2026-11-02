import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/place_cards.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.categoryRequest});

  /// Главный экран может запросить категорию (клик по чипу).
  final ValueNotifier<String?> categoryRequest;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  String? _cat;
  String? _region;
  bool _byRating = false;

  @override
  void initState() {
    super.initState();
    widget.categoryRequest.addListener(_onRequest);
  }

  void _onRequest() {
    final v = widget.categoryRequest.value;
    if (v == null) return;
    setState(() => _cat = v == '_focus' ? _cat : v);
    if (v == '_focus') _focus.requestFocus();
    widget.categoryRequest.value = null;
  }

  @override
  void dispose() {
    widget.categoryRequest.removeListener(_onRequest);
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Place> _filtered(BuildContext context) {
    final l = context.app.lang;
    final q = _q.text.trim().toLowerCase();
    var list = context.store.places.where((p) {
      if (_cat != null && p.category != _cat) return false;
      if (_region != null && p.region != _region) return false;
      if (q.isNotEmpty &&
          !p.name.values.any((n) => n.toLowerCase().contains(q)))
        return false;
      return true;
    }).toList();
    list.sort((a, b) {
      // Душанбе — первым, как на сайте
      final ra = a.region == 'DUSHANBE' ? 0 : 1;
      final rb = b.region == 'DUSHANBE' ? 0 : 1;
      if (_byRating) {
        final r = b.ratingAvg.compareTo(a.ratingAvg);
        if (r != 0) return r;
      }
      if (ra != rb) return ra - rb;
      return a.nameOf(l).compareTo(b.nameOf(l));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final list = _filtered(context);
    final top = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
          child: Text(context.t('nav_explore'), style: context.tt.displaySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  focusNode: _focus,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.t('search'),
                    prefixIcon: Icon(Icons.search_rounded, color: c.primary),
                    suffixIcon: _q.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_q.clear),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: () => setState(() => _byRating = !_byRating),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _byRating ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _byRating ? c.primary : c.border),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: _byRating ? c.onPrimary : c.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CategoryChip(
                  label: context.t('all'),
                  selected: _cat == null,
                  onTap: () => setState(() => _cat = null),
                ),
              ),
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CategoryChip(
                    label: context.cat(cat),
                    icon: catIcon(cat),
                    selected: _cat == cat,
                    onTap: () =>
                        setState(() => _cat = _cat == cat ? null : cat),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            children: [
              for (final r in regions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _RegionPill(
                    label: context.reg(r),
                    selected: _region == r,
                    onTap: () =>
                        setState(() => _region = _region == r ? null : r),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
          child: Text(
            context.t('found', {'n': list.length}),
            style: TextStyle(
              color: c.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            child: list.isEmpty
                ? EmptyState(
                    key: const ValueKey('empty'),
                    icon: Icons.search_off_rounded,
                    title: context.t('nothing'),
                    hint: context.t('nothing_hint'),
                  )
                : ListView.builder(
                    key: ValueKey('${_cat}_${_region}_${_byRating}_${_q.text}'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                    itemCount: list.length,
                    itemBuilder: (_, i) => FadeSlideIn(
                      index: i,
                      offset: 18,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RowPlaceCard(
                          place: list[i],
                          heroTag: 'exp-${list[i].slug}',
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: .18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? c.accent : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place_outlined,
              size: 14,
              color: selected ? c.accent : c.muted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? c.accent : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
