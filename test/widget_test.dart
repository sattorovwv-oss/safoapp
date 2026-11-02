import 'package:flutter_test/flutter_test.dart';
import 'package:safo/core/i18n.dart';
import 'package:safo/core/models.dart';

void main() {
  test('переводы: все ключи tg есть в ru и en', () {
    for (final k in ['app', 'nav_home', 'dushanbe', 'cat_HISTORICAL', 'reg_DUSHANBE']) {
      for (final l in supportedLangs) {
        expect(tr(l, k), isNot(k), reason: '$l/$k');
      }
    }
    expect(tr('ru', 'found', {'n': 5}), contains('5'));
  });

  test('Place.fromJson читает ответ API', () {
    final p = Place.fromJson({
      'id': '1',
      'slug': 'hisor',
      'name': {'tg': 'Ҳисор', 'ru': 'Гиссар', 'en': 'Hisor'},
      'desc': {'tg': 'a', 'ru': 'b', 'en': 'c'},
      'bestTime': {'tg': null, 'ru': null, 'en': null},
      'category': 'HISTORICAL',
      'region': 'DUSHANBE',
      'lat': 38.5,
      'lng': 68.6,
      'address': null,
      'hours': null,
      'price': null,
      'mapsUrl': null,
      'ratingAvg': 4.5,
      'ratingCount': 2,
      'photos': [
        {'thumb': '/t', 'medium': '/m', 'large': '/l', 'author': 'A', 'license': 'CC', 'licenseUrl': null, 'sourceUrl': null}
      ],
    });
    expect(p.nameOf('ru'), 'Гиссар');
    expect(p.hasCoords, true);
    expect(p.photos.single.medium, '/m');
  });
}
