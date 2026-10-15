# Fitopia — Mobile App Handover

A handover guide for the team taking over the **Fitopia** Flutter mobile application.
Read this file top-to-bottom before touching the code.

---

## 1. What this project is

- **Name:** Fitopia (`pubspec.yaml` → `name: fitopia`)
- **Type:** Cross-platform mobile app built with **Flutter** (Android, iOS, and also web/desktop scaffolding present).
- **Domain:** Fitness / health app — onboarding, workout routines, meal plans, nutrition, recipes, subscriptions, chat, news feed, e-books.
- **Current state:** **UI-first build.** The screens and navigation are implemented, but the **backend/networking layer is commented out** (see [`lib/data/api/api_client.dart`](../lib/data/api/api_client.dart) and [`lib/data/repository/auth_repo.dart`](../lib/data/repository/auth_repo.dart)). The app runs and navigates without a live server. Wiring the API back up is the main integration task for the new team.
- **Languages supported in-app:** English (`en`) and Arabic (`ar`) via `easy_localization`.

---

## 2. Prerequisites

Install these before running:

| Tool | Version used | Notes |
|------|--------------|-------|
| Flutter SDK | **3.41.2** (stable) | `flutter --version` to check |
| Dart SDK | **3.11.0** | Bundled with Flutter |
| Android Studio / SDK | latest | For Android builds & emulator |
| Xcode | latest | macOS only, for iOS builds |
| A device or emulator | — | Android emulator, iOS simulator, or physical device |

> `pubspec.yaml` declares `sdk: '>=2.18.5 <3.0.0'`. If your local Dart is 3.x and pub fails on the constraint, widen it to `'>=2.18.5 <4.0.0'` and re-run `flutter pub get`.

Verify your setup:

```bash
flutter doctor
```

---

## 3. Configuration (base URLs / secrets)

**No secrets, API keys, keystores, or `google-services.json` are stored in this repo.**

The backend base URLs used to be **hardcoded** in `lib/presentation/resources/strings_manager.dart`. They have been **removed from the source** and are now injected at build/run time via `--dart-define`.

- Reference values: [`handover/config.example.env`](./config.example.env)
- In code: `AppStrings.appBaseUrl` and `AppStrings.imgBaseUrl` now read from the environment and default to an empty string.

Provide them when running/building (see next section). The previous values were:

| Key | Previous value |
|-----|----------------|
| `APP_BASE_URL` | `https://medeaminds.com/` |
| `IMG_BASE_URL` | `https://medeaminds.com/uploads` |

Replace these with your own backend before release.

### Android signing
There is currently **no release keystore** committed. Release builds fall back to the **debug** signing config (`android/app/build.gradle` → `signingConfig signingConfigs.debug`). Before publishing to the Play Store, create a release keystore and a `key.properties` file (keep it **out of git**) and wire it into `build.gradle`.

App identifiers to update before release:
- `applicationId` is `com.example.fitopia` (`android/app/build.gradle`) — change to your own domain.
- iOS bundle identifier — set in Xcode / `ios/Runner.xcodeproj`.

---

## 4. Running the app

Install dependencies first:

```bash
flutter pub get
```

Run on a connected device/emulator, passing the config values:

```bash
flutter run \
  --dart-define=APP_BASE_URL=https://your-backend.example.com/ \
  --dart-define=IMG_BASE_URL=https://your-backend.example.com/uploads
```

> The app also runs **without** these defines (they default to empty) because networking is currently commented out — useful for UI work.

Handy commands:

```bash
flutter devices          # list available targets
flutter run -d chrome    # run in a browser (web)
flutter clean            # clear build cache if things get weird
```

---

## 5. Building releases

Android (APK / App Bundle):

```bash
flutter build apk --release \
  --dart-define=APP_BASE_URL=... --dart-define=IMG_BASE_URL=...

flutter build appbundle --release \
  --dart-define=APP_BASE_URL=... --dart-define=IMG_BASE_URL=...
```

iOS (run on macOS, then archive in Xcode):

```bash
flutter build ios --release \
  --dart-define=APP_BASE_URL=... --dart-define=IMG_BASE_URL=...
```

App launcher icons are generated with `flutter_launcher_icons`:

```bash
flutter pub run flutter_launcher_icons:main
```

---

## 6. Project structure

```
lib/
├── main.dart                 # Entry point: init localization + GetStorage, run MyApp
├── app/app.dart              # Root MaterialApp, theme + routing wiring
├── bloc/                     # Theme BLoC (flutter_bloc) — light/dark theming
├── controller/               # GetX controllers (auth_controller.dart)
├── data/
│   ├── api/                  # api_client.dart, api_checker.dart  (COMMENTED OUT)
│   └── repository/           # auth_repo.dart                    (COMMENTED OUT)
├── model/                    # Data models (dashboard, products, subscription, ...)
├── presentation/             # All UI screens, grouped by feature
│   ├── login/ signup/ forgot/        # Auth flows
│   ├── onboarding/ introduction/     # First-run flows
│   ├── home/ dashboard, analytics, news feed, stories, more
│   ├── nutrition/ my_meal_plans/ receipe_list/ workout_routine/ my_program/
│   ├── subscription/ chat/ ebook/ help/ settings/ my_profile/ splash/
│   └── resources/            # Design system + constants (see below)
├── translations/             # Generated i18n (codegen_loader.g.dart, locale_keys.g.dart)
└── widgets/                  # Reusable widgets (buttons, charts, cards, fields)
```

### `presentation/resources/` — the design-system layer
- `routes_manager.dart` — named routes + `onGenerateRoute` (start here to trace navigation)
- `strings_manager.dart` — string constants **and** the env-driven base URLs
- `color_manager.dart`, `font_manager.dart`, `styles_manager.dart`, `values_manager.dart`, `app_theme.dart` — colors, fonts, text styles, spacing, theme
- `assets_manager.dart` — asset path constants
- `index_manager.dart` — barrel file re-exporting the above

### Assets (`assets/`, declared in `pubspec.yaml`)
- `images/`, `icons/`, `applogo.png` — imagery
- `fonts/` — bundled fonts
- `translations/` — `en.json`, `ar.json` source files for i18n

---

## 7. Key libraries in use

| Package | Purpose |
|---------|---------|
| `get`, `get_storage` | State management (GetX) + local key-value storage |
| `flutter_bloc`, `equatable` | BLoC for theming |
| `easy_localization` | Internationalization (en/ar) |
| `flutter_svg` | SVG rendering |
| `fl_chart`, `percent_indicator` | Charts & progress UI |
| `http`, `dio` | HTTP clients (for when the API layer is re-enabled) |
| `dots_indicator`, `smooth_page_indicator`, `pin_code_fields` | Onboarding/OTP UI |
| `convex_bottom_bar`, `ff_navigation_bar_plus`, `circular_menu`, `fab_circular_menu_plus` | Navigation / menus |
| `flutter_credit_card` | Subscription/payment card UI |
| `responsive_sizer` | Responsive layout sizing |

Full list: `pubspec.yaml`.

---

## 8. Internationalization workflow

Translation source files live in `assets/translations/*.json`. The Dart bindings
(`lib/translations/codegen_loader.g.dart` and `locale_keys.g.dart`) are **generated**.
After editing the JSON, regenerate them:

```bash
flutter pub run easy_localization:generate -S "assets/translations" -O "lib/translations"
flutter pub run easy_localization:generate -S "assets/translations" -O "lib/translations" -o locale_keys.g.dart -f keys
```

(These commands are also noted at the top of `strings_manager.dart`.)

---

## 9. First tasks for the new team

1. **Point the app at your backend** — pass `APP_BASE_URL` / `IMG_BASE_URL` via `--dart-define` (Section 3).
2. **Re-enable networking** — the API client, repositories, and controller in `lib/data/**` and `lib/controller/auth_controller.dart` are commented out. Uncomment/rewrite against your API and wire the auth flows (login, signup, forgot-password, OTP).
3. **Change app identifiers** — `applicationId`/bundle id away from `com.example.fitopia`.
4. **Set up release signing** — create a keystore + `key.properties` (keep out of git).
5. **Widen the Dart SDK constraint** in `pubspec.yaml` if you're on Dart 3.x.

---

## 10. Housekeeping notes

- The root `README.md` is still the default Flutter template — safe to replace with project-specific content.
- `strings_manager.dart` contains large blocks of **commented-out** legacy strings (superseded by `easy_localization`). Safe to delete during cleanup.
- No CI/CD is configured in the repo.
- `.gitignore` already excludes `/build/`, `.dart_tool/`, IDE files, and Android build artifacts. **Also add** `**/key.properties` and `**/*.jks`/`*.keystore` and any real `.env` before committing signing material.
