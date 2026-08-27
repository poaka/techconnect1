# FixerPro237 Cameroun — Roadmap

**How to read this:** phases are ordered by technical dependency, not by feature category. Don't start a phase before its dependencies are done and acceptance criteria are met — that's how "build hard and easy things in parallel" mistakes happen. Riskiest/foundational work comes first; the most complex/optional layers (real-time chat, payments, GPS) are pushed to Post-V1 on purpose.

---

## Phase 0 — Foundations (Backend + Database)
**Status: mostly done.**
- Supabase project + `database/schema.sql` (tables, enums, triggers, RLS, seed data) ✅
- Express skeleton: config, middleware (`auth.js`, `errorHandler.js`, `upload.js`), route structure for all 7 modules ✅
- Auth module fully implemented (`register`, `login`, `me`, bcrypt + JWT + rate limiting) ✅
- **Remaining:** everything else in `backend/src/routes/*.routes.js` is stubbed `501 NOT_IMPLEMENTED` — this is the actual riskiest/most load-bearing work, since web and mobile both block on it.
- **Acceptance to close this phase:** `technicians`, `requests`, `reviews`, `favorites`, `notifications`, `admin` services implemented and manually tested against the Sample Test Cases (TC-01–TC-10) in the Cahier de Charges.

## Phase 1 — Web MVP: Auth + Directory (React)
- Depends on: Phase 0 auth + technicians endpoints.
- Build: Login/Register (done), Directory search/filter page, Technician Profile page.
- Acceptance: a client can browse and search technicians end-to-end on web without a mobile app existing yet — validates the backend contract before mobile consumes it too.

## Phase 2 — Mobile Setup + Core (Flutter)
- Depends on: Phase 0.
- Build: project init, clean-architecture folder structure, `DioClient` + JWT interceptor + error mapper, `go_router` skeleton, theme.
- Acceptance: app runs, hits `/health`, themed shell in place. (Full detail in `FLUTTER_MVP_BLUEPRINT.md` §Phase 0.)

## Phase 3 — Mobile Auth
- Depends on: Phase 2, Phase 0 auth.
- Build: Register/Login, `authProvider`, route guards, auto-login on restart.
- Acceptance: all 4 auth error cases (401 invalid, 409 duplicate, 400 validation, expired token) correctly surfaced in UI.

## Phase 4 — Directory (Web polish + Mobile)
- Depends on: Phase 0 technicians endpoint (search/filter/sort/paginate), Phase 1 (web reference implementation), Phase 3 (mobile auth for the nav shell, though directory itself is public).
- Build: Mobile Home + Directory + Technician Profile screens; web directory filter UX polish.
- Acceptance: filters combine correctly on both platforms (city + category + rating simultaneously = FR-11), pagination is consistent, empty/error states handled.

## Phase 5 — Service Requests (Web + Mobile, parallel)
- Depends on: Phase 0 requests endpoint + state-machine validation, Phase 4 (need a technician to request).
- Build: Create request, status tracking, Accept/Reject/In Progress/Completed actions on both client types.
- Acceptance: the full `pending → accepted → in_progress → completed/cancelled/rejected` lifecycle is reachable and enforced identically on web and mobile — illegal transitions rejected by backend regardless of which client attempts them.

## Phase 6 — Reviews
- Depends on: Phase 5 (needs a Completed request).
- Build: Rate & Review flow (web + mobile), review list on Technician Profile, backend trigger already recomputes `rating_avg`/`rating_count` (done in `schema.sql`).
- Acceptance: one review per completed request enforced (DB unique constraint + API check), non-Completed requests can't be reviewed.

## Phase 7 — Favorites (Web + Mobile, parallel with Phase 6)
- Depends on: Phase 4.
- Build: add/remove/list favorites.
- Acceptance: favorite state is consistent across Directory, Profile, and Favorites list on both platforms.

## Phase 8 — Technician Onboarding & Verification (Web + Mobile)
- Depends on: Phase 3 (technician auth), Phase 4 (category/city reference data).
- Build: professional profile completion form, document upload (Supabase Storage wiring — currently the one piece of `upload.js` middleware that's stubbed on the backend), availability toggle, admin approval flow on the web back-office.
- Acceptance: a technician can go from bare registration to "Pending Verification" to "Verified" (via admin action on web) end-to-end.

## Phase 9 — Dashboards & Notifications (Web + Mobile)
- Depends on: Phases 1–8 (dashboards aggregate data from all of them).
- **Status: ✅ IMPLEMENTED (July 2026)**
- Build: Client dashboard (active requests count, favorites count, quick actions), Technician dashboard (real stats from `GET /api/technicians/me/stats` — pending, completed, rating avg, availability), in-app Notifications list + unread badge (polling every 30s), bottom navigation shell (`StatefulShellRoute`) with 4 tabs per role.
- Acceptance: dashboard numbers match what's independently visible in detail screens (no drift). ✅

## Phase 10 — Hardening & Testing
- Depends on: everything above.
- **Status: ✅ IMPLEMENTED (Mobile Only)**
- Build: consistent loading/empty/error UI across both clients, security pass (rate limiting, input sanitization, CORS, RLS review), performance pass (Lighthouse for web, cold-start profiling for mobile), full manual QA against TC-01–TC-10, unit/integration tests (Jest+Supertest backend, RTL/Cypress web, widget tests mobile).
- Acceptance: every sample test case passes on both platforms; no unhandled error states (white screens, stuck spinners).

## Phase 11 — Deployment
- Depends on: Phase 10.
- Build: web → Vercel/Netlify + CDN; backend → Render/Railway (Dockerized); Supabase Cloud already live; GitHub Actions CI/CD (lint/test/build/deploy on push to main); mobile → signed builds for Play Store / TestFlight internal testing.
- Acceptance: production URLs live, environment variables managed via host secrets (never committed), monitoring via host logs + Supabase dashboard.

---

## Post-V1 (deliberately deferred — do not start early)

Real-time chat · Mobile Money (MTN MoMo, Orange Money) · GPS/proximity search · AI-driven recommendations · Voice search · Push notifications (FCM/SMS/WhatsApp) · PWA/offline-first · National expansion beyond Yaoundé · Admin on mobile.

These are deferred **on purpose** — building them before the V1 loop (search → verify → request → rate) is proven working would be building complex/expensive layers before the simple foundation is validated, which is the exact mistake this roadmap structure is designed to avoid.

---

## Dependency Graph (condensed)

```
Phase 0 (backend+DB)
 ├─▶ Phase 1 (web directory)
 └─▶ Phase 2 (mobile setup) ─▶ Phase 3 (mobile auth)
        └─▶ Phase 4 (directory, both platforms)
               ├─▶ Phase 5 (requests) ─▶ Phase 6 (reviews)
               ├─▶ Phase 7 (favorites)
               └─▶ Phase 8 (technician verification)
                      └─▶ Phase 9 (dashboards + notifications)
                             └─▶ Phase 10 (hardening) ─▶ Phase 11 (deploy)
```
