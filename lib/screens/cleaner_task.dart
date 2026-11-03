import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/offline_queue.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_field.dart';
import '../widgets/steps.dart';

/// Задание: 1) взять, 2) убрать и 3) отправить фото. Каждый шаг — одна крупная кнопка.
class CleanerTaskScreen extends StatefulWidget {
  const CleanerTaskScreen({super.key, required this.report});
  final CleanerReport report;

  @override
  State<CleanerTaskScreen> createState() => _CleanerTaskScreenState();
}

class _CleanerTaskScreenState extends State<CleanerTaskScreen> {
  late String _status = widget.report.status;
  final _note = TextEditingController();
  List<XFile> _shots = [];
  bool _busy = false;
  bool _uploading = false;
  bool _done = false;
  bool _offlineSaved = false;

  CleanerReport get r => widget.report;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _err(Object e) {
    final code = e is ApiException ? e.code : 'generic';
    final key = 'err_$code';
    final s = context.t(key);
    return s == key ? context.t('err_generic') : s;
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final auth = context.auth;
    final msg = context;
    try {
      await auth.api.claim(r.id);
      if (!mounted) return;
      setState(() => _status = 'IN_PROGRESS');
    } catch (e) {
      if (msg.mounted) _toast(_err(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _release() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('confirm_release')),
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
    setState(() => _busy = true);
    final auth = context.auth;
    try {
      await auth.api.release(r.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    } catch (e) {
      if (mounted) _toast(_err(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendPhoto() async {
    if (_shots.isEmpty) {
      _toast(context.t('err_photo_required'));
      return;
    }
    final shots = _shots;
    if (!mounted) return;
    setState(() => _uploading = true);
    final auth = context.auth;
    final queue = context.queue;
    try {
      // Нет интернета — сохраняем фото на телефоне, отправим автоматически позже
      if (!await auth.api.reachable()) throw ApiException('network');
      await auth.api.complete(r.id, shots, note: _note.text);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _done = true;
        _status = 'CLEANED';
      });
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'network') {
        await queue.enqueue(r.id, shots, _note.text);
        if (!mounted) return;
        setState(() {
          _uploading = false;
          _done = true;
          _offlineSaved = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 2600));
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _uploading = false);
      _toast(_err(e));
    }
  }

  Future<void> _navigate() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final api = context.auth.api;
    final top = MediaQuery.of(context).padding.top;
    final current = _status == 'NEW' ? 1 : (_status == 'IN_PROGRESS' ? 2 : 4);
    final hint = _status == 'NEW'
        ? 'hint_new'
        : (_status == 'IN_PROGRESS' ? 'hint_progress' : 'hint_done');
    final photo = r.firstPhoto;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 40),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('my_task'),
                      style: context.tt.headlineMedium?.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: c.border.withValues(alpha: .7)),
                  ),
                  child: Column(
                    children: [
                      StepsBar(current: current),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: Container(
                          key: ValueKey(hint),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            context.t(hint),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (photo != null)
                FadeSlideIn(
                  index: 1,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, _, _) => _FullPhoto(
                          url: api.media(photo.url),
                          headers: api.authHeaders,
                        ),
                        transitionsBuilder: (_, a, _, ch) =>
                            FadeTransition(opacity: a, child: ch),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: CachedNetworkImage(
                          imageUrl: api.media(photo.url),
                          httpHeaders: api.authHeaders,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: c.surface2),
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
                  ),
                ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 2,
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
                      Text(
                        r.description,
                        style: context.tt.titleMedium?.copyWith(
                          fontSize: 18,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 16, color: c.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                            style: TextStyle(
                              color: c.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(r.lat, r.lng),
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'tj.safo.safo',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(r.lat, r.lng),
                              width: 50,
                              height: 56,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 50,
                                color: c.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  outlined: true,
                  label: context.t('navigate'),
                  icon: Icons.navigation_rounded,
                  onTap: _navigate,
                ),
              ),
              const SizedBox(height: 22),
              if (_status == 'NEW')
                _BigButton(
                  label: context.t('take'),
                  icon: Icons.back_hand_rounded,
                  busy: _busy,
                  onTap: _claim,
                ),
              if (_status == 'IN_PROGRESS') ...[
                PhotoField(
                  files: _shots,
                  onChanged: (l) => setState(() => _shots = l),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: context.t('note_hint'),
                    prefixIcon: Icon(Icons.edit_note_rounded, color: c.primary),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                _BigButton(
                  label: context.t('send_photo'),
                  icon: Icons.check_rounded,
                  busy: _busy,
                  onTap: _sendPhoto,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    outlined: true,
                    label: context.t('release'),
                    icon: Icons.undo_rounded,
                    onTap: () => _busy ? null : _release(),
                  ),
                ),
              ],
            ],
          ),
          if (_uploading) const _Overlay(),
          if (_done) _Success(offline: _offlineSaved),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.busy = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: busy ? null : onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: c.brand,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: .42),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: c.onPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 28, color: c.onPrimary),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: .6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.primary),
                const SizedBox(height: 18),
                Text(context.t('uploading'), style: context.tt.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Анимация успеха: зелёный круг с галочкой «выпрыгивает».
class _Success extends StatelessWidget {
  const _Success({this.offline = false});
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned.fill(
      child: ColoredBox(
        color: c.bg.withValues(alpha: .97),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (_, v, _) => Transform.scale(
              scale: v,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: c.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: .5),
                          blurRadius: 50,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 80,
                      color: c.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.t(offline ? 'offline_saved_title' : 'done_title'),
                    textAlign: TextAlign.center,
                    style: context.tt.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      context.t(offline ? 'offline_saved_text' : 'done_text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.url, required this.headers});
  final String url;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .95),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}
