import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/location.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_field.dart';
import 'login_screen.dart';

/// Сообщение о мусоре: 1) место (GPS + запасная карта), 2) до 4 фото, 3) описание.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _desc = TextEditingController();
  final _map = MapController();
  List<XFile> _photos = [];
  LatLng? _pos;
  double? _acc;
  bool _manual = false;
  bool _locating = false;
  LocError? _locError;
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locError = null;
    });
    final res = await Locator.locate(
      onInterim: (f) {
        if (!mounted) return;
        setState(() {
          _pos = LatLng(f.lat, f.lng);
          _acc = f.accuracy;
          _manual = false;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (res.fix != null) {
        _pos = LatLng(res.fix!.lat, res.fix!.lng);
        _acc = res.fix!.accuracy;
        _manual = false;
        _map.move(_pos!, 17);
      } else {
        _locError = res.error;
      }
    });
  }

  String _locMsg(LocError e) => switch (e) {
    LocError.serviceOff => context.t('loc_service_off'),
    LocError.denied => context.t('loc_denied'),
    LocError.deniedForever => context.t('loc_denied_forever'),
    LocError.unavailable => context.t('loc_unavailable'),
    LocError.timeout => context.t('loc_timeout'),
  };

  Future<void> _submit() async {
    if (_pos == null)
      return setState(() => _error = context.t('err_location_required'));
    if (_photos.isEmpty)
      return setState(() => _error = context.t('err_photo_required'));
    if (_desc.text.trim().isEmpty)
      return setState(() => _error = context.t('err_validation'));
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.auth;
    try {
      await auth.api.createReport(
        description: _desc.text.trim(),
        lat: _pos!.latitude,
        lng: _pos!.longitude,
        manual: _manual,
        photos: _photos,
      );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      final k = 'err_${e.code}';
      if (mounted)
        setState(
          () => _error = context.t(k) == k
              ? context.t('err_generic')
              : context.t(k),
        );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final top = MediaQuery.of(context).padding.top;

    if (auth.user == null) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: context.t('report_login_needed'),
        action: PrimaryButton(
          label: context.t('sign_in'),
          icon: Icons.login_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      );
    }
    if (_done) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, _) => Transform.scale(
                  scale: v,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: c.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: .5),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 72,
                      color: c.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.t('report_done_title'),
                style: context.tt.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.t('report_done_text'),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.t('report_title'),
                icon: Icons.add_rounded,
                onTap: () => setState(() {
                  _done = false;
                  _photos = [];
                  _desc.clear();
                }),
              ),
            ],
          ),
        ),
      );
    }

    final meters = _acc?.round();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 130),
      children: [
        FadeSlideIn(
          child: Text(
            context.t('report_title'),
            style: context.tt.displaySmall,
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          index: 1,
          child: _Section(
            n: 1,
            title: context.t('report_step_loc'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _locating
                        ? context.t('loc_searching')
                        : (_pos == null
                              ? context.t('loc_find')
                              : context.t('loc_retry')),
                    icon: _locating
                        ? Icons.hourglass_top_rounded
                        : Icons.my_location_rounded,
                    onTap: () => _locating ? null : _locate(),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    children: [
                      if (meters != null && !_manual)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: (meters <= 100 ? c.primary : c.accent)
                                .withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                meters <= 100
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: meters <= 100 ? c.primary : c.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.t(
                                    meters <= 100 ? 'loc_good' : 'loc_weak',
                                    {'m': meters},
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_locError != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: c.danger.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_off_rounded,
                                    color: c.danger,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _locMsg(_locError!),
                                      style: TextStyle(
                                        color: c.danger,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_locError == LocError.deniedForever ||
                                  _locError == LocError.serviceOff)
                                TextButton(
                                  onPressed: _locError == LocError.serviceOff
                                      ? Locator.openLocationSettings
                                      : Locator.openSettings,
                                  child: Text(context.t('loc_open_settings')),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.t('loc_pick_map'),
                  style: TextStyle(color: c.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 260,
                    child: FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: _pos ?? const LatLng(38.5598, 68.787),
                        initialZoom: _pos == null ? 11 : 17,
                        onTap: (_, p) => setState(() {
                          _pos = p;
                          _manual = true;
                          _acc = null;
                        }),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'tj.safo.safo',
                        ),
                        if (_pos != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pos!,
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
                if (_pos != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}${_manual ? ' · ${context.t('loc_point')}' : ''}',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 2,
          child: _Section(
            n: 2,
            title: context.t('report_step_photos'),
            child: PhotoField(
              files: _photos,
              onChanged: (l) => setState(() => _photos = l),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 3,
          child: _Section(
            n: 3,
            title: context.t('report_step_desc'),
            child: TextField(
              controller: _desc,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: context.t('report_desc_hint'),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: c.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: _busy ? '…' : context.t('report_submit'),
            icon: Icons.send_rounded,
            onTap: () => _busy ? null : _submit(),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.n, required this.title, required this.child});
  final int n;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: c.brand,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: TextStyle(
                      color: c.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: context.tt.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
