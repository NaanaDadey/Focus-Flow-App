# FocusFlow

**Beat procrastination. Own your schedule.**

A time-management and anti-procrastination companion for students, built
with **Flutter** (frontend) and **Supabase** (backend). Final-year IT
project.

---

## What it does

Starting from the project brief (task input, deadlines, progress
tracking, and daily reminders), FocusFlow expands into a full student
time-management system:

- **Works instantly, no account required.** Every feature — tasks,
  timetable, courses, exams, reminders — runs fully offline in guest
  mode, backed by local storage (Hive). Signing in is optional and only
  adds cross-device sync.
- **Smart "early start" nudges.** Instead of just tracking a deadline,
  FocusFlow computes a suggested start time (halfway to the deadline, or
  24h before it — whichever gives more buffer) and reminds the student
  *before* procrastination sets in, not just when it's already too late.
- **3x-daily digest reminders.** Configurable check-in notifications
  (default 08:00 / 13:00 / 19:00) summarizing what's due — matching the
  brief's "reminders three times a day," but fully editable per user.
- **Weekly timetable.** Recurring class schedule by day, with a "next up
  today" card on the dashboard.
- **Semester outline.** Register courses and exam dates; the app
  automatically schedules countdown alerts (default 7 / 3 / 1 days
  before each exam) so exam prep can never sneak up unannounced.
- **Zero data loss on sign-up.** Anything entered as a guest is
  automatically migrated into a new account the moment the student
  signs up — nothing typed before authenticating is lost.
- **Progress tracking.** Completion rate, overdue count, and a
  dashboard summary give the student an at-a-glance view of how they're
  doing.

## Architecture

```
lib/
  core/            Theme, constants, Supabase bootstrap
  models/          Hive-backed data models (Task, Course, Exam, Timetable, Profile)
  services/        Repositories (local-first + Supabase sync) and NotificationService
  providers/       ChangeNotifier state (Auth, Task, Timetable, Semester, Theme)
  screens/         UI, organized by feature (auth, home, tasks, timetable, semester, settings)
  widgets/         Shared UI components (task card, countdown card, badges, empty states)
supabase/
  schema.sql       Full Postgres schema: tables, RLS policies, triggers, a stats view
```

**Local-first, sync-second.** Every write lands in a local Hive box
first — the UI is instant and works fully offline. If a user is signed
in, the same write is mirrored to Supabase in the background. This
keeps a single code path for both guest and authenticated users; no
screen has to branch on auth state.

**State management:** `provider` (ChangeNotifier). Chosen for clarity
and low ceremony — appropriate for a project this size and easy to
explain in a viva/defense.

## Getting started

### 1. Prerequisites
- Flutter SDK 3.3+ (`flutter --version`)
- A free [Supabase](https://supabase.com) project

### 2. Scaffold platform folders
This repo ships only the Dart source (`lib/`) and `pubspec.yaml` — the
native `android/`, `ios/`, etc. folders are generated locally so they
match your machine's toolchain:

```bash
flutter create .
flutter pub get
```

### 3. Set up Supabase
1. Create a new project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor → New query**, paste the contents of
   `supabase/schema.sql`, and run it. This creates all tables, Row Level
   Security policies, the auto-profile trigger, and a `task_stats` view.
3. Go to **Project Settings → API** and copy your **Project URL** and
   **anon public key**.
4. Paste them into `lib/core/constants.dart`:
   ```dart
   static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
   static const String supabaseAnonKey = 'YOUR-SUPABASE-ANON-KEY';
   ```

### 4. Run it
```bash
flutter run
```
The app opens straight into guest mode — no sign-in wall. Create an
account any time from the profile icon or Settings tab to enable sync.

### 5. Generate the app icon
The launcher icon (a white bolt on the app's indigo brand color) lives as
source PNGs in `assets/icon/` and is turned into every platform's real
icon files by `flutter_launcher_icons` — config is already in
`pubspec.yaml`. Run:
```bash
flutter pub get
dart run flutter_launcher_icons
```
This writes into `android/app/src/main/res/`, `ios/Runner/Assets.xcassets/`,
`windows/runner/resources/`, etc. Re-run it any time you replace the
source images in `assets/icon/`. To use a different icon, swap out
`assets/icon/app_icon.png` (flat, full-bleed — used for iOS/Windows/web)
and `assets/icon/app_icon_foreground.png` (transparent background, art
kept within the center ~66% — used as the Android adaptive-icon
foreground layer) and re-run the command above.

### 6. (Optional) Regenerate Hive adapters
The `*.g.dart` Hive adapter files are committed hand-authored so the
project compiles immediately without a codegen step. If you add or
change a `@HiveField` in any model, either update the matching `.g.dart`
file by hand or regenerate it:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Notes for the project report

- **Method:** Flutter (Material 3) frontend, Supabase (Postgres + Auth)
  backend, Hive for local/offline persistence, `flutter_local_notifications`
  + `timezone` for scheduled reminders.
- **Security:** Every Supabase table has Row Level Security enabled —
  a user can only ever read or write their own rows, enforced at the
  database layer, not just in the app.
- **Recommendations from the brief** (rewards, calendar view, more
  features) are natural next steps: a `fl_chart`/`table_calendar`
  dependency is already included in `pubspec.yaml` for a future calendar
  view, and a streak/points system could hook into the existing
  `completionRate` tracking in `TaskProvider` without any schema changes.
