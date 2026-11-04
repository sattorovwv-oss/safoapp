import 'package:flutter/material.dart';
import '../core/auth.dart';
import '../core/models_social.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Вход: «Житель» (махалля + номер дома) или «Сотрудник / турист» (логин). Крупные поля, понятные ошибки.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _house = TextEditingController();
  final _pass = TextEditingController();
  bool _resident = false;
  bool _busy = false;
  bool _show = false;
  String? _error;
  List<MahallaItem> _mahallas = [];
  String? _mahallaId;
  bool _google = false; // нажали «Войти через Google» и ждём возврата из браузера

  @override
  void dispose() {
    _login.dispose();
    _house.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _loadMahallas() async {
    if (_mahallas.isNotEmpty) return;
    final auth = context.auth;
    try {
      final l = await auth.api.mahallas();
      if (mounted) setState(() => _mahallas = l);
    } catch (_) {
      if (mounted) setState(() => _error = context.t('err_network'));
    }
  }

  Future<void> _submit() async {
    final ok = _resident
        ? (_mahallaId != null &&
              _house.text.trim().isNotEmpty &&
              _pass.text.isNotEmpty)
        : (_login.text.trim().isNotEmpty && _pass.text.isNotEmpty);
    if (!ok) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.auth;
    final err = _resident
        ? await auth.loginResident(_mahallaId!, _house.text, _pass.text)
        : await auth.login(_login.text, _pass.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      final k = 'err_$err';
      setState(
        () => _error = context.t(k) == k
            ? context.t('err_generic')
            : context.t(k),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    if (_google && auth.user != null) {
      _google = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
    final gErr = _google && !auth.googleWaiting ? auth.googleError : null;
    final shownError =
        _error ??
        (gErr == null
            ? null
            : (context.t('err_$gErr') == 'err_$gErr'
                  ? context.t('err_failed')
                  : context.t('err_$gErr')));
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.9),
                  radius: 1.2,
                  colors: [c.primary.withValues(alpha: .25), c.bg],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: .45),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 92,
                          height: 92,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  index: 1,
                  child: Text(
                    context.t('sign_in'),
                    textAlign: TextAlign.center,
                    style: context.tt.headlineMedium,
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  index: 2,
                  child: _GoogleButton(
                    label: auth.googleWaiting && _google
                        ? context.t('google_waiting')
                        : context.t('google_sign_in'),
                    onTap: auth.googleWaiting && _google
                        ? null
                        : () {
                            setState(() {
                              _google = true;
                              _error = null;
                            });
                            auth.startGoogle();
                          },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    context.t('google_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        context.t('or_word').toUpperCase(),
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: c.border)),
                  ],
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 3,
                  child: _Switch(
                    resident: _resident,
                    left: context.t('login_staff'),
                    right: context.t('login_resident'),
                    onChanged: (v) {
                      setState(() {
                        _resident = v;
                        _error = null;
                      });
                      if (v) _loadMahallas();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    context.t('sign_in_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, height: 1.4, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _resident
                      ? Column(
                          key: const ValueKey('res'),
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _mahallaId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.t('mahalla'),
                                prefixIcon: Icon(
                                  Icons.location_city_rounded,
                                  color: c.primary,
                                ),
                              ),
                              hint: Text(context.t('choose_mahalla')),
                              items: [
                                for (final m in _mahallas)
                                  DropdownMenuItem(
                                    value: m.id,
                                    child: Text(
                                      '${m.city} · ${m.name}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _mahallaId = v),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _house,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.t('house'),
                                prefixIcon: Icon(
                                  Icons.home_rounded,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : TextField(
                          key: const ValueKey('staff'),
                          controller: _login,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: context.t('username'),
                            prefixIcon: Icon(
                              Icons.person_rounded,
                              color: c.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pass,
                  obscureText: !_show,
                  onSubmitted: (_) => _submit(),
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: context.t('password'),
                    prefixIcon: Icon(Icons.lock_rounded, color: c.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _show
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () => setState(() => _show = !_show),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: shownError == null
                      ? const SizedBox(width: double.infinity)
                      : Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.danger.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: c.danger.withValues(alpha: .4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: c.danger,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  shownError,
                                  style: TextStyle(
                                    color: c.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _busy ? '…' : context.t('sign_in'),
                    icon: Icons.login_rounded,
                    onTap: () => _busy ? null : _submit(),
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

class _Switch extends StatelessWidget {
  const _Switch({
    required this.resident,
    required this.left,
    required this.right,
    required this.onChanged,
  });
  final bool resident;
  final String left, right;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (_, box) {
          final w = box.maxWidth / 2;
          return SizedBox(
            height: 46,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: resident ? w : 0,
                  width: w,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: c.brand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, label) in [left, right].indexed)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i == 1),
                          child: Center(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: (i == 1) == resident
                                    ? c.onPrimary
                                    : c.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Белая кнопка Google с цветной «G» (без картинок: буква с градиентом в цветах Google).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (r) => const SweepGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF34A853),
                    Color(0xFFFBBC05),
                    Color(0xFFEA4335),
                    Color(0xFF4285F4),
                  ],
                ).createShader(r),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (onTap == null) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
