import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';
import 'settings.dart';

/// Хранилище списка мест: загрузка, кэш, ошибки.
class PlacesStore extends ChangeNotifier {
  PlacesStore(this.settings) : api = Api(settings);

  final AppSettings settings;
  final Api api;

  List<Place> places = [];
  bool loading = false;
  bool fromCache = false;
  bool failed = false;

  Future<void> load() async {
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final r = await api.places();
      places = r.places;
      fromCache = r.fromCache;
    } catch (_) {
      failed = places.isEmpty;
    }
    loading = false;
    notifyListeners();
  }

  List<Place> inRegion(String r) => places.where((p) => p.region == r).toList();

  /// Лучшие по рейтингу, затем по числу отзывов.
  List<Place> get top {
    final l = [...places]
      ..sort((a, b) {
        final c = b.ratingAvg.compareTo(a.ratingAvg);
        return c != 0 ? c : b.ratingCount.compareTo(a.ratingCount);
      });
    return l.take(8).toList();
  }
}

class StoreScope extends InheritedNotifier<PlacesStore> {
  const StoreScope({
    super.key,
    required PlacesStore store,
    required super.child,
  }) : super(notifier: store);

  static PlacesStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

extension StoreX on BuildContext {
  PlacesStore get store => StoreScope.of(this);
}
