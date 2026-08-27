# FixerPro237 Cameroun — AI Agent / Developer Guide

**Read this file first, before touching any code.** It's the entry point that ties the other docs together.

---

## 1. One-Paragraph Project Summary

FixerPro237 Cameroun is a full-stack platform (React web + Flutter mobile) that digitalizes the search, verification, and hiring of technicians/artisans in Cameroon, starting with a Yaoundé pilot. Clients search a filterable directory, send tracked service requests to technicians, and rate them after completion; technicians manage a professional profile and respond to requests; admins verify technician identity documents and moderate the platform. The backend is a Node.js/Express REST API backed by a Supabase-managed PostgreSQL database.

## 2. Core Architectural Decisions That Must Not Be Violated

1. **Express sits between every client and Supabase.** React and Flutter never call Supabase directly — they only call `/api/*` on the Express backend. The backend holds the `service_role` key; clients never see it. (Reconfirmed July 2026 — do not "simplify" this to a direct-to-Supabase architecture without an explicit new decision.)
2. **Single source of truth per data type:** Supabase Postgres is the source of truth for all persistent data (users, requests, reviews, etc.). Supabase Storage is the source of truth for uploaded files (avatars, ID documents, certificates). No client-side cache is ever authoritative — local storage (Hive, localStorage) is a performance/offline convenience only.
3. **Role-based access control is enforced server-side, always.** Every protected Express route uses `requireAuth` + `requireRole`. Client-side route guards (React `ProtectedRoute`, Flutter `go_router` guards) are UX conveniences, not security boundaries — never trust them as the only check.
4. **Admin is web-only.** Mobile V1 scope = Client + Technician roles only. This is a locked scope decision, not an oversight.
5. **No WebSocket / real-time dependency in V1.** Notifications and status updates use polling / pull-to-refresh, per the explicit non-functional requirement to work on unstable 3G.
6. **One review per completed request, enforced at the database level** (`reviews.request_id` is `unique`) — not just in application logic.

## 3. Tech Stack Summary

| Layer | Technology | Doc |
|---|---|---|
| Web frontend | React + Tailwind (Vite) | — (see `web/` folder, README) |
| Mobile frontend | Flutter (Client + Technician only) | `FLUTTER_MVP_BLUEPRINT.md` |
| Backend | Node.js + Express (REST API, MVC-ish: routes → controllers → services) | — (see `backend/` folder, README) |
| Database | Supabase-managed PostgreSQL + Storage + RLS | `database/schema.sql` |
| Auth | JWT (issued/verified by Express, not Supabase Auth) + Bcrypt | `backend/src/services/auth.service.js` |
| Product scope & rationale | — | `project-specification.md` |
| Build sequencing | — | `roadmap.md` |

*(Per-integration docs like `supabase.md` for Storage/RLS specifics haven't been written yet — recommended before Phase 8 (verification/document upload), since that's the first phase that seriously exercises Supabase Storage.)*

## 4. Non-Negotiable Rules

- **Cost-safety:** Supabase free/low-cost tier is assumed (per the Cahier de Charges constraints). Don't add usage-based paid services (SMS, push notification providers, third-party AI APIs) without an explicit decision — they're all in the deferred Post-V1 list for a reason.
- **Data ownership:** never duplicate write-paths. E.g., `rating_avg`/`rating_count` are computed by a Postgres trigger (`refresh_technician_rating()` in `schema.sql`) — application code must never write to those columns directly, or the two will drift.
- **Security:** passwords are bcrypt-hashed (min. 10 salt rounds), never logged or returned in API responses (`auth.service.js` explicitly deletes `password_hash` before returning a user object — follow that pattern everywhere).
- **Error shape consistency:** every API error follows `{ error: { code, message, details? } }` — both frontends should have one central place that maps this to UI (already done in `web/src/services/api.js` interceptor; mobile equivalent is the `error mapper` described in the Flutter blueprint's `core/network/`).

## 5. Repo / Folder Structure

```
fixerpro237-cameroun/
├── backend/                 Express REST API
│   └── src/{config,controllers,middleware,routes,services,utils}
├── web/                     React + Tailwind (Vite)
│   └── src/{components,pages,context,services}
├── mobile/                  Flutter (Client + Technician)
│   └── lib/{core,features,shared}   (target shape — see FLUTTER_MVP_BLUEPRINT.md §3)
├── database/
│   └── schema.sql           Full Postgres schema, triggers, RLS, seed data
├── docs/
│   ├── project-specification.md   (this doc set)
│   ├── roadmap.md
│   ├── AI-agent-guide.md          (this file)
│   └── FLUTTER_MVP_BLUEPRINT.md
└── README.md                 Setup instructions for all 4 pieces
```

## 6. Environment Variables Needed

**Backend (`backend/.env`):**
`PORT`, `NODE_ENV`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `CORS_ORIGIN`, `AUTH_RATE_LIMIT_WINDOW_MS`, `AUTH_RATE_LIMIT_MAX`

**Web (`web/.env`):**
`VITE_API_URL`

**Mobile:** no `.env` file — uses `--dart-define=API_BASE_URL=...` at build time (see `FLUTTER_MVP_BLUEPRINT.md` §8).

## 7. Build Order (see `roadmap.md` for full detail)

`Backend/DB foundations → Web directory (validates the API contract) → Mobile setup → Mobile auth → Directory (both) → Requests → Reviews / Favorites / Verification (parallel) → Dashboards & Notifications → Hardening → Deployment.`

The backend's non-auth routes (`technicians`, `requests`, `reviews`, `favorites`, `notifications`, `admin`) are currently stubbed `501 NOT_IMPLEMENTED` — **this is the actual current blocker** for both web and mobile progress past the auth screens. Implement them following the exact pattern already established in `auth.controller.js` / `auth.service.js`.

## 8. Every Doc in This Set

| Doc | One-line description |
|---|---|
| `project-specification.md` | Problem, users, goals, modules, user flows, MVP scope, differentiation, NFRs |
| `roadmap.md` | Phased build order across backend/web/mobile, with dependencies and acceptance criteria per phase |
| `AI-agent-guide.md` | This file — master index, architectural rules, stack summary, folder structure, env vars |
| `FLUTTER_MVP_BLUEPRINT.md` | Deep-dive Flutter-specific plan: clean architecture layout, package choices, data models, 8-phase mobile roadmap |
| `database/schema.sql` | Executable source of truth for the entire data model |
| `backend/README.md` / root `README.md` | Local setup instructions for Supabase, backend, web, mobile |

**Rule:** if a real-world decision changes (a package swap, a scope change, a discovered constraint), update the relevant doc immediately — these docs represent the current decision, not the first one made. Don't let code and docs drift apart.
