# Сафо — мобильное приложение (Flutter)

Приложение для туристов: места Таджикистана (Душанбе — первым), поиск и фильтры, карта, страница места с галереей,
кнопки Google Maps / Google Earth, отзывы. Языки: тоҷикӣ, русский, English. Тёмная/светлая тема.

## Как это работает
Приложение читает данные с вашего сайта «Сафо» (Next.js) через два маршрута только на чтение:
`GET /api/mobile/places` и `GET /api/mobile/places/<slug>`. Список кэшируется на телефоне (работает офлайн).

## Адрес сервера
По умолчанию приложение работает с боевым сервером **https://tjsafo.site** (`defaultBaseUrl` в `lib/core/settings.dart`).
Для тестов с компьютером поменяйте адрес в приложении: Аккаунт → Адрес сервера (например, `http://IP-компьютера:3000`;
для http в Android нужно временно поставить `usesCleartextTraffic="true"` в AndroidManifest).

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
HTTP отключён (`usesCleartextTraffic="false"`), приложение ходит только по HTTPS.

## Структура
`lib/core` — тема, переводы, API, модели · `lib/widgets` — общие виджеты и карточки ·
`lib/screens` — заставка, главная, поиск, карта, место, настройки.
