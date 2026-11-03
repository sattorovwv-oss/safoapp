import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'api.dart';
import 'auth.dart';

/// Фото «после» тозакунанда, которое ждёт интернета.
class QueuedUpload {
  QueuedUpload({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.note,
    required this.paths,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id, userId, reportId, note;
  final List<String> paths;
  final DateTime createdAt;
  int attempts;
  String? lastError;

  /// Только для веба (там нет файловой системы): фото хранятся в памяти.
  List<XFile>? memoryFiles;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'reportId': reportId,
    'note': note,
    'paths': paths,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
    'lastError': lastError,
  };

  factory QueuedUpload.fromJson(Map<String, dynamic> j) => QueuedUpload(
    id: j['id'] as String,
    userId: j['userId'] as String,
    reportId: j['reportId'] as String,
    note: (j['note'] ?? '') as String,
    paths: [for (final p in (j['paths'] as List)) p as String],
    createdAt: DateTime.parse(j['createdAt'] as String),
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
    lastError: j['lastError'] as String?,
  );
}

/// Очередь отправки без интернета. Фото сохраняются в папке приложения и уходят сами,
/// как только появится связь (проверка каждые 25 секунд, пока приложение открыто, и при каждом запуске).
class OfflineQueue extends ChangeNotifier {
  OfflineQueue(this.auth) {
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => process());
  }

  final AuthStore auth;
  final List<QueuedUpload> _items = [];
  Timer? _timer;
  bool _busy = false;
  bool _loaded = false;

  /// Сколько заданий отправлено в фоне (для сообщения пользователю)
  int sentCount = 0;

  List<QueuedUpload> get items {
    final uid = auth.user?.id;
    return [
      for (final i in _items)
        if (i.userId == uid) i,
    ];
  }

  int get pending => items.length;
  bool get busy => _busy;
  bool hasFor(String reportId) => items.any((i) => i.reportId == reportId);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File?> _indexFile() async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/safo_queue.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = await _indexFile();
      if (f != null && await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        for (final j in list) {
          final q = QueuedUpload.fromJson((j as Map).cast<String, dynamic>());
          // Если файлы пропали — не держим «пустое» задание
          if (q.paths.every((p) => File(p).existsSync())) _items.add(q);
        }
      }
    } catch (_) {}
    notifyListeners();
    unawaited(process());
  }

  Future<void> _save() async {
    try {
      final f = await _indexFile();
      if (f != null)
        await f.writeAsString(jsonEncode([for (final i in _items) i.toJson()]));
    } catch (_) {}
  }

  /// Сохраняем фото на телефоне и ставим в очередь.
  Future<void> enqueue(String reportId, List<XFile> photos, String note) async {
    final uid = auth.user?.id;
    if (uid == null) return;
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final paths = <String>[];
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      for (var i = 0; i < photos.length; i++) {
        final p = '${dir.path}/safo_q_${id}_$i.jpg';
        await File(p).writeAsBytes(await photos[i].readAsBytes(), flush: true);
        paths.add(p);
      }
    }
    final q = QueuedUpload(
      id: id,
      userId: uid,
      reportId: reportId,
      note: note,
      paths: paths,
      createdAt: DateTime.now(),
    );
    if (kIsWeb) q.memoryFiles = photos;
    _items.add(q);
    await _save();
    notifyListeners();
  }

  Future<void> _remove(QueuedUpload q) async {
    _items.remove(q);
    for (final p in q.paths) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
    await _save();
  }

  /// Пробуем отправить всё, что накопилось. Останавливаемся при первой же потере связи.
  Future<void> process() async {
    if (_busy || auth.user == null || items.isEmpty) return;
    _busy = true;
    notifyListeners();
    for (final q in [...items]) {
      final files = q.memoryFiles ?? [for (final p in q.paths) XFile(p)];
      try {
        await auth.api.complete(q.reportId, files, note: q.note);
        await _remove(q);
        sentCount++;
      } on ApiException catch (e) {
        if (e.code == 'network') {
          q.lastError = 'network';
          break; // нет связи — попробуем позже
        }
        q.attempts++;
        q.lastError = e.code;
        // Окончательные отказы (место уже убрано/не ваше) — нет смысла повторять
        if (const {
              'forbidden',
              'not_found',
              'report_closed',
              'photo_required',
              'too_many_photos',
            }.contains(e.code) ||
            q.attempts >= 5) {
          await _remove(q);
        }
      }
    }
    _busy = false;
    await _save();
    notifyListeners();
  }
}

class QueueScope extends InheritedNotifier<OfflineQueue> {
  const QueueScope({
    super.key,
    required OfflineQueue queue,
    required super.child,
  }) : super(notifier: queue);

  static OfflineQueue of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QueueScope>()!.notifier!;
}

extension QueueX on BuildContext {
  OfflineQueue get queue => QueueScope.of(this);
}
