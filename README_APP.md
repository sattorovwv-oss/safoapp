# Сафо — мобильное приложение (Flutter)

Приложение для туристов: места Таджикистана (Душанбе — первым), поиск и фильтры, карта, страница места с галереей,
кнопки Google Maps / Google Earth, отзывы. Языки: тоҷикӣ, русский, English. Тёмная/светлая тема.

## Как это работает
Приложение читает данные с вашего сайта «Сафо» (Next.js) через два маршрута только на чтение:
`GET /api/mobile/places` и `GET /api/mobile/places/<slug>`. Список кэшируется на телефоне (работает офлайн).

## Адрес сервера
- Эмулятор Android: `http://10.0.2.2:3000` (по умолчанию).
- Телефон по Wi-Fi: `http://IP-компьютера:3000`. Сайт запускайте так, чтобы он был виден в сети.
- Боевой сервер: `https://ваш-домен`. Адрес можно поменять в приложении: Настройки → Адрес сервера.
  Чтобы зашить другой адрес по умолчанию, измените `defaultBaseUrl` в `lib/core/settings.dart`.

## Сборка APK (release)
```
flutter pub get
dart run flutter_launcher_icons     # иконка (уже сгенерирована)
flutter build apk --release         # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release   # для Google Play
```
Для публикации создайте ключ и файл `android/key.properties`:
```
storePassword=...
keyPassword=...
keyAlias=safo
storeFile=C:/путь/safo.jks
```
(`keytool -genkey -v -keystore safo.jks -keyalg RSA -keysize 2048 -validity 10000 -alias safo`).
Без `key.properties` APK подписывается debug-ключом — для личных тестов подходит, для Google Play нет.

## Безопасность
В `AndroidManifest.xml` включено `usesCleartextTraffic="true"` (нужно для http в локальной сети).
Когда сайт будет на HTTPS — поставьте `false`.

## Структура
`lib/core` — тема, переводы, API, модели · `lib/widgets` — общие виджеты и карточки ·
`lib/screens` — заставка, главная, поиск, карта, место, настройки.
