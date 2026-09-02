# TaskFlow — Architecture

This document covers how the app is put together and why. For setup, test
credentials and how to trigger the simulated failures, see the
[README](../README.md).

---

## 1. Layers

```
        ┌───────────────────────────────────────────────────────┐
        │                    presentation                       │
        │                                                       │
        │  screens ──uses──▶ providers (ChangeNotifier)         │
        │     │                    │                            │
        │     └──renders──▶ ViewState<T>                        │
        └──────────────────────────┬────────────────────────────┘
                                   │ entities, Result<T>, Snapshot<T>
                                   │ (no JSON, no DTOs, no exceptions)
        ┌──────────────────────────▼────────────────────────────┐
        │                       domain                          │
        │                                                       │
        │  entities        repository interfaces                │
        │  TaskFilter      AccessPolicy                         │
        │                                                       │
        │  pure Dart — no Flutter, no serialization             │
        └──────────────────────────▲────────────────────────────┘
                                   │ implements
        ┌──────────────────────────┴────────────────────────────┐
        │                        data                           │
        │                                                       │
        │  *RepositoryImpl                                      │
        │      ├── TaskFlowApi ◀── MockTaskFlowApi              │
        │      │                       ├── NetworkSimulator     │
        │      │                       ├── MockAuthGateway      │
        │      │                       └── MockDatabase ◀─ asset│
        │      ├── CacheFallback ──▶ CacheStore (prefs)         │
        │      └── ApiCallRunner ──▶ SessionManager             │
        │                                └─▶ SessionStore (secure)
        └───────────────────────────────────────────────────────┘
```

Dependencies point inward. `domain` imports nothing from `data` or
`presentation`; `presentation` never sees a DTO, a JSON map or an
`ApiException`.

Composition happens in `lib/app/service_locator.dart`. Everything is registered
behind its interface, so the only place that knows `MockTaskFlowApi` exists is
that file.

---

## 2. The request lifecycle

What happens when the projects screen loads:

```
ProjectListScreen.initState
  └─▶ ProjectListProvider.loadIfNeeded()
        │   state: initial ─▶ loading (keeps previous data)
        │   cancels any in-flight request, creates a CancellationToken
        └─▶ ProjectRepository.getProjects(cancelToken)
              └─▶ CacheFallback.load(key: 'projects.<orgId>')
                    ├─▶ ApiCallRunner.run(…)          ← retries once on 401
                    │     └─▶ MockTaskFlowApi.getProjects()
                    │           ├─ NetworkSimulator: delay, offline?, fault?, cancelled?
                    │           ├─ MockAuthGateway.authenticate(bearer token)
                    │           ├─ scope rows to ctx.orgId, derive task_count
                    │           └─ build {"data": [...], "meta": {...}}
                    │              └─ ApiResponse.fromJson ─▶ List<ProjectModel>
                    ├─ on success: write models to CacheStore, return Snapshot.fresh
                    └─ on offline/timeout: read CacheStore, return Snapshot.cached
                                            (or Err(failure) if nothing is cached)
        ◀── Result<Snapshot<List<Project>>>
        │   Ok + empty      ─▶ EmptyState
        │   Ok + items      ─▶ SuccessState(isStale, fetchedAt)
        │   Err             ─▶ ErrorState(failure, previous: …)
        └─▶ notifyListeners ─▶ AsyncListView picks the matching UI
```

Three details worth calling out:

- **Cancellation.** Each load creates a `CancellationToken` and cancels the
  previous one. A superseded response is discarded instead of overwriting newer
  state — pull-to-refresh twice in a row cannot produce a stale list.
- **JSON on every call.** The mock endpoints build a plain map and parse it back
  through `ApiResponse.fromJson`. Serialization is therefore exercised in
  development and in tests, not just in theory.
- **Cache is written from models, not entities.** The cached bytes are the same
  shape as the wire format, so a cached read and a fresh read go through
  identical parsing.

---

## 3. Error handling

Two vocabularies, with one translation point:

```
transport            translation                domain            UI
─────────            ───────────                ──────            ──
ApiException(500) ┐                          ┌ ServerFailure    ┐
ApiException(422) │                          │ ValidationFailure│
ApiException(404) ├─▶ mapExceptionToFailure ─┤ NotFoundFailure  ├─▶ FailureDisplay
ApiException(403) │   (core/errors)          │ PermissionFailure│   icon + title +
ApiException(401) │                          │ Unauthorized…    │   message + canRetry
offline / timeout ┘                          └ Offline/Timeout  ┘
RequestCancelled                               CancelledFailure
```

`Failure` is a **sealed** class, so `FailureDisplay.of` is an exhaustive switch:
adding a failure type is a compile error until every screen can describe it.

`Result<T>` (`Ok` / `Err`) is what repositories return. There is no
`try`/`catch` in the presentation layer, and no way to accidentally ignore an
error — `fold` requires both branches.

`ValidationFailure` carries `fieldErrors`, keyed by the field name the API used,
so a 422 shows up under the right input rather than in a snackbar.

---

## 4. Simulated authentication

### Token format

```
mock.access.token.short_lived . eyJzdWIiOiJ1c2VyXzAwMSIsIm9yZyI6...  . 5f3a91c4
└──── from auth_mock ────────┘ └──── base64url(claims) ───────────┘  └ checksum ┘
        (unchanged)              sub, org, role, typ, iat, exp, jti     (FNV-1a)
```

The prefix is the literal token from `mock_login_response`, so what the app
stores is still the value the payload specifies. The claims segment is what lets
the simulated backend answer "who is calling, in which org, with what role, and
has this expired" — which is exactly what a real JWT carries. The checksum only
detects hand-edited payloads; it is not a signature.

Lifetimes come from the payload: 900s access, 604800s refresh.

### The refresh flow

```
Screen        Repository      ApiCallRunner    MockTaskFlowApi   SessionManager
  │               │                 │                 │                │
  │ getTasks()    │                 │                 │                │
  ├──────────────▶│  run(request)   │                 │                │
  │               ├────────────────▶│  GET /tasks     │                │
  │               │                 ├────────────────▶│                │
  │               │                 │                 │ authenticate() │
  │               │                 │   401 expired   │ ── exp passed  │
  │               │                 │◀────────────────┤                │
  │               │                 │  refreshTokens()│                │
  │               │                 ├─────────────────┼───────────────▶│
  │               │                 │                 │ POST /refresh  │
  │               │                 │                 │◀───────────────┤
  │               │                 │                 │  new pair ─▶ secure storage
  │               │                 │  retry GET /tasks                │
  │               │                 ├────────────────▶│                │
  │               │   Ok(tasks)     │◀────────────────┤                │
  │◀──────────────┴─────────────────┘                 │                │
  │  the screen never knew a 401 happened             │                │
```

Concurrent 401s share one refresh: `SessionManager.refreshTokens()` returns the
in-flight future rather than starting a second request. If the refresh token
itself is rejected, the session is cleared, `SessionManager` emits `null`,
`AuthProvider` flips to `unauthenticated`, and the router's redirect moves the
user to login with a message explaining why.

### What is stored where

| Item | Where | Notes |
|---|---|---|
| access + refresh token | `flutter_secure_storage` | Keystore / Keychain backed |
| user, org, role, expiries | `flutter_secure_storage` | one JSON blob |
| password | **nowhere** | passed to the login call and dropped |
| cached lists | `shared_preferences` | cleared on sign-out |
| mock database mutations | `shared_preferences` | resettable from Developer options |
| theme, biometric flag, debug switches | `shared_preferences` | |

`AuthSession.toString()` and the auth DTOs' `toString()` are overridden so a
token or password cannot reach a log line.

---

## 5. Authorization

Three independent checks, deliberately:

1. **UI** — admin-only affordances are not rendered for members.
2. **Repository** — `AccessPolicy.assertCanDeleteProject(session)` throws a
   `PermissionFailure` before the call is made. This catches an action reached
   from a deep link or a screen that was already open when the role changed.
3. **Simulated backend** — `MockTaskFlowApi` re-derives the role from the token
   and returns 403. This is the check a real server would own, and it is the one
   that still holds if the first two are bypassed.

Org scoping lives at layer 3 too: `_requireProject` returns **404** when the
project belongs to another organization, so an id from another org is
indistinguishable from an id that does not exist.

Assignment has the same shape: the picker only lists org members (UI), and
`_requireOrgMember` rejects a foreign `assignee_id` with a 422 carrying a field
error (backend). `test/unit/task_repository_test.dart` calls the API directly to
prove the second one.

---

## 6. State management

`ChangeNotifier` per feature, with two shared bases:

| | `AsyncListNotifier<T>` | `AsyncValueNotifier<T>` |
|---|---|---|
| used by | project list, task list, members, notifications | project detail, task detail |
| gives you | one in-flight request, cancellation, `loadIfNeeded`/`refresh`, initial→loading→success/empty/error | the same, minus the empty state |

Subclasses implement `fetch(cancelToken)` and add their own mutations.

`ViewState<T>` is a sealed family. Because `LoadingState` and `ErrorState` both
carry `previous`, a refresh or a failed retry never blanks the screen — which is
what makes the offline experience readable.

### Provider scope

| Scope | Notifiers | Lifetime |
|---|---|---|
| App (`app.dart`) | `SettingsProvider`, `SimulationSettings`, `AuthProvider`, `ProjectListProvider`, `TaskListProvider`, `MemberProvider`, `NotificationProvider` | process |
| Route (`router.dart`) | `ProjectDetailProvider`, per-project `TaskListProvider`, `TaskDetailProvider` | disposed with the screen |

The app-scoped list notifiers are declared with
`ChangeNotifierProxyProvider<AuthProvider, …>`. When the signed-in user changes,
`bindSession` cancels any in-flight request and resets to `initial` — without
notifying, because that runs during a build; screens reload from
`loadIfNeeded()` instead.

---

## 7. Navigation

`go_router`, with `AuthProvider` as the `refreshListenable`. Every auth change
re-runs one redirect:

| Status | Allowed | Otherwise redirect to |
|---|---|---|
| `checking` | `/splash` | `/splash` |
| `locked` | `/lock` | `/lock` |
| `unauthenticated` | `/login`, `/register` | `/login` |
| `authenticated` | everything else | `/home` (from an entry screen) |

The four tabs are a `StatefulShellRoute.indexedStack`, so each keeps its own
navigation stack and scroll position. Detail and form screens are declared at
the **root** of the router rather than inside a branch — they cover the tab bar,
which keeps back navigation predictable and makes every one of them a working
deep link (`/projects/proj_1001`, `/tasks/task_2004`). Those deep links are also
how the authorization story is demonstrated: a member opening an admin-only
route still gets refused below the UI.

---

## 8. Swapping in a real API

```dart
// data/datasources/remote/dio_taskflow_api.dart
class DioTaskFlowApi implements TaskFlowApi {
  @override
  Future<ApiResponse<List<ProjectModel>>> getProjects({CancellationToken? cancelToken}) async {
    final response = await _dio.get('/projects');
    return ApiResponse.fromJson(response.data, (d) => parseList(d, ProjectModel.fromJson));
  }
  // …
}
```

```diff
  // app/service_locator.dart
- ..registerSingleton<TaskFlowApi>(MockTaskFlowApi(…))
+ ..registerSingleton<TaskFlowApi>(DioTaskFlowApi(dio, tokenSupplier: …))
```

Nothing else changes. The repositories already speak DTOs, already map status
codes to failures, already handle cancellation and already cache through
`CacheStore`. `MockDatabase`, `MockAuthGateway`, `NetworkSimulator` and
`MockAssetSource` become dead code and can be deleted with the asset.

The one piece that would move server-side is the authorization in
`MockTaskFlowApi` — which is the point: it is written where a server would
enforce it, not smuggled into the UI.
