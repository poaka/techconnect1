# Feature Gap Analysis: Backend vs. Flutter Mobile App

This document provides a deep and complete analysis of all the features implemented on the backend and compares them directly to the Flutter mobile application to identify exactly what is missing on the mobile side.

---

## 1. Authentication (Auth)
**Backend Implementation:**
- `POST /api/auth/register` (Registers users)
- `POST /api/auth/login` (Authenticates and returns JWT)
- `POST /api/auth/change-password` (Updates password)
- `GET /api/auth/me` (Gets user profile)

**Flutter Implementation:** 
- **100% Complete**. All endpoints are connected in `auth_remote_data_source.dart`. Forms and screens exist for all actions.

---

## 2. Technicians & Directory
**Backend Implementation:**
- `GET /api/technicians` (Search and list with filters)
- `GET /api/technicians/:id` (Fetch profile)
- `GET /api/technicians/categories` (Get service categories)
- `GET /api/technicians/cities` (Get cities)
- `GET /api/technicians/regions` (Get regions)

**Flutter Implementation:**
- **Mostly Complete**. The directory features, categories, and profile fetching are fully implemented in `technicians_remote_data_source.dart` and the UI. 

---

## 3. Service Requests
**Backend Implementation:**
- `POST /api/requests` (Create request)
- `GET /api/requests` (List incoming/outgoing requests)
- `PATCH /api/requests/:id/status` (Update status: pending, accepted, completed, etc.)

**Flutter Implementation:**
- **100% Complete**. `requests_remote_data_source.dart` perfectly maps to these endpoints. The UI includes the status color indicators and action buttons.

---

## 4. Notifications
**Backend Implementation:**
- `GET /api/notifications`
- `PATCH /api/notifications/:id/read`
- `PATCH /api/notifications/read-all`

**Flutter Implementation:**
- **100% Complete**. `notifications_remote_data_source.dart` connects these endpoints. The notification bell and unread counters are implemented in the UI.

---

## 5. Favorites
**Backend Implementation:**
- `POST /api/favorites/:technicianId`
- `GET /api/favorites`

**Flutter Implementation:**
- **100% Complete**. Fully connected in `favorites_remote_data_source.dart` with a dedicated UI tab in the app.

---

## 6. Reviews
**Backend Implementation:**
- `POST /api/reviews` (Create a review)
- `GET /api/technicians/:id/reviews` (Or fetched via profile)

**Flutter Implementation:**
- **100% Complete**. 
  - `POST /reviews` **is** implemented (`reviews_remote_data_source.dart`).
  - `GET /technicians/:id` from the backend actually populates the `reviews` array directly in the payload! The mobile app correctly parses this in `technician_profile.dart` and displays them in `technician_profile_screen.dart`.

---

## 7. Technician Profile Management
**Backend Implementation:**
- `GET /api/technicians/me/stats`
- `PUT /api/technicians/me/profile`
- `PUT /api/technicians/me/availability`
- `POST /api/technicians/me/documents`
- `GET /api/technicians/me/documents`

**Flutter Implementation:**
- **Incomplete**.
  - `me/stats` **is** implemented.
  - `me/profile` **is** implemented.
  - `me/availability` **is** implemented (called directly in `technician_dashboard_screen.dart` via the bottom sheet).
  - `me/documents` (GET and POST) are **MISSING**. Technicians cannot upload or view their verification documents.

---

## 8. Admin Panel
**Backend Implementation:**
- `GET /api/admin/stats`
- `GET /api/admin/verifications`
- `PATCH /api/admin/verifications/:documentId`
- `GET /api/admin/users`
- `DELETE /api/admin/users/:userId`
- `GET /api/admin/technicians`
- `GET /api/admin/categories`
- `POST /api/admin/categories`
- `PUT /api/admin/categories/:categoryId`
- `DELETE /api/admin/categories/:categoryId`
- Region & City Management (POST/PUT/DELETE for regions and cities)
- `GET /api/report/admin`
- `PATCH /api/report/admin/:id/resolve`

**Flutter Implementation:**
- **Incomplete**.
  - Stats, Verifications (GET and PATCH), GET Users, GET Technicians, Categories (GET, POST, PUT, DELETE), and Reports (GET, PATCH) **are** implemented.
  - `DELETE /api/admin/users/:userId` is **MISSING**. Admins cannot delete users from the mobile app.
  - Region & City Management (POST/PUT/DELETE) is **MISSING**. Admins cannot create or edit cities and regions from the mobile app.

---

# Summary List of Missing Flutter Features

Here is the exact and updated list of backend features that have **not yet been implemented** in the Flutter mobile application:

### Missing Technician Features:
1. **Document Management**: No API calls to `GET /api/technicians/me/documents` or `POST /api/technicians/me/documents` to allow technicians to upload KYC/Verification files.

### Missing Admin Features:
2. **Delete Users**: No API call to `DELETE /api/admin/users/:userId`. Admins can view users but cannot delete them from the app.
3. **Manage Regions**: Missing UI and API calls to Create, Update, or Delete regions (`/api/admin/regions`).
4. **Manage Cities**: Missing UI and API calls to Create, Update, or Delete cities (`/api/admin/cities`).
