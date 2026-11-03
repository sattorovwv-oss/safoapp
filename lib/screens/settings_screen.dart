import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/auth.dart';
import 'login_screen.dart';
import '../core/i18n.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onSignedIn});
  final VoidCallback? onSignedIn;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url = TextEditingController(
    text: context.app.baseUrl,
  );
  bool _testing = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save({bool test = false}) async {
    final app = context.app;
    final store = context.store;
    final msg = ScaffoldMessenger.of(context);
    final saved = context.t('saved');
    final ok = context.t('ok');
    final fail = context.t('load_error');
    await app.setBaseUrl(_url.text);
    _url.text = app.baseUrl;
    if (test) {
      setState(() => _testing = true);
      final good = await Api(app).ping();
      if (!mounted) return;
      setState(() => _testing = false);
      msg.showSnackBar(SnackBar(content: Text(good ? ok : fail)));
      if (good) store.load();
    } else {
      msg.showSnackBar(SnackBar(content: Text(saved)));
      store.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final app = context.app;
    final top = MediaQuery.of(context).padding.top;
    const names = {'tg': 'Тоҷикӣ', 'ru': 'Русский', 'en': 'English'};

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 130),
      children: [
        FadeSlideIn(
          child: Text(
            context.t('nav_settings'),
            style: context.tt.displaySmall,
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          index: 1,
          child: _AccountCard(onSignedIn: widget.onSignedIn),
        ),
        FadeSlideIn(
          index: 1,
          child: _Card(
            icon: Icons.language_rounded,
            title: context.t('language'),
            child: _Segmented<String>(
              value: app.lang,
              items: {for (final l in supportedLangs) l: names[l]!},
              onChanged: app.setLang,
            ),
          ),
        ),
        FadeSlideIn(
          index: 2,
          child: _Card(
            icon: Icons.brightness_6_rounded,
            title: context.t('theme'),
            child: _Segmented<ThemeMode>(
              value: app.themeMode,
              items: {
                ThemeMode.system: context.t('theme_system'),
                ThemeMode.light: context.t('theme_light'),
                ThemeMode.dark: context.t('theme_dark'),
              },
              onChanged: app.setTheme,
            ),
          ),
        ),
        FadeSlideIn(
          index: 3,
          child: _Card(
            icon: Icons.dns_rounded,
            title: context.t('server'),
            child: Column(
              children: [
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: context.t('server_hint'),
                    prefixIcon: Icon(Icons.link_rounded, color: c.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        outlined: true,
                        label: context.t('check'),
                        icon: _testing
                            ? Icons.hourglass_top_rounded
                            : Icons.wifi_tethering_rounded,
                        onTap: () => _testing ? null : _save(test: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: context.t('save'),
                        icon: Icons.check_rounded,
                        onTap: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          index: 4,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/icon.png', width: 64, height: 64),
              ),
              const SizedBox(height: 12),
              Text(context.t('app'), style: context.tt.titleLarge),
              const SizedBox(height: 4),
              Text(context.t('tagline'), style: TextStyle(color: c.muted)),
              const SizedBox(height: 4),
              Text(
                '${context.t('version')} 1.0.0',
                style: TextStyle(
                  color: c.muted.withValues(alpha: .7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 19, color: c.primary),
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

/// Сегментированный переключатель с плавным «ползунком».
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final keys = items.keys.toList();
    final idx = keys.indexOf(value).clamp(0, keys.length - 1);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (_, box) {
          final w = box.maxWidth / keys.length;
          return SizedBox(
            height: 44,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: idx * w,
                  width: w,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: c.brand,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: .3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final k in keys)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(k),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 240),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: k == value ? c.onPrimary : c.muted,
                              ),
                              child: Text(
                                items[k]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({this.onSignedIn});
  final VoidCallback? onSignedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.auth;
    final u = auth.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: u == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary.withValues(alpha: .22), c.surface],
              ),
        color: u == null ? c.surface : null,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: u == null
              ? c.border.withValues(alpha: .7)
              : c.primary.withValues(alpha: .5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: c.brand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  u == null
                      ? Icons.person_outline_rounded
                      : Icons.verified_user_rounded,
                  color: c.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u?.name ?? context.t('guest'),
                      style: context.tt.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u == null ? context.t('guest_hint') : u.role,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (auth.isCommittee) ...[
            SizedBox(
              width: double.infinity,

              child: PrimaryButton(
                label: context.t('open_panel'),

                icon: Icons.dashboard_rounded,

                onTap: () => launchUrl(
                  Uri.parse('${context.app.baseUrl}/committee'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: u == null
                ? PrimaryButton(
                    label: context.t('sign_in'),
                    icon: Icons.login_rounded,
                    onTap: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      if (ok == true &&
                          context.mounted &&
                          context.auth.isCleaner)
                        onSignedIn?.call();
                    },
                  )
                : PrimaryButton(
                    outlined: true,
                    label: context.t('sign_out'),
                    icon: Icons.logout_rounded,
                    onTap: auth.logout,
                  ),
          ),
        ],
      ),
    );
  }
}
