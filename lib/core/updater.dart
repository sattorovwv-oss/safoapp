import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings.dart';
import 'theme.dart';

/// Проверка обновлений. Каждая подписанная сборка публикуется в GitHub Release вместе с version.json:
/// {"build": 12, "name": "1.0.12", "url": ".../safo.apk"}. Если build новее установленного — предлагаем обновить.
class Updater {
  static const _manifest =
      'https://github.com/sattorovwv-oss/safoapp/releases/latest/download/version.json';

  static bool _checked = false;

  static Future<void> check(BuildContext context) async {
    if (_checked || kIsWeb) return;
    _checked = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final local = int.tryParse(info.buildNumber) ?? 0;
      final r = await http
          .get(Uri.parse(_manifest))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final remote = (j['build'] as num?)?.toInt() ?? 0;
      final url = j['url'] as String?;
      final name = (j['name'] as String?) ?? '$remote';
      if (remote <= local || url == null || !url.startsWith('https://')) return;

      // «Позже» — не напоминаем об этой же версии сутки
      final prefs = await SharedPreferences.getInstance();
      final snoozedBuild = prefs.getInt('upd_snooze_build') ?? 0;
      final snoozedAt = prefs.getInt('upd_snooze_at') ?? 0;
      final day = DateTime.now().millisecondsSinceEpoch - snoozedAt < 86400000;
      if (snoozedBuild == remote && day) return;
      if (!context.mounted) return;

      final update = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final c = ctx.c;
          return AlertDialog(
            icon: Icon(Icons.system_update_rounded, color: c.primary, size: 40),
            title: Text(ctx.t('update_title')),
            content: Text(
              ctx.t('update_text', {'v': name}),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, height: 1.4),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.t('update_later')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.download_rounded),
                label: Text(ctx.t('update_now')),
              ),
            ],
          );
        },
      );
      if (update == true) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        await prefs.setInt('upd_snooze_build', remote);
        await prefs.setInt(
          'upd_snooze_at',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      // нет интернета или GitHub недоступен — тихо пропускаем, проверим при следующем запуске
    }
  }
}
