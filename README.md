# TaskFlow

## 🌐 Website URL

Experience TaskFlow directly in your browser:
🔗 **[https://taskflow-app-five-mauve.vercel.app](https://taskflow-app-five-mauve.vercel.app)**

---

## 📱 Download & Install Android APK

Get the latest Android release build directly:

- 📥 **[Download Universal APK (v1.0.0)](https://github.com/rohitjaiswal2001/TaskFlow-/releases/download/v1.0.0/app-release.apk)** (~55 MB — works on all Android devices)
- 📥 **[Download ARM64 APK (v1.0.0)](https://github.com/rohitjaiswal2001/TaskFlow-/releases/download/v1.0.0/app-arm64-v8a-release.apk)** (23 MB — recommended for modern phones & tablets)
- 📦 **[View GitHub Releases](https://github.com/rohitjaiswal2001/TaskFlow-/releases/tag/v1.0.0)**

#### Quick Install via ADB:
```bash
adb install -r app-arm64-v8a-release.apk
```

---

## 📖 About the Project

**TaskFlow** is a lightweight project and task manager for organizations featuring projects, tasks, member assignment, threaded comments, and real-time notifications with role-based access rules and offline-first persistence.

Everything runs against a **simulated backend** that reads a bundled JSON dataset. While operating entirely self-contained without requiring an external backend server, the architecture adheres strictly to clean layering (Data, Domain, Presentation) identical to production applications interacting with a live REST API.

### 🔑 Demo Accounts

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `alex.miller@taskflow.dev` | `TaskFlow#2026` |
| **Member** | `sarah.chen@taskflow.dev` | `TaskFlow#2026` |

*(You can also use the Quick-Fill demo accounts button on the login screen)*

---

| Tech Stack | Specifications |
| :--- | :--- |
| **Framework** | Flutter 3.44.5 (stable) • Dart 3.12.2 |
| **State Management** | Provider (`ChangeNotifier` + `AsyncNotifier`) |
| **Dependency Injection** | `get_it` Service Locator |
| **Navigation & Routing** | `go_router` with auth guards & redirection |
| **Storage & Caching** | `flutter_secure_storage` (tokens) + `shared_preferences` (cache, database) |
| **Supported Platforms** | Web, Android, iOS |

---

## Quick start

```bash
flutter pub get
flutter run                     # debug
flutter test                    # unit + widget + end-to-end flows
flutter build apk --release     # release APK
```

Requires Flutter 3.44.5 (stable) or newer on the 3.44 channel; `flutter doctor`
should be clean for the Android toolchain. Android `minSdk` is 23, the
application id is `com.taskflow.taskflow`, app version `1.0.0+1`.

## Demo video

A three-minute screen recording of the app on a device —
[**`Demo Task Flow.mp4`**](Demo%20Task%20Flow.mp4), at the root of this
repository (10.5 MB, 1080×2424). GitHub plays it inline when you open that file;
locally, any player will do. A still from it is in
[Screens → Watch it running](#watch-it-running).

It covers login as an admin and as a member (the role rules), creating and
assigning a task, offline mode with the saved-copy banner, an armed failure and
the token refresh.

## APK build

### Build it yourself

```bash
flutter pub get
flutter build apk --release                  # one universal APK
flutter build apk --release --split-per-abi  # smaller, one per architecture
flutter build appbundle --release            # .aab, for Play upload
```

Outputs land in `build/app/outputs/flutter-apk/`:

| File | Target | Size |
|---|---|---|
| `app-release.apk` | universal (all ABIs) | ~55 MB |
| `app-armeabi-v7a-release.apk` | 32-bit ARM | 20.4 MB |
| `app-arm64-v8a-release.apk` | 64-bit ARM — any recent phone | 23.0 MB |
| `app-x86_64-release.apk` | 64-bit x86 emulators | 24.4 MB |

For a physical device or a modern emulator, `app-arm64-v8a-release.apk` is the
one to install; use the universal APK if you don't want to think about it.

The release build is signed with the **debug keystore**, deliberately, so
`flutter build apk --release` works on a fresh clone with no key material to
hand around. A real submission would add a `signingConfigs` block and a
`key.properties` file. Because of that, Play Protect may warn on install — the
APK is not from a known publisher.

### Install it

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Or copy the `.apk` onto the device and open it, allowing "install from unknown
sources" for the file manager when prompted.

`build/` is git-ignored, so the APK is not in version control — build it with
the command above, or ask for the prebuilt file.

The app needs no network permission or backend to run — everything is served
from the bundled JSON asset, so the APK works on a device in airplane mode.

## Test credentials

All four accounts use the password **`Password123!`**. They come from
`auth_mock.test_credentials` in the mock payload and are loaded through the data
layer — the login screen's **Use a demo account** sheet lists them, so nothing
has to be typed.

| Organization | Role | Email |
|---|---|---|
| Nimbus Digital | Admin | `ava.admin@nimbusdigital.test` |
| Nimbus Digital | Member | `marcus.member@nimbusdigital.test` |
| Harborlight Studios | Admin | `daniel.admin@harborlightstudios.test` |
| Harborlight Studios | Member | `elena.member@harborlightstudios.test` |

Sign in as an admin and then as a member of the same organization to see the
role rules: a member gets no "New project" button, no edit/delete menu, and is
still refused if the action is reached another way.

Registering creates a brand new organization with you as its admin — useful for
seeing the empty states. That account lives in memory only: passwords are never
written to disk, so it is gone after a restart. The four demo accounts always
work.

---

## Architecture

Three layers, with dependencies pointing inward. `domain` knows nothing about
Flutter or JSON; `presentation` knows nothing about where data comes from.

```
┌──────────────────────────────────────────────┐
│ presentation                                 │
│   screens · widgets · ChangeNotifier providers│
│   ViewState<T>: initial/loading/success/…    │
└───────────────────┬──────────────────────────┘
                    │ Result<T> / Snapshot<T>, entities
┌───────────────────▼──────────────────────────┐
│ domain                                       │
│   entities · repository interfaces           │
│   TaskFilter · AccessPolicy                  │
└───────────────────▲──────────────────────────┘
                    │ implements
┌───────────────────┴──────────────────────────┐
│ data                                         │
│   repositories → TaskFlowApi (interface)     │
│                  ├── MockTaskFlowApi         │
│                  │     └── MockDatabase ← asset JSON
│                  └── (a DioTaskFlowApi would slot in here)
│   SessionManager · SecureSessionStore · CacheStore
└──────────────────────────────────────────────┘
```

A fuller write-up, including the request lifecycle and the auth sequence, is in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

### Folder structure

```
lib/
├── app/                    # composition root
│   ├── app.dart            # MultiProvider + MaterialApp.router
│   ├── router.dart         # go_router config + auth redirect
│   ├── routes.dart         # every path in one place
│   └── service_locator.dart# get_it wiring
├── core/                   # framework-level building blocks
│   ├── config/             # AppConfig, SimulationSettings (debug switches)
│   ├── errors/             # Failure family, ApiException, the mapper between them
│   ├── network/            # NetworkStatus, CancellationToken
│   ├── result/             # Result<T>, Snapshot<T>
│   ├── services/           # BiometricService
│   ├── theme/              # palette, spacing, AccentColors extension, ThemeData
│   └── utils/              # validators, date and string helpers
├── domain/
│   ├── entities/           # Project, TaskItem, AuthSession, TaskFilter, …
│   ├── repositories/       # abstract interfaces + their draft/params types
│   └── services/           # AccessPolicy (who may do what)
├── data/
│   ├── datasources/
│   │   ├── local/          # SessionStore (secure), CacheStore (prefs)
│   │   ├── mock/           # MockDatabase, MockAuthGateway, MockJwt, NetworkSimulator
│   │   └── remote/         # TaskFlowApi + MockTaskFlowApi + ApiCallRunner
│   ├── dto/                # request/response models
│   ├── models/             # JSON models with toEntity()
│   ├── repositories/       # the implementations
│   └── session/            # SessionManager (tokens, refresh, sign-out)
└── presentation/
    ├── models/             # UI-only models (FailureDisplay)
    ├── providers/          # one ChangeNotifier per feature
    ├── screens/            # grouped by feature
    ├── state/              # ViewState + the two async notifier bases
    └── widgets/            # reusable components
```

### Data layer

`TaskFlowApi` is written as if it were an HTTP client: one method per endpoint,
request DTOs in, response DTOs out, `ApiException` with a status code on
failure. `MockTaskFlowApi` implements it by:

1. running the call through `NetworkSimulator` (latency, offline, injected
   faults, cancellation),
2. verifying the bearer token via `MockAuthGateway`,
3. applying the org-scoping and role rules,
4. reading/writing `MockDatabase`,
5. returning a plain JSON envelope (`{"data": …, "meta": …}`) that is then
   parsed back into models — so serialization runs on every call, exactly as it
   would over the wire.

Repositories map DTOs to entities, apply `AccessPolicy`, and return
`Result<T>` (`Ok` / `Err`) so no caller can ignore the failure path. List reads
return `Snapshot<T>`, which carries `isStale` and `fetchedAt`.

`MockDatabase` seeds from `assets/mock_data/taskflow_mock_data.json` and
persists mutations to shared preferences, so a task you create survives a
restart until you reset it from Developer options.

**To point this at a real API**, write `DioTaskFlowApi implements TaskFlowApi`
and change one line in `service_locator.dart`. Nothing in `domain` or
`presentation` moves.

### Auth and tokens (simulated)

- Login matches `auth_mock.test_credentials` and mints a **JWT-style** token
  pair. The token is `<mock token from the payload>.<base64url(claims)>.<checksum>`,
  so the stored value still starts with the literal string from
  `mock_login_response` while the claims segment lets the fake backend know who
  is calling and when the token expires.
- Lifetimes come straight from the payload: **900s** access, **604800s** refresh.
- Tokens go to **secure storage**; the password is never stored and never
  logged. Request/response DTOs override `toString()` so a stray log line cannot
  print credentials.
- When the access token expires, the next request comes back `401`.
  `ApiCallRunner` — the equivalent of a Dio error interceptor — refreshes once
  and retries the original request. Concurrent 401s share a single refresh.
- If the refresh token is rejected, the session is cleared and the router
  redirects to login with an explanation.
- **Profile → Session** shows a live countdown and a **Refresh token now**
  button, so the refresh flow can be demonstrated without waiting 15 minutes.
- Bonus: biometric unlock (Profile → Security) locks the session when the app
  returns from the background, and the session is signed out after 10 minutes
  without any interaction.

---

## Triggering the simulated failures

Two ways, both without touching source. The switches live in
**Profile → Developer options**.

### 1. Developer options

| Control | What it does |
|---|---|
| **Offline mode** | Requests fail with "no connection". Lists fall back to the last saved copy and show a *Saved copy from …* banner; a red strip appears app-wide with a **Go online** action. |
| **Artificial latency** | On by default: 300–800ms per request, so loading states are visible. Turn it off for fast clicking. |
| **Arm a failure** | Makes the next request fail with a server error (500), a timeout, a 404, or an expired token (401). "Only once" disarms it after a single request; turn it off to fail every call. |
| **Clear cached data** | Empties local storage, so offline mode has nothing to fall back on and shows the offline error page instead. |
| **Reset mock data** | Throws away everything created in the app and reseeds from the bundled JSON. |

The **expired token (401)** option is the interesting one: the request still
succeeds, because the client refreshes the token and retries. Watch the
countdown on the Profile screen change.

### 2. Trigger words in a name or title

Put any of these anywhere in a **project name** or **task title** and that one
save fails:

| Trigger | Result |
|---|---|
| `#500` | Server error — snackbar / error banner |
| `#timeout` | Request times out after ~900ms |
| `#invalid` | 422 with a field-level error shown under the input |
| `#403` | Permission denied |

For example, creating a task called `Check the invoices #invalid` shows the
validation message inline on the Title field.

### 3. Authorization

Sign in as `marcus.member@nimbusdigital.test`. The create/edit/delete affordances
are gone, and the rule is enforced twice below the UI — once in the repository
(`AccessPolicy`) and once in the simulated backend, which reads the role from the
token. `test/unit/project_repository_test.dart` calls the API directly to prove
the second one holds when the first is bypassed.

Org scoping works the same way: a project or task belonging to another
organization returns **404**, not 403 — a real API should not confirm that an id
exists to someone who cannot see it.

---

## Screens

| Dashboard | Project details | Task details |
|---|---|---|
| ![Dashboard](screenshots/03-dashboard.png) | ![Project details](screenshots/05-project-details.png) | ![Task details](screenshots/06-task-details.png) |

| Task list | Offline | Dark mode |
|---|---|---|
| ![Task list](screenshots/07-task-list.png) | ![Offline](screenshots/13-offline.png) | ![Dark mode](screenshots/11-dark-mode.png) |

Splash · Login · Register · Biometric lock · Dashboard · Projects · Project
details · Task list · Task details · Create/Edit project · Create/Edit task ·
Notifications · Profile & Settings · Developer options.

### Watch it running

[![Watch the demo](screenshots/00-demo-video.png)](Demo%20Task%20Flow.mp4)

▶ **[Demo Task Flow.mp4](Demo%20Task%20Flow.mp4)** — 3 minutes, 1080×2424, 10.5 MB.
Click the frame above (or the link) to play it on GitHub. Every screen listed
above appears in it, in motion.

The images in `screenshots/` are generated, not hand-collected:

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart -d <device>
```

Beyond the required list: dark mode (Profile → Appearance), a tablet layout
(navigation rail plus a two-column project grid above 720dp), skeleton loading,
pull-to-refresh everywhere, an inbox for the mock notifications with deep links
into the task, and per-task comments.
