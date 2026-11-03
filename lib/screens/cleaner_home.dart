import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/models.dart';
import '../core/offline_queue.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/steps.dart';
import 'cleaner_task.dart';

/// Главный экран тозакунанда: статистика, текущее задание, список грязных мест.
class CleanerHomeScreen extends StatefulWidget {
  const CleanerHomeScreen({super.key});

  @override
  State<CleanerHomeScreen> createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends State<CleanerHomeScreen> {
  CleanerData? _data;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null && _loading && _error == null) _load();
  }

  Future<void> _load() async {
    final auth = context.auth;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await auth.api.cleanerReports();
      if (!mounted) return;
      setState(() => _data = d);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(CleanerReport r) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => CleanerTaskScreen(report: r),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final top = MediaQuery.of(context).padding.top;
    final d = _data;

    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _load,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20, top + 16, 20, 130),
        children: [
          FadeSlideIn(
            child: _Header(
              name: auth.user?.name ?? '',
              today: d?.today ?? 0,
              total: d?.total ?? 0,
              open: d?.open.length ?? 0,
            ),
          ),
          const SizedBox(height: 18),
          _QueueBanner(),
          if (d != null && d.fromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: c.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t('offline_cached'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading && d == null) ...const [
            Shimmer(height: 120),
            SizedBox(height: 14),
            Shimmer(height: 120),
          ] else if (_error != null && d == null)
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: context.t(
                _error == 'network' ? 'err_network' : 'err_generic',
              ),
              action: PrimaryButton(
                label: context.t('retry'),
                icon: Icons.refresh_rounded,
                onTap: _load,
              ),
            )
          else if (d != null) ...[
            FadeSlideIn(
              index: 1,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.border.withValues(alpha: .7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('how'), style: context.tt.titleMedium),
                    const SizedBox(height: 16),
                    StepsBar(current: d.mine.isNotEmpty ? 2 : 1),
                  ],
                ),
              ),
            ),
            if (d.mine.isNotEmpty) ...[
              SectionTitle(context.t('my_task'), icon: Icons.bolt_rounded),
              for (var i = 0; i < d.mine.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeSlideIn(
                    index: i,
                    child: _TaskTile(
                      r: d.mine[i],
                      highlight: true,
                      onTap: () => _open(d.mine[i]),
                    ),
                  ),
                ),
            ],
            SectionTitle(
              context.t('available'),
              icon: Icons.delete_outline_rounded,
            ),
            if (d.open.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.border.withValues(alpha: .7)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 52,
                      color: c.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.t('empty_tasks'),
                      textAlign: TextAlign.center,
                      style: context.tt.titleMedium,
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < d.open.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeSlideIn(
                    index: i,
                    child: _TaskTile(
                      r: d.open[i],
                      onTap: () => _open(d.open[i]),
                    ),
                  ),
                ),
            if (d.done.isNotEmpty) ...[
              SectionTitle(context.t('done_list'), icon: Icons.history_rounded),
              for (final r in d.done.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskTile(r: r, compact: true, onTap: () => _open(r)),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.today,
    required this.total,
    required this.open,
  });
  final String name;
  final int today, total, open;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, const Color(0xFF047857)],
        ),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: .35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('hello_user', {'name': name}),
            style: TextStyle(
              color: c.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(value: today, label: context.t('stat_today')),
              const SizedBox(width: 10),
              _Stat(value: total, label: context.t('stat_total')),
              const SizedBox(width: 10),
              _Stat(value: open, label: context.t('stat_open')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text(
                v.round().toString(),
                style: TextStyle(
                  color: c.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: c.onPrimary.withValues(alpha: .85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.r,
    required this.onTap,
    this.highlight = false,
    this.compact = false,
  });
  final CleanerReport r;
  final VoidCallback onTap;
  final bool highlight, compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final api = context.auth.api;
    final thumb = r.firstPhoto?.thumb;
    final size = compact ? 64.0 : 92.0;
    return Pressable(
      onTap: onTap,
      scale: .975,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlight ? c.accent.withValues(alpha: .1) : c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlight
                ? c.accent.withValues(alpha: .7)
                : c.border.withValues(alpha: .7),
            width: highlight ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: size,
                height: size,
                child: thumb == null
                    ? Container(
                        color: c.surface2,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: c.muted,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: api.media(thumb),
                        httpHeaders: api.authHeaders,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: c.surface2,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: c.muted,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBadge(status: r.status),
                  const SizedBox(height: 6),
                  Text(
                    r.description,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: c.muted),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(r.claimedAt ?? r.createdAt),
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = status == 'CLEANED'
        ? c.primary
        : (status == 'IN_PROGRESS' ? c.accent : c.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.t('status_$status'),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// Сколько фото ждут интернета, с кнопкой «Отправить сейчас».
class _QueueBanner extends StatelessWidget {
  const _QueueBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = context.queue;
    if (q.pending == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.accent.withValues(alpha: .6)),
        ),
        child: Row(
          children: [
            q.busy
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: c.accent,
                    ),
                  )
                : Icon(Icons.cloud_upload_rounded, color: c.accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('pending_uploads', {'n': q.pending}),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    context.t('pending_hint'),
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: q.busy ? null : q.process,
              child: Text(context.t('send_now')),
            ),
          ],
        ),
      ),
    );
  }
}
