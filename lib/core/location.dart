import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum LocError { serviceOff, denied, deniedForever, unavailable, timeout }

class LocFix {
  LocFix(this.lat, this.lng, this.accuracy);
  final double lat, lng, accuracy;
}

class LocResult {
  LocResult.ok(this.fix) : error = null;
  LocResult.fail(this.error) : fix = null;
  final LocFix? fix;
  final LocError? error;
}

/// Надёжное определение места:
///  1) проверка службы геолокации и разрешения (с запросом);
///  2) поток GPS высокой точности до 15 секунд, берём лучшую точку (цель ≤ 25 м);
///  3) если GPS молчит (помещение, эмулятор) — запасной режим по сети, чтобы пользователь не застрял.
class Locator {
  static const goodAccuracy = 25.0;

  static Future<LocResult> locate({
    void Function(LocFix interim)? onInterim,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        return LocResult.fail(LocError.serviceOff);

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever)
        return LocResult.fail(LocError.deniedForever);
      if (perm == LocationPermission.denied)
        return LocResult.fail(LocError.denied);

      LocFix? best;
      final done = Completer<LocFix?>();
      late StreamSubscription<Position> sub;
      final timer = Timer(const Duration(seconds: 15), () {
        if (!done.isCompleted) done.complete(best);
      });
      sub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
            ),
          ).listen(
            (p) {
              final f = LocFix(p.latitude, p.longitude, p.accuracy);
              if (best == null || f.accuracy < best!.accuracy) {
                best = f;
                onInterim?.call(f);
              }
              if (f.accuracy <= goodAccuracy && !done.isCompleted)
                done.complete(f);
            },
            onError: (_) {
              if (!done.isCompleted) done.complete(best);
            },
          );
      final fix = await done.future;
      timer.cancel();
      await sub.cancel();
      if (fix != null) return LocResult.ok(fix);

      // Запасной режим
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
        return LocResult.ok(LocFix(p.latitude, p.longitude, p.accuracy));
      } on TimeoutException {
        return LocResult.fail(LocError.timeout);
      }
    } on TimeoutException {
      return LocResult.fail(LocError.timeout);
    } catch (_) {
      return LocResult.fail(LocError.unavailable);
    }
  }

  static Future<void> openSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();
}
