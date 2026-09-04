# Prompt for Claude AI to Generate UML Diagrams

**Copy and paste everything below this line into Claude:**

---

**Act as an Expert Software Architect and UML Specialist.**

I am building an application called **FixerPro237 Cameroun**, a platform that connects clients with local home service technicians (electricians, plumbers, mechanics, etc.) in Cameroon. The project consists of a PostgreSQL database (managed via Supabase), a Node.js/Express REST API backend, and a Flutter mobile application. The core logic relies on an intelligent "Dispatch" system, not a simple open directory.

Please analyze the architecture and database schema provided below and generate the following 9 UML diagrams using **Mermaid.js** syntax (so they can be rendered directly in Markdown):

1. **Entity-Relationship Diagram (ERD)**
2. **System Component Diagram** (Mobile App, Backend API, Supabase Database, Auth Service)
3. **High-Level Class Diagram (Flutter App)** (Clean Architecture representation)
4. **Sequence Diagram (Core Business Loop: Dispatch & Job Offers)**
5. **Sequence Diagram (GPS Tracking)**
6. **State Diagram (Service Request Lifecycle)**
7. **State Diagram (Job Offer Lifecycle)**
8. **Deployment Diagram**
9. **Activity Diagram (Technician Onboarding)**

---

### Context 1: Database Schema (Supabase / PostgreSQL)
Here is the core database structure:

*   **Enums:** `user_role` (client, technician, admin), `availability_status` (available, busy, offline), `request_status` (unassigned, assigned, in_progress, completed, cancelled), `offer_status` (pending, accepted, rejected, expired), `document_type`, `document_status`.
*   **users:** id (UUID), full_name, email, phone, password_hash, role, avatar_url.
*   **regions:** id, name.
*   **cities:** id, name, region_id (FK).
*   **categories:** id, name, icon, description.
*   **technician_profiles:** id, user_id (FK), bio, years_experience, price_min, price_max, whatsapp, city_id (FK), verified (Boolean), availability, rating_avg, rating_count, active_job_count (integer), category_id (FK - 1 technician has 1 category).
*   **technician_documents:** id, technician_id (FK), document_type, file_url, status.
*   **service_requests:** id, client_id (FK), assigned_technician_id (FK, nullable), category_id (FK), city_id (FK), status, description, address, latitude, longitude, created_at, completed_at.
*   **job_offers:** id, request_id (FK), technician_id (FK), status, expires_at, created_at.
*   **location_updates:** id, request_id (FK), technician_id (FK), latitude, longitude, updated_at.
*   **reviews:** id, request_id (FK, Unique), client_id (FK), technician_id (FK), rating, comment.
*   **favorites:** id, client_id (FK), technician_id (FK).
*   **notifications:** id, user_id (FK), type, title, message, is_read, metadata.

### Context 2: Backend Architecture (Node.js / Express)
*   The backend is a REST API built with Express.js.
*   It serves main modules: 
    *   `/api/auth` (Register, Login, Me)
    *   `/api/technicians` (Search, Filter, Profile stats)
    *   `/api/requests` (Create, Status updates, GPS location)
    *   `/api/offers` (Accept, Reject)
    *   `/api/reviews`, `/api/favorites`, `/api/notifications`, `/api/admin`
*   **Core Logic (Dispatch & CAS):** 
    *   `DispatchService` finds technicians by city, category, and sorts by `active_job_count` ASC.
    *   `OffersService` handles accepting an offer using a Compare-And-Swap (CAS) atomic UPDATE to guarantee only 1 technician wins the request.

### Context 3: Mobile Architecture (Flutter)
*   **Navigation:** Uses `go_router` for a stateful shell navigation (bottom tabs).
*   **Networking:** Uses `Dio` for API calls.
*   **State Management:** Uses Providers/Riverpod (`FutureProvider`, `StateNotifierProvider`).
*   **Structure:** Feature-based Clean Architecture (e.g. `features/requests`, `features/offers`).
*   **GPS:** Uses `geolocator` plugin to share location during active requests.

---

**Output Requirements:**
Please output ONLY the Mermaid code blocks for the 9 requested diagrams. Ensure the Mermaid syntax is valid.
