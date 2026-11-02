import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/models_social.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_field.dart';
import 'login_screen.dart';

/// Субботники махалли. Житель: участвую / не смогу / фото. Председатель: статистика участников.
class SubbotniksScreen extends StatefulWidget {
  const SubbotniksScreen({super.key});

  @override
  State<SubbotniksScreen> createState() => _SubbotniksScreenState();
}

class _SubbotniksScreenState extends State<SubbotniksScreen> {
  SubbotnikData? _data;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null &&
        !_loading &&
        _error == null &&
        (context.auth.isResident || context.auth.isChairman))
      _load();
  }

  Future<void> _load() async {
    final auth = context.auth;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await auth.api.subbotniks();
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _err(String code) {
    final k = 'err_$code';
    return context.t(k) == k ? context.t('err_generic') : context.t(k);
  }

  Future<void> _open(Subbotnik s) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(s: s, data: _data!, errText: _err),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final top = MediaQuery.of(context).padding.top;

    if (!(auth.isResident || auth.isChairman)) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: context.t('login_needed_title'),
        hint: context.t('login_needed_text'),
        action: PrimaryButton(
          label: context.t('sign_in'),
          icon: Icons.login_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      );
    }
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
            child: Text(context.t('sub_title'), style: context.tt.displaySmall),
          ),
          if (d != null) ...[
            const SizedBox(height: 6),
            Text(
              d.mahalla,
              style: TextStyle(color: c.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  icon: Icons.emoji_events_rounded,
                  text: context.t('sub_rating', {'p': d.rating}),
                ),
                if (d.role == 'RESIDENT')
                  _Chip(
                    icon: Icons.do_not_disturb_on_rounded,
                    text: context.t('sub_refusals', {
                      'n': d.refusalsUsed,
                      'max': d.refusalLimit,
                    }),
                    warn: d.refusalsUsed >= d.refusalLimit - 1,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (_loading && d == null) ...const [
            Shimmer(height: 130),
            SizedBox(height: 12),
            Shimmer(height: 130),
          ] else if (_error != null && d == null)
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: _err(_error!),
              action: PrimaryButton(
                label: context.t('retry'),
                icon: Icons.refresh_rounded,
                onTap: _load,
              ),
            )
          else if (d != null && d.items.isEmpty)
            EmptyState(
              icon: Icons.event_busy_rounded,
              title: context.t('sub_empty'),
            )
          else if (d != null)
            for (var i = 0; i < d.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  index: i,
                  child: _Card(
                    s: d.items[i],
                    chairman: d.role == 'CHAIRMAN',
                    residents: d.residents,
                    onTap: () => _open(d.items[i]),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.warn = false});
  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = warn ? c.accent : c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: col),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: col,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';
String fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String fmtDT(DateTime d) => '${_two(d.day)}.${_two(d.month)} ${fmtTime(d)}';

Color _stateColor(BuildContext context, String? s) {
  final c = context.c;
  return switch (s) {
    'PHOTO_ACCEPTED' => c.primary,
    'PARTICIPATING' || 'PHOTO_SENT' => c.accent,
    'REFUSED' || 'PHOTO_REJECTED' || 'MUST_APPEAR' => c.danger,
    _ => c.muted,
  };
}

class _Card extends StatelessWidget {
  const _Card({
    required this.s,
    required this.chairman,
    required this.residents,
    required this.onTap,
  });
  final Subbotnik s;
  final bool chairman;
  final int residents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cancelled = s.status == 'CANCELLED';
    return Pressable(
      onTap: onTap,
      scale: .98,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: c.brand,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${s.date.day}',
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        _two(s.date.month),
                        style: TextStyle(
                          color: c.onPrimary.withValues(alpha: .85),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.titleMedium?.copyWith(
                          decoration: cancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: c.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fmtTime(s.startsAt),
                            style: TextStyle(
                              color: c.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.place_rounded, size: 14, color: c.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (chairman)
              Row(
                children: [
                  _Stat(
                    label: context.t('sub_stats_participate'),
                    value: '${s.participate}/$residents',
                  ),
                  _Stat(
                    label: context.t('sub_stats_refused'),
                    value: '${s.refused}',
                  ),
                  _Stat(
                    label: context.t('sub_stats_accepted'),
                    value: '${s.accepted}',
                  ),
                ],
              )
            else if (cancelled)
              _StateBadge(text: context.t('status_CANCELLED'), color: c.danger)
            else
              _StateBadge(
                text: context.t('state_${s.state ?? 'NO_RESPONSE'}'),
                color: _stateColor(context, s.state),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: c.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: c.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 12.5,
      ),
    ),
  );
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({
    required this.s,
    required this.data,
    required this.errText,
  });
  final Subbotnik s;
  final SubbotnikData data;
  final String Function(String) errText;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  List<XFile> _photos = [];
  final _reason = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _ok = false;

  Subbotnik get s => widget.s;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job, {String? okText}) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await job();
      if (!mounted) return;
      setState(() {
        _ok = true;
        _msg = okText;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
      return;
    } on ApiException catch (e) {
      if (mounted) setState(() => _msg = widget.errText(e.code));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _refuse() async {
    final last = widget.data.refusalsUsed >= widget.data.refusalLimit - 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('sub_refuse_confirm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (last)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ctx.t('sub_last_refusal_warn'),
                  style: TextStyle(
                    color: ctx.c.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            TextField(
              controller: _reason,
              decoration: InputDecoration(hintText: ctx.t('sub_reason_hint')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('no')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('yes')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final auth = context.auth;
    await _run(
      () => auth.api.respondSubbotnik(s.id, false, reason: _reason.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final resident = auth.isResident;
    final state = s.state ?? 'NO_RESPONSE';
    final open = s.status == 'PLANNED';
    final canAnswer =
        resident &&
        open &&
        (state == 'NO_RESPONSE' ||
            state == 'PARTICIPATING' ||
            state == 'REFUSED' ||
            state == 'MUST_APPEAR');
    final canPhoto =
        resident &&
        open &&
        s.photoWindowOpen &&
        (state == 'PARTICIPATING' ||
            state == 'PHOTO_REJECTED' ||
            state == 'PHOTO_SENT' ||
            state == 'NO_RESPONSE');

    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .5,
      maxChildSize: .96,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(s.title, style: context.tt.headlineMedium),
            const SizedBox(height: 14),
            _Row(
              icon: Icons.event_rounded,
              label: context.t('sub_when'),
              value: '${fmtDate(s.date)}, ${fmtTime(s.startsAt)}',
            ),
            _Row(
              icon: Icons.place_rounded,
              label: context.t('sub_where'),
              value: s.location,
            ),
            _Row(
              icon: Icons.photo_camera_rounded,
              label: context.t('photos'),
              value: context.t('sub_photo_window', {
                'from': fmtDT(s.photoFrom),
                'to': fmtDT(s.photoUntil),
              }),
            ),
            if (s.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                s.description,
                style: TextStyle(
                  height: 1.5,
                  color: c.text.withValues(alpha: .9),
                ),
              ),
            ],
            if (resident) ...[
              const SizedBox(height: 16),
              _StateBadge(
                text: context.t('state_$state'),
                color: _stateColor(context, state),
              ),
              if (s.photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in s.photos)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.status == 'ACCEPTED'
                                  ? c.primary
                                  : (p.status == 'REJECTED'
                                        ? c.danger
                                        : c.border),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _Thumb(path: p.thumb),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
            if (canAnswer) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: context.t('sub_participate'),
                      icon: Icons.check_circle_rounded,
                      onTap: () => _busy
                          ? null
                          : _run(() => auth.api.respondSubbotnik(s.id, true)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      outlined: true,
                      label: context.t('sub_refuse'),
                      icon: Icons.cancel_rounded,
                      onTap: () => _busy ? null : _refuse(),
                    ),
                  ),
                ],
              ),
            ],
            if (canPhoto) ...[
              const SizedBox(height: 20),
              PhotoField(
                files: _photos,
                max: 4,
                onChanged: (l) => setState(() => _photos = l),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: context.t('sub_send_photos'),
                  icon: Icons.cloud_upload_rounded,
                  onTap: () => _busy || _photos.isEmpty
                      ? null
                      : _run(
                          () => auth.api.sendSubbotnikPhotos(s.id, _photos),
                          okText: context.t('sub_sent_ok'),
                        ),
                ),
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              child: _msg == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (_ok ? c.primary : c.danger).withValues(
                          alpha: .13,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _msg!,
                        style: TextStyle(
                          color: _ok ? c.primary : c.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final api = context.auth.api;
    return Image.network(
      api.media(path),
      headers: api.authHeaders,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: context.c.surface2,
        child: Icon(Icons.image_not_supported_outlined, color: context.c.muted),
      ),
    );
  }
}
