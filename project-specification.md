# FixerPro237 — Project Specification

**DÉCISIONS TRANCHÉES (Phase 0):**
1. **Annuaire vs Dispatch** : Modèle de Dispatch (le client poste une demande, le système trouve et assigne le technicien).
2. **Flutter vs React** : Mobile = Flutter, Web/Admin = React.
3. **1 vs N catégories** : 1 seule catégorie par technicien (relation 1-to-many).

**Status:** Living document — reflects the current locked decisions as of July 2026 (Express-in-the-middle architecture, mobile scope = Client + Technician).
**Source of truth chain:** Cahier de Charges v1.0 → Full Specification Book v2.0 → this document (consolidates and supersedes wording conflicts between the two, e.g. the "Visitor" role, which is folded into Client everywhere in this doc).

---

## 1. Problem Statement

In Cameroon, finding a reliable technician — electrician, plumber, mechanic, carpenter, computer/phone repairer, tailor, painter, mason, and other skilled trades — is handled informally through family recommendations, WhatsApp groups, Facebook posts, and physical markets (e.g. Mvog-Ada, Briqueterie in Yaoundé). This produces long search delays, no way to verify a technician's identity or competence before letting them into a home or business, no standardized way to compare providers on price/experience/rating, and no record of past work or recourse for poor service. Existing local attempts (iCiyaTout, TAQ App, MboaTek, Senvato, IMHOTEP) only partially solve this — weak filtering, no real verification, no structured request workflow.

## 2. Target Users

- **Client** — an individual or small business in Cameroon (pilot: Yaoundé) who needs to find and hire a technician. Not tech-savvy by default; often on a budget 3G/4G connection.
- **Technician** — an independent artisan/tradesperson who wants online visibility and a structured way to receive and manage job requests, without needing their own website or marketing.
- **Administrator** — platform operator (initially the founder/student team) responsible for verifying technician identity/credentials and moderating the platform.

## 3. Product Goals

1. Digitalize technician discovery for clients across Cameroon, starting with a Yaoundé pilot.
2. Build trust through mandatory identity/credential verification and a reputation system tied to confirmed completed jobs (not open, unmoderated reviews).
3. Give technicians a free digital storefront and a structured request inbox, replacing ad-hoc WhatsApp coordination.
4. Keep the system usable on low-to-moderate bandwidth (a stated non-functional constraint, not an afterthought).
5. Ship a scope that is realistically buildable as a Bachelor's Final Year Project in one semester, with a credible path to a real commercial product afterward.

## 4. Core Modules

| Module | Description |
|---|---|
| Authentication | Register (Client/Technician), login, JWT sessions, password recovery, RBAC |
| Technician Directory | Search, multi-filter (city, region, category, availability, rating, price), sort, pagination |
| Service Request Workflow | Client → Technician request lifecycle: Pending → Accepted → In Progress → Completed / Rejected / Cancelled |
| Verification | Technician uploads ID + certificate; Admin approves/rejects before the profile is publicly marked "verified" |
| Rating & Review | 1–5 stars + written comment, only after a request is Completed; drives the technician's public reputation score |
| Favorites | Client saves technicians for quick access later |
| Dashboards | Role-specific: Client (requests, favorites), Technician (profile views, completed jobs, pending requests, rating), Admin (platform-wide analytics, web-only) |
| Notifications | In-app notifications on request status changes (email/SMS/WhatsApp/push explicitly deferred) |

## 5. User Flows

### 5.1 Client
Browse (no account needed) → Register/Login → Search & filter Directory → View Technician Profile → Send Service Request → Track status in "My Requests" → On Completed: Rate & Review → Manage Favorites → Receive in-app Notifications on every status change.

### 5.2 Technician
Register (role=technician) → Complete professional profile (bio, experience, price range, categories, city, WhatsApp) → Upload ID + certificate for verification → (Admin approves) → Receive incoming requests → Accept/Reject → Mark In Progress → Mark Completed → Rating accrues on public profile → Toggle availability at any time.

### 5.3 Administrator (web only)
Login → Review pending verification documents → Approve/reject technician accounts → Manage categories/regions/cities → Manage/suspend/delete user accounts → View platform-wide analytics.

## 6. MVP Scope

**In scope (V1):**
- Everything in Section 4's core modules, for web (React) and mobile (Flutter, Client+Technician only).
- 21 seeded service categories, 10 regions with major cities (Cameroon-specific, admin-extensible).
- JWT auth with bcrypt password hashing, RBAC on every protected route.
- Structured verification workflow (manual admin review, not automated).

**Explicitly excluded from V1** (documented, not forgotten):
- Real-time chat between client and technician.
- Mobile Money integration (MTN MoMo, Orange Money).
- GPS/proximity-based search.
- AI-driven recommendation engine.
- Voice search.
- Push notifications (FCM), SMS, WhatsApp delivery channels — in-app only for V1.
- Progressive Web App / offline-first sync.
- Admin functionality on mobile.

## 7. Differentiation Strategy

Per the competitive analysis (WhatsApp/Facebook, iCiyaTout, TAQ App, MboaTek, Senvato, IMHOTEP): none of the existing options combine **structured identity verification** + a **full trackable request lifecycle** + a **reputation system tied to confirmed completed jobs**. TechConnect's bet is "trust as the product" — not just another open directory, but a platform where a technician's rating actually means something because it's gated behind a real completed transaction, and where identity has been checked by a human admin before the profile goes live.

## 8. Non-Functional Requirements

- **Performance / bandwidth:** must function acceptably on unstable 3G — server-side pagination, lazy loading, compressed assets, no WebSocket dependency in V1.
- **Security:** JWT + bcrypt (min. 10 salt rounds), RBAC on every endpoint, rate limiting on auth routes, input sanitization, XSS/SQL-injection protection, CORS whitelisting, validated file uploads (type + size) for identity documents.
- **Reliability:** structured error responses (`{error:{code,message}}`) with correct HTTP status codes across the board (400/401/403/404/409/429/500), correlation IDs on server errors for traceability.
- **Scalability:** Supabase-managed Postgres with RLS as a defensive layer; architecture designed to extend from Yaoundé pilot → national → Central African expansion without a rewrite.
- **Data protection:** general compliance with personal/identity data protection principles (documents are stored via Supabase Storage, not exposed publicly by default).

## 9. Roles Summary Table

| Role | Web | Mobile | Key permissions |
|---|---|---|---|
| Client | ✅ | ✅ | Browse, search, request, review, favorite |
| Technician | ✅ | ✅ | Manage profile, respond to requests, view stats |
| Administrator | ✅ | ❌ (out of scope) | Verify technicians, moderate, manage taxonomy, analytics |
