# KinoGo (Flutter) — iOS 18+ / Android

Кроссплатформенная (Flutter) пересборка приложения **KinoGo**, воспроизводящая
поведение оригинального Android-приложения `biz.kinogo.app` и добавляющая
полноценную поддержку **iOS 18+**.

Проект восстановлен по декомпилированному APK (исходного Dart-проекта не было),
поэтому архитектура, список экранов, эндпоинты API и ассеты воспроизведены по
данным из бинарника, а не скопированы 1:1.

## Технологии

Riverpod · go_router · Dio · flutter_secure_storage · shared_preferences ·
webview_flutter · cached_network_image · Firebase Analytics · flutter_native_splash.

## Структура

```
lib/
  core/        конфиг, API-клиент + интерсепторы, тема, навигация, хранилище, аналитика
  shared/      модели, пагинация, переиспользуемые виджеты
  features/    home, categories, category_detail, movie, player, search,
               favorites, franchise, podborki, history, auth, profile
```

## Запуск (разработка)

```bash
flutter pub get
flutter run
```

## Источник данных

Каталог (главная, категории, поиск, страница фильма, плееры, комментарии,
франшизы, подборки) берётся разбором мобильной версии сайта
`https://kinogo-10.biz` — см. `core/api/kinogo_web_service.dart`. Сайт отдаёт
мобильный шаблон только при мобильном `User-Agent` (`AppConfig.userAgent`).

Проверка парсера на живом сайте:

```bash
dart run tool/site_smoke_test.dart
```

Фильтр каталога (экран «Фильтр»: раздел, жанр, страна, год, подборки, качество,
перевод, сортировка) использует собственный фильтр сайта: список значений
берётся из `window.__XSORT__` на главной, а выбранные значения передаются в куке
`xsort`.

Регистрации и входа в приложении нет: избранное и история просмотров хранятся
на устройстве. Gateway (см. ниже) приложением сейчас не используется.

## ⚠️ Доступ к API (X-App-Signature)

Боевой gateway `https://api.kinogo-10.biz/gateway` подписывает каждый запрос
заголовком `X-App-Signature` и без него возвращает `403 Forbidden`. В оригинале
подпись выводится из отпечатка **Android-сертификата** приложения — у iOS такого
нет. Секрет и алгоритм подписи принадлежат владельцу backend и **в код не
зашиты**. Передайте их при запуске через `--dart-define` (см. `main.dart` и
`core/api/interceptors/signature_interceptor.dart`):

```bash
flutter run \
  --dart-define=KINOGO_APP_SECRET=... \
  --dart-define=KINOGO_CLIENT_ID=...
```

Если формула подписи на вашем сервере отличается от HMAC-SHA256 по умолчанию,
поправьте её в одном месте — `SignatureInterceptor.onRequest`.

## Сборка iOS

iOS нельзя собрать на Windows/Linux — нужен **macOS + Xcode**. В репозитории
настроен GitHub Actions workflow `.github/workflows/ios.yml`:

- **build-unsigned** — собирает неподписанный `.app` на macOS-раннере (без
  Apple-аккаунта) и кладёт его в артефакты. Это проверяет, что проект
  компилируется под iOS.
- **signed-ipa** (закомментирован) — собирает устанавливаемый `.ipa`. Включите
  его и добавьте секреты подписи (сертификат `.p12`, provisioning profile,
  team id) — инструкция в комментариях внутри workflow.

Локально на Маке:

```bash
flutter build ios --release --no-codesign   # без подписи
flutter build ipa  --release                # подписанный .ipa (нужен аккаунт)
```

- iOS deployment target: **18.0** (`ios/Podfile`, `project.pbxproj`,
  `AppFrameworkInfo.plist`).
- Bundle id: `biz.kinogo.app`.

## Firebase

Аналитика инициализируется «мягко»: без `ios/Runner/GoogleService-Info.plist`
и `android/app/google-services.json` она просто отключается, приложение
работает. Положите свои конфиги, чтобы включить отчётность.
