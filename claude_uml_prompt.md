# Prompt for Claude AI to Generate UML Diagrams

**Copy and paste everything below this line into Claude:**

---

**Act as an Expert Software Architect and UML Specialist.**

I am building an application called **FixerPro237 Cameroun**, a platform that connects clients with local home service technicians (electricians, plumbers, mechanics, etc.) in Cameroon. The project consists of a PostgreSQL database (managed via Supabase), a Node.js/Express REST API backend, and a Flutter mobile application.

Please analyze the architecture and database schema provided below and generate the following UML diagrams using **Mermaid.js** syntax (so they can be rendered directly in Markdown):

1.  **Entity-Relationship Diagram (ERD):** Showing all database tables, their columns, primary/foreign keys, and relationships.
2.  **System Component Diagram:** Showing the high-level architecture (Mobile App, Backend API, Supabase Database, Auth Service) and how they interact.
3.  **High-Level Class Diagram (Flutter App):** Illustrating the Clean Architecture used in the Flutter app (Presentation, Domain, Data layers) for a core feature (like `Technicians` or `Service Requests`).
4.  **Sequence Diagram (Core Business Loop):** Illustrating the lifecycle of a Service Request: Client searches for a technician -> Client creates a request -> Backend creates it -> Technician accepts -> Technician completes -> Client leaves a review.

---

### Context 1: Database Schema (Supabase / PostgreSQL)
Here is the core database structure:

*   **Enums:** `user_role` (client, technician, admin), `availability_status` (available, busy, offline), `request_status` (pending, accepted, rejected, in_progress, completed, cancelled), `document_type`, `document_status`.
*   **users:** id (UUID), full_name, email, phone, password_hash, role, avatar_url.
*   **regions:** id, name.
*   **cities:** id, name, region_id (FK).
*   **categories:** id, name, icon, description.
*   **technician_profiles:** id, user_id (FK to users), bio, years_experience, price_min, price_max, whatsapp, city_id (FK to cities), verified (Boolean), availability, rating_avg, rating_count.
*   **technician_categories:** technician_id (FK), category_id (FK). *(Many-to-Many)*
*   **technician_documents:** id, technician_id (FK), document_type, file_url, status. *(For verification)*
*   **service_requests:** id, client_id (FK to users), technician_id (FK to technician_profiles), category_id (FK), status, description, address, created_at, completed_at.
*   **reviews:** id, request_id (FK, Unique), client_id (FK), technician_id (FK), rating, comment. *(Max 1 review per completed request)*
*   **favorites:** id, client_id (FK), technician_id (FK).
*   **notifications:** id, user_id (FK), type, title, message, is_read, metadata.

### Context 2: Backend Architecture (Node.js / Express)
*   The backend is a REST API built with Express.js.
*   It serves 7 main modules/routes: 
    *   `/api/auth` (Register, Login, Me)
    *   `/api/technicians` (Search, Filter, Profile stats)
    *   `/api/requests` (Create, Status updates)
    *   `/api/reviews` (Create, List)
    *   `/api/favorites` (Add, Remove, List)
    *   `/api/notifications` (List, Mark read)
    *   `/api/admin` (Verify technicians, view stats)
*   **Layers:** Routes -> Controllers -> Services -> Database (Supabase Client).
*   **Middlewares:** `auth.js` (JWT validation), `errorHandler.js`, `upload.js`.

### Context 3: Mobile Architecture (Flutter)
*   **Navigation:** Uses `go_router` for a stateful shell navigation (bottom tabs).
*   **Networking:** Uses `Dio` for API calls with JWT interceptors.
*   **State Management:** Uses Providers/Riverpod.
*   **Structure:** Feature-based Clean Architecture. Main features include: `auth`, `technicians`, `requests`, `favorites`, `notifications`. 
*   Each feature contains:
    *   **Presentation:** Screens, Widgets, Providers (State).
    *   **Domain:** Models (e.g., `NotificationModel`, `City`), Entities.
    *   **Data:** Repositories, API Clients.

---

**Output Requirements:**
Please output ONLY the Mermaid code blocks for the 4 requested diagrams, with brief explanations before each one explaining your design choices. Ensure the Mermaid syntax is valid and uses modern diagram types (`erDiagram`, `classDiagram`, `sequenceDiagram`, `flowchart` or `componentDiagram`).
