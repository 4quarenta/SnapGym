# SnapGym

Foundation v0.1 for the SnapGym mobile app.

## Baseline

- Flutter 3.47.2 stable
- Dart 3.12+
- Material 3
- Riverpod
- go_router
- Phosphor icons
- Inter through `google_fonts` during development
- Supabase SDK wired but backend initialization is optional until credentials exist
- Feature-first structure
- `dev`, `staging`, and `prod` Dart entrypoints
- Light + dark themes
- SnapGym palette:
  - Orange `#F06021`
  - Jet `#202123`
  - Moonstone `#6B9CAA`

## Important: native folders

This foundation intentionally contains the application source and architecture, but not hand-written Android/iOS generated projects.

On a machine with Flutter 3.47.2 installed, generate the native Android shell first:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\bootstrap_android.ps1
```

iOS should later be generated/validated on macOS:

```bash
flutter create --platforms=ios --org com.snapgym --project-name snapgym .
```

After generation, re-run:

```bash
flutter pub get
flutter analyze
flutter test
```

## Run

Development:

```bash
flutter run -t lib/main_dev.dart
```

Staging:

```bash
flutter run -t lib/main_staging.dart \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```

Production:

```bash
flutter run -t lib/main_prod.dart \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```

The app starts without Supabase credentials. Supabase is initialized only when both values are supplied.

## Structure

```text
lib/
├── app/
│   ├── app.dart
│   └── router/
├── core/
│   ├── config/
│   ├── theme/
│   └── ui/
├── features/
│   ├── checkin/
│   ├── explore/
│   ├── feed/
│   ├── profile/
│   └── ranking/
├── bootstrap.dart
├── main.dart
├── main_dev.dart
├── main_staging.dart
└── main_prod.dart
```

## Environment rule

No production secret belongs in the mobile app. Supabase publishable keys are client-safe by design when RLS is correct; privileged keys such as `service_role` must never be placed in Flutter.

R2 credentials will also never be placed in the app. When the media flow is implemented, uploads will use server-authorized short-lived URLs.

## Foundation acceptance criteria

- `flutter pub get` succeeds
- `flutter analyze` returns no errors
- `flutter test` passes
- dev app opens with the SnapGym foundation screen
- bottom navigation switches among the five product areas
- dark and light themes are available
- no backend credential is required to boot locally
