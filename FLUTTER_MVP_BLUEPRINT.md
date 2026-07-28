# TechConnect Cameroun — Flutter Mobile MVP Blueprint

**Source of truth used to build this plan:** Cahier de Charges v1.0, Full Specification Book v2.0, Research Report (Chapters 1–2), and the confirmed architecture decision that Express remains the intermediary between clients and Supabase.

This document is the implementation blueprint for the **Flutter mobile app**. It assumes the backend (Express REST API + Supabase) described in the shared spec is the single source of truth for data — the mobile app is a pure consumer of `/api/*`, exactly like the React web client. No business logic is duplicated on-device beyond what's needed for offline-friendly UX (caching, optimistic UI).

---

## 0. Scope Decision (read first)

The spec defines three roles: Client, Technician, Administrator. It does **not** explicitly say which roles get the mobile app. To avoid ambiguity, here is the scope decision this blueprint locks in:

> **Mobile V1 = Client + Technician only.** Administrator stays web-only (back-office tooling doesn't need to be mobile-first, and it keeps the mobile MVP focused). If this is wrong, flag it now — it changes the phase plan below.

Everything past this point assumes that decision.

---

## 1. MVP Feature Scope (mapped to FR-IDs from the Cahier de Charges)

| Module | In MVP | Deferred |
|---|---|---|
| Auth (FR-01–06) | Register (Client/Technician), Login, JWT session, logout | Email verification (FR-05, explicitly future) |
| Directory (FR-07–11) | Keyword search, filters (city, region, category, availability, rating), sort, pagination | — |
| Service Requests (FR-12–17) | Create request, view history, accept/reject/complete/cancel, full status lifecycle | — |
| Reviews (FR-18–20) | Rate 1–5 + comment after Completed, view technician's reviews | — |
| Favorites (FR-21–22) | Add/remove/list favorites (Client only) | — |
| Dashboard (FR-23–25) | Client dashboard (requests, favorites), Technician dashboard (stats: views, completed jobs, pending, rating) | Admin dashboard (web only) |
| Notifications (FR-26–27) | In-app notification list + unread badge, polling or pull-to-refresh | Push (FCM), SMS, WhatsApp, email — explicitly deferred per spec |
| Verification (technician) | Upload ID + certificate from device (camera/gallery) | — |

**Explicitly out of scope for mobile V1** (per spec §20 / Future Improvements, applies to both clients): real-time chat, Mobile Money payment, GPS/proximity search, AI recommendations, voice search, offline-first sync.

---

## 2. User Flows

### 2.1 Client flow
`Splash → Login/Register → Home (search bar + categories) → Directory (filtered list) → Technician Profile → Send Request → Request tracked in "My Requests" (status updates) → on Completed: Rate & Review → Favorites accessible from profile or directory heart icon → Notifications tab shows status changes`

### 2.2 Technician flow
`Splash → Login/Register (role=technician) → Onboarding: complete profile (bio, experience, price range, categories, city, availability) + upload ID/certificate → Dashboard (stats + pending requests) → Incoming Request → Accept/Reject → Mark In Progress → Mark Completed → Rating appears on profile → Toggle availability anytime from dashboard`

### 2.3 Cross-cutting
- Unauthenticated users can browse the Directory and view Technician Profiles (read-only) before being prompted to register — mirrors the "Visitor folded into Client" decision from the spec.
- 401 from any API call → clear stored token → redirect to Login.

---

## 3. Architecture: Clean Architecture, 3 layers

```
lib/
├── core/
│   ├── network/          # DioClient, interceptors, ApiException
│   ├── error/             # Failure types, error mapper (matches backend error codes)
│   ├── storage/           # SecureStorage wrapper (JWT), local cache (Hive)
│   ├── router/            # go_router config + route guards
│   ├── theme/             # colors, typography (mirrors web Tailwind brand palette)
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/           # AuthRemoteDataSource (Dio calls), AuthRepositoryImpl
│   │   ├── domain/         # User entity, AuthRepository interface, use cases (Login, Register, GetMe, Logout)
│   │   └── presentation/   # Riverpod providers/notifiers, screens, widgets
│   ├── directory/          # search, filters, technician list
│   ├── technician_profile/ # profile detail, reviews list, favorite toggle
│   ├── requests/           # create request, request list, status transitions
│   ├── reviews/            # submit rating/review
│   ├── favorites/
│   ├── notifications/
│   ├── technician_dashboard/  # stats, availability toggle, verification upload
│   └── client_dashboard/
│
├── shared/
│   ├── widgets/            # buttons, cards, empty states, loading, error banner
│   └── models/             # shared DTOs used across features (Category, Region, City)
│
└── main.dart
```

**Why this shape:** each feature is self-contained (data/domain/presentation), so a feature can be built, tested, and reviewed in isolation — matching the phased roadmap in Section 6. `core/` holds nothing feature-specific, so it's built once in Phase 0 and never touched again except for bugfixes.

---

## 4. Recommended Stack (deviates from the earlier scaffold — see note)

| Concern | Recommendation | Why |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod`) | Testable outside widget tree, no BuildContext coupling, scales cleanly per-feature. Better fit for clean architecture than plain `provider`. |
| Networking | **Dio** | Interceptors for JWT injection + centralized error mapping (the earlier scaffold used raw `http`; Dio's interceptor model matches `web/src/services/api.js` more closely). |
| Navigation | **go_router** | Declarative routes, guard support for `ProtectedRoute`-equivalent logic, deep-link ready. |
| Models / JSON | **freezed + json_serializable** | Immutable models, compile-time safety mapping to the Supabase schema (enums for `role`, `request_status`, `availability`). |
| Secure token storage | `flutter_secure_storage` | Already in the scaffold — kept as is. |
| Local cache (non-sensitive) | `hive` or `shared_preferences` | Cache category/region/city reference data so filters render instantly offline. |
| Image handling | `image_picker` + `cached_network_image` | Profile photos, ID/certificate uploads, technician avatars in lists. |
| Forms | `reactive_forms` or plain `TextEditingController` + validators | Registration/profile forms need validation parity with backend (`express-validator` rules). |

> **Note on the earlier scaffold:** `mobile/pubspec.yaml` from the initial setup used `http` + `provider`. This blueprint recommends **Riverpod + Dio** instead for a cleaner clean-architecture fit. If you'd rather keep `http`/`provider` to match what's already scaffolded, say so — Phase 0 below assumes the upgrade, but it's a small swap.

---

## 5. Data Models (mirrors `database/schema.sql`)

```dart
enum UserRole { client, technician, admin }
enum Availability { available, busy, offline }
enum RequestStatus { pending, accepted, rejected, inProgress, completed, cancelled }
enum DocumentType { idCard, certificate }
enum DocumentStatus { pending, approved, rejected }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
}

class TechnicianProfile {
  final String id;
  final String userId;
  final String? bio;
  final int yearsExperience;
  final double? priceMin;
  final double? priceMax;
  final String? whatsapp;
  final City? city;
  final bool verified;
  final Availability availability;
  final double ratingAvg;
  final int ratingCount;
  final List<Category> categories;
}

class ServiceRequest {
  final String id;
  final String clientId;
  final String technicianId;
  final RequestStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
}

class Review {
  final String id;
  final String requestId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;
}

class Category { final String id; final String name; final String? icon; }
class Region { final String id; final String name; }
class City { final String id; final String name; final String regionId; }

class AppNotification {
  final String id;
  final String type; // request_update | verification | system
  final String message;
  final bool isRead;
  final DateTime createdAt;
}
```

These map 1:1 to the Postgres tables/enums in `database/schema.sql`, so JSON parsing needs no translation layer beyond `freezed`'s generated `fromJson`.

---

## 6. Phased Roadmap

Each phase lists **what to build → dependencies → output → acceptance criteria**. Build in this order — later phases assume earlier ones are done and tested.

### Phase 0 — Project Setup & Core
- **Build:** Flutter project init, folder structure above, `DioClient` with base URL + JWT interceptor + error mapper (maps backend `{error:{code,message}}` shape to typed `Failure`s: `AuthFailure`, `ValidationFailure`, `NetworkFailure`, `ServerFailure`), `go_router` skeleton with placeholder screens, theme matching web brand color (`#16A34A`), `SecureStorage` wrapper.
- **Depends on:** Backend running and reachable (Phase 0 of backend, already done).
- **Output:** App builds and runs, shows a themed splash screen, hits `GET /health` successfully.
- **Acceptance:** Cold start → splash → empty home shell, no crashes, correct base URL for emulator vs. physical device documented in README.

### Phase 1 — Authentication
- **Build:** Register screen (role picker: Client/Technician), Login screen, `AuthRepository` (register/login/me/logout), Riverpod `authProvider` (holds current user + loading/error state), route guard redirecting unauthenticated users to Login for protected routes, token persistence across app restarts (auto-login via `/api/auth/me` if a token exists).
- **Depends on:** Phase 0.
- **Output:** A user can register as Client or Technician, log in, stay logged in after app restart, and log out.
- **Acceptance:** All 4 error cases surfaced correctly in UI: invalid credentials (401), duplicate email (409), validation errors (400, field-level), expired token → forced logout.

### Phase 2 — Technician Directory (read path)
- **Build:** Home screen (search bar + category grid, pulled from `GET /api/technicians` and a cached reference-data call for categories/regions/cities), Directory/results screen with filter sheet (city, region, category, availability, rating) and pagination (infinite scroll), Technician Profile screen (bio, price range, rating, reviews list via `GET /api/technicians/:id/reviews`).
- **Depends on:** Phase 0 (auth not required — directory is public per spec).
- **Output:** Full browse-and-search experience, usable even logged out.
- **Acceptance:** Filters combine correctly (matches FR-11 "advanced search combining multiple filters"), pagination doesn't duplicate/drop results, empty-state and error-state UI both handled.

### Phase 3 — Favorites & Client Profile
- **Build:** Favorite toggle (heart icon) on directory cards and profile screen, Favorites list screen, basic Client profile edit (name, phone, avatar upload via `image_picker`).
- **Depends on:** Phase 1 (requires auth), Phase 2 (technician cards to favorite).
- **Output:** Client can save/unsave technicians and view their list.
- **Acceptance:** Favorite state persists and reflects correctly across Directory, Profile, and Favorites screens (single source of truth in Riverpod state, not re-fetched inconsistently).

### Phase 4 — Service Request Lifecycle
- **Build:** "Send Request" flow from Technician Profile (description field → `POST /api/requests`), Client "My Requests" list with status chips and pull-to-refresh, Technician "Incoming Requests" list with Accept/Reject/Mark In Progress/Mark Completed actions, request detail screen showing the full status history.
- **Depends on:** Phase 1, Phase 2 (need a technician to request).
- **Output:** The complete Pending → Accepted → In Progress → Completed/Cancelled/Rejected loop works end-to-end between a Client account and a Technician account.
- **Acceptance:** Every state transition in `database/schema.sql`'s `request_status` enum is reachable from the UI on the correct role, and illegal transitions (e.g., completing a Pending request) are blocked client-side AND rejected by the backend (defense in depth).

### Phase 5 — Reviews
- **Build:** Rate & Review screen (triggered from a Completed request), star input + comment field (`POST /api/reviews`), reviews rendering on Technician Profile (already scaffolded in Phase 2, now populated).
- **Depends on:** Phase 4 (needs a Completed request to rate).
- **Output:** Client can rate a completed job exactly once; technician's `rating_avg`/`rating_count` reflect it (backend trigger handles the math — mobile just re-fetches).
- **Acceptance:** Attempting to review a non-Completed or already-reviewed request is blocked, matching backend's `409`/`400` responses.

### Phase 6 — Technician Onboarding & Verification
- **Build:** Professional profile completion form (bio, years experience, price range, categories multi-select, city picker, WhatsApp), document upload screen (camera/gallery via `image_picker` → `POST /api/technicians/:id/documents`), availability toggle.
- **Depends on:** Phase 1 (technician role), Phase 2 (category/city reference data already fetched).
- **Output:** A technician can go from bare registration to a complete, submitted-for-verification profile.
- **Acceptance:** Upload respects the backend's 5MB / image-or-pdf constraint client-side before hitting the network; profile shows "Pending Verification" state until an admin approves via the web back-office.

### Phase 7 — Dashboards & Notifications
- **Build:** Technician dashboard (profile views, completed jobs, pending requests, rating — `GET` aggregate, to be added on the backend), Client dashboard (quick links: active requests, favorites), Notifications screen (`GET /api/notifications`, mark-as-read, unread badge on a bottom-nav icon), pull-to-refresh or short-interval polling (no WebSocket per NFR).
- **Depends on:** Phases 1–6 (dashboards surface data from all of them).
- **Output:** Each role has a home base summarizing their activity.
- **Acceptance:** Badge counts and stats match what's independently visible in the Requests/Favorites screens (no drift between summary and detail views).

### Phase 8 — Polish, Error States, Testing
- **Build:** Consistent loading/empty/error widgets across all screens, French-first copy (per user base) with structure ready for `intl` if English is added later, unit tests for repositories/use cases, widget tests for critical flows (login, send request, submit review), manual QA pass against the Sample Test Cases table in the Cahier de Charges (TC-01 through TC-10).
- **Depends on:** All prior phases.
- **Output:** MVP-ready build.
- **Acceptance:** Every TC-01–TC-10 test case from the spec passes on-device; app handles offline/timeout gracefully (no white screens or stuck spinners).

---

## 7. Missing Requirements / Open Questions to Resolve Before or During Build

These aren't blockers for Phase 0–2, but need answers before the phases that touch them:

1. **Backend aggregate endpoints don't exist yet.** `technicians.service.js`, `requests.service.js`, and an admin-style `/technician-stats` endpoint for the Technician Dashboard (Phase 7) are still `501 NOT_IMPLEMENTED` in the Express scaffold — they need to be built before Phase 2/4/7 can integrate for real.
2. **Notification delivery mechanism.** Spec confirms in-app only for V1 (no push/SMS/WhatsApp) — confirms polling or pull-to-refresh is sufficient; no FCM setup needed yet.
3. **Image compression before upload.** Spec doesn't mention it, but Cameroon's bandwidth constraints (explicitly called out as a NFR) suggest client-side image compression before profile photo / document upload — recommend adding this in Phase 6, flagging here since it's an addition beyond the literal spec text.
4. **French vs. bilingual UI.** You communicate in French and the target market is Cameroonian; spec text itself is bilingual (French subtitle, English body). Recommend building all copy in French for V1 and structuring strings for `intl` so English can be added later without rework — confirm this matches your intent.
5. **Admin on mobile.** Locked as web-only in Section 0 — flag if that's wrong.
6. **Deep linking / share.** Not in the spec. Worth deciding now if a shared technician-profile link (e.g., for WhatsApp sharing, which is culturally how referrals already happen per the Research Report) should be in scope — cheap to add in Phase 2 if decided early, expensive to retrofit.

---

## 8. Environment & Build Setup

```yaml
# pubspec.yaml additions (on top of the existing scaffold)
dependencies:
  flutter_riverpod: ^2.5.1
  dio: ^5.6.0
  go_router: ^14.2.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.2   # kept from scaffold
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  image_picker: ^1.1.2
  cached_network_image: ^3.4.0

dev_dependencies:
  build_runner: ^2.4.12
  freezed: ^2.5.7
  json_serializable: ^6.8.0
```

```dart
// lib/core/network/dio_client.dart — sketch, matches backend base URL convention
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000/api', // Android emulator -> host
);
```

Run with: `flutter run --dart-define=API_BASE_URL=https://your-deployed-api.com/api` for staging/prod builds — avoids hardcoding per environment.

---

## 9. Build Order Summary (dependency graph)

```
Phase 0 (setup)
   └─▶ Phase 1 (auth)
          ├─▶ Phase 2 (directory — public, but dashboard nav needs auth)
          │      ├─▶ Phase 3 (favorites)
          │      └─▶ Phase 4 (requests) ──▶ Phase 5 (reviews)
          └─▶ Phase 6 (technician onboarding, parallel to 3/4/5)
                     └─▶ Phase 7 (dashboards, needs 1–6)
                              └─▶ Phase 8 (polish + testing)
```

Phases 3, 4, and 6 can be built in parallel by splitting work (e.g., across two developers) once Phase 2 is done — they don't depend on each other, only on Phase 1/2.
