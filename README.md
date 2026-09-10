# SnapGym

SnapGym is a social fitness application centered on workout proof, consistency and friendly competition.

## Current development stack

- Flutter 3.47.x
- Riverpod
- go_router
- Supabase (Postgres, Auth, RLS, Storage, Edge Functions)
- GitHub Actions

## Environments

Android application IDs:

- dev: `com.snapgym.app.dev`
- staging: `com.snapgym.app.staging`
- prod: `com.snapgym.app`

## Development commands

```bash
flutter pub get
flutter analyze
flutter test
```

Run Android dev:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

## Database tests

Phase 6 introduced transactional pgTAP coverage for notification triggers, RLS and activity state transitions. With Docker and the Supabase CLI available:

```bash
supabase start
supabase test db supabase/tests/database
supabase stop --no-backup
```

The same database suite runs automatically in GitHub Actions for Supabase changes.

## QA fixtures

The hosted development project contains synthetic QA actors for social, Explore, challenges and Activity testing. They are not login accounts and contain no real personal data. See `docs/qa-testing.md` for fixture behavior and cleanup.

## Architecture notes

See `docs/ARCHITECTURE.md` and the phase-specific documents under `docs/`.
