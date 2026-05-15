# InstaJob (ShiftSphere) — Project Intelligence

> This document provides essential context for AI assistants working on this codebase.

## Project Overview

**InstaJob** (package name: `shiftsphere`) is a **Flutter + Node.js/MongoDB** job/shift marketplace app.
- **Users** (ushers) browse and apply for event shifts (concerts, conferences, etc.)
- **Team Leaders** manage attendance and rate workers per event
- **Admins** manage the entire platform (events, users, analytics)

## Architecture

### Frontend — Flutter (Dart)
```
lib/
├── main.dart                    # App entry, theme setup, ProviderScope
├── routes/app_router.dart       # GoRouter with role-based guards
├── controllers/                 # Business logic (Riverpod providers)
│   ├── auth_controller.dart     # Login, register, Google SSO, profile mgmt
│   ├── event_controller.dart    # CRUD events, categories, search
│   ├── application_controller.dart
│   ├── admin_controller.dart
│   ├── team_leader_controller.dart
│   ├── notification_controller.dart
│   ├── rating_controller.dart
│   └── message_controller.dart
├── models/                      # Data models (manual fromJson, no code-gen)
│   ├── event_model.dart         # EventModel + LocationData
│   ├── user_model.dart          # UserModel with profileCompletion getter
│   ├── application_model.dart
│   ├── notification_model.dart
│   ├── rating_model.dart
│   └── message_model.dart
├── services/
│   ├── file_upload_service.dart  # Avatar, CV, ID, event image uploads
│   ├── realtime_service.dart    # Socket.io (currently polling stub)
│   └── logout_service.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart      # Dio HTTP client with JWT interceptor + auto-refresh
│   │   ├── api_config.dart      # Base URL auto-detection, endpoints
│   │   └── token_storage.dart   # Hive-backed JWT storage
│   ├── theme/
│   │   ├── dark_colors.dart     # Navy/cyan dark palette
│   │   ├── colors.dart          # Light theme palette
│   │   ├── glass.dart           # Glassmorphic container + decorations
│   │   ├── typography.dart      # Font system
│   │   ├── shadows.dart
│   │   └── theme_provider.dart
│   ├── utils/
│   │   ├── responsive.dart      # ResponsiveHelper (sp, wp, hp scaling)
│   │   ├── extensions.dart      # DateTime, String extensions
│   │   ├── result.dart          # Result<T> pattern (Success/Error)
│   │   └── perf_log.dart        # Performance logging
│   └── auth/
│       └── auth_guard.dart
├── views/
│   ├── home/                    # Main user screens
│   │   ├── event_browse_screen.dart  # Homepage with hero carousel + shift list
│   │   ├── event_details_screen.dart # Full event details with apply button
│   │   ├── event_card.dart           # Legacy card (uses GlassContainer)
│   │   ├── event_search_screen.dart
│   │   └── application_form_screen.dart
│   ├── user/                    # User-specific screens
│   │   ├── user_profile_screen.dart  # Profile with avatar/CV/ID upload
│   │   ├── edit_profile_screen.dart
│   │   ├── applications_screen.dart
│   │   ├── user_dashboard_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── user_ratings_screen.dart
│   │   └── user_history_screen.dart
│   ├── admin/                   # Admin screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── events/
│   │   ├── users/
│   │   └── applications/
│   ├── team_leader/             # Team leader screens
│   │   ├── team_leader_events_screen.dart
│   │   ├── attendance_screen.dart
│   │   ├── event_applicants_screen.dart
│   │   └── rating_form_screen.dart
│   ├── shared/                  # Shared across roles
│   │   ├── main_shell.dart      # Bottom nav shell (ShellRoute)
│   │   ├── notifications_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── messaging_screen.dart
│   │   └── splash_screen.dart
│   └── common/
│       └── skeleton_loader.dart # Shimmer skeleton widgets
└── widgets/
    └── glass/                   # (empty — glass system is in core/theme/)
```

### Backend — Node.js + Express + MongoDB
```
backend/src/
├── app.js                       # Express app setup, middleware, routes
├── server.js                    # Server entry with MongoDB connection
├── config/                      # DB config, env vars
├── controllers/                 # Route handlers
│   ├── auth.controller.js       # Login, register, Google SSO, JWT
│   ├── event.controller.js
│   ├── application.controller.js
│   ├── user.controller.js
│   ├── notification.controller.js
│   └── ...
├── models/                      # Mongoose schemas
│   ├── User.js, Event.js, Application.js, etc.
├── middleware/
│   ├── auth.js                  # JWT verification + role guard
│   └── upload.js                # Multer file upload
├── routes/                      # Express routers
├── services/                    # Email, file storage
├── sockets/                     # Socket.io handlers
├── utils/                       # Tokens, logger, async handler
└── validations/                 # Joi schemas
```

## Key Patterns & Conventions

### State Management
- **Riverpod** with `StateProvider`, `FutureProvider`, `Provider`
- `currentUserProvider` (StateProvider<UserModel?>) — single source of truth for auth state
- `isAuthenticatedProvider` (StateProvider<bool>) — tracks token existence
- Controllers are plain classes registered as `Provider`, not `StateNotifier`

### Navigation
- **GoRouter** with ShellRoute for bottom nav
- Role-based redirects in the global `redirect` callback
- Normal users: ShellRoute wraps `/`, `/applications`, `/notifications`, `/profile`
- Non-shell routes: `/event/:id`, `/apply/:id`, `/search`, `/dashboard`, etc.
- Always use `context.push()` or `context.go()` — never raw `Navigator.push`

### API Communication
- **Dio** with interceptors for auth (token attach + 401 refresh)
- `Result<T>` pattern: all controller methods return `Success(data)` or `Error(exception)`
- Backend returns `{ success: true, data: {...} }` shape
- MongoDB `_id` → normalized to `id` in models

### Image Handling
- `CachedNetworkImage` with `memCacheHeight`/`memCacheWidth` for memory optimization
- `FileUploadService` wraps upload endpoints, returns file paths
- Avatar cache-busting via `?v=timestamp` query param

### Theme System
- Dark-first design with navy/cyan/teal palette
- `DarkColors` class for all dark theme constants
- `GlassConfig` + `GlassContainer` for glassmorphism (uses `BackdropFilter`)
- `ResponsiveHelper.sp(context, size)` for responsive font scaling

## Performance Considerations

### Current Optimizations Already In Place
- `RepaintBoundary` wrapping cards in lists
- `SliverList` with `SliverChildBuilderDelegate` (lazy building)
- `CachedNetworkImage` with `memCacheHeight`/`memCacheWidth`
- `SkeletonLoader` shimmer placeholders during loading
- `PerfLog` instrumentation in key screens

### Known Performance Issues
1. **BackdropFilter** in `GlassContainer` — extremely expensive on mobile GPU
2. **No `const` constructors** on many stateless widget instances (defeats tree-shaking)
3. **`MediaQuery.of(context)` called inside build** — causes unnecessary rebuilds
4. **`ResponsiveHelper.sp()` called per-widget** — calls `MediaQuery` each time
5. **`FutureProvider.autoDispose`** refetches on every screen revisit
6. **Hero carousel height = `MediaQuery.of(context).size.width * 1.0625`** — recalculated each build
7. **`DateFormat` created per-card** in `_HeroEventCard._formatDateRange`
8. **`AnimatedContainer` on category chips** — animates on every selection change
9. **Large widget trees inside single `build` methods** — no extraction into `const` sub-widgets

## Common Gotchas

1. **Dialog context shadowing**: `builder: (context) =>` shadows outer context. Use `dialogContext` naming.
2. **GoRouter push vs go**: `go` replaces the stack; `push` adds to it. Use `push` for detail screens.
3. **`Navigator.pop` in dialogs**: Always use `Navigator.of(dialogContext).pop()`, never bare `context.pop()`.
4. **Profile completion**: Computed from 8 fields via `UserModel.profileCompletion` getter (not stored in DB).
5. **Backend `_id`**: MongoDB uses `_id`; all models normalize to `id` in `fromJson`.
6. **Token refresh loop**: ApiClient uses a separate Dio instance for refresh to avoid interceptor loops.
7. **`autoDispose` providers**: Data is refetched when the screen is popped and re-pushed. This is by design but can feel slow.

## File Naming Conventions
- Dart files: `snake_case.dart`
- Screens: `*_screen.dart`
- Controllers: `*_controller.dart`
- Models: `*_model.dart`
- Backend: `camelCase.js` for controllers, `PascalCase.js` for models

## Development Setup
- Flutter SDK ^3.10.1
- Backend: Node.js + MongoDB (local or Atlas)
- `.env` file required in project root with `API_BASE_URL`
- Backend runs on port 5000 by default
- Local network IP for mobile testing: `192.168.1.9`
