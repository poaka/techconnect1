# FixerPro237 - Backend Documentation

This document provides a deep analysis of the Node.js backend architecture, routing, and features for the FixerPro237 platform.

## Overview
The backend is built with **Node.js** and **Express.js**. It exposes a RESTful API prefixed with `/api`. Data persistence is handled by **Supabase (PostgreSQL)**, with a robust fallback mechanism using an in-memory map for local testing when Supabase credentials are not provided.

## Architecture
The backend strictly follows the **Controller-Service-Route** pattern:
- **Routes (`src/routes`)**: Defines API endpoints and attaches middleware (e.g., auth guards).
- **Controllers (`src/controllers`)**: Handles HTTP requests, extracts parameters/body, and calls the appropriate service. Formats the JSON response.
- **Services (`src/services`)**: Contains the core business logic, database queries, and data manipulation.

## Features & Endpoints

### 1. Authentication
Handles secure user registration, login, and password management.
- **Service**: `auth.service.js` (Manages `bcryptjs` hashing and `jsonwebtoken` signing).
- **Routes**:
  - `POST /api/auth/register`: Create a new user (Client or Technician).
  - `POST /api/auth/login`: Authenticate and return JWT token.
  - `POST /api/auth/change-password`: Validates old password and updates the hash in Supabase.
  - `GET /api/auth/me`: Retrieves details of the currently authenticated user.

### 2. Technicians
Manages the directory of service providers.
- **Routes**:
  - `GET /api/technicians`: Retrieves paginated list of technicians. Supports `category` UUID filter and `q` search queries.
  - `GET /api/technicians/:id`: Retrieves detailed profile info for a specific technician.
  - `GET /api/technicians/categories`: Returns a list of all service categories available in the system.

### 3. Service Requests
Handles the core business transaction between clients and technicians.
- **Routes**:
  - `POST /api/requests`: Client creates a new service request.
  - `GET /api/requests`: Retrieves requests belonging to the authenticated user.
  - `PATCH /api/requests/:id/status`: Updates request status (e.g., `accepted`, `completed`). This action automatically triggers the Notification service.

### 4. Reviews
Manages post-job feedback.
- **Routes**:
  - `POST /api/reviews`: Client creates a review for a completed job.
  - `GET /api/reviews/technician/:id`: Retrieves paginated reviews for a technician.

### 5. Favorites
Allows clients to bookmark preferred technicians.
- **Routes**:
  - `POST /api/favorites/:technicianId`: Toggles (adds/removes) a technician in the authenticated client's favorites.
  - `GET /api/favorites`: Retrieves the client's list of favorited technicians.

### 6. Notifications
System alerts generated internally by status changes.
- **Routes**:
  - `GET /api/notifications`: Retrieves all notifications for the user.
  - `PATCH /api/notifications/:id/read`: Marks a single notification as read.
  - `PATCH /api/notifications/read-all`: Marks all notifications as read.
- **Internal Triggers**: The `RequestsService` automatically calls the `NotificationsService` to generate alerts when a request changes status.

### 7. Admin & Reporting
Exclusive endpoints for system administration and overview.
- **Routes**:
  - `GET /api/admin/stats`: Aggregates system metrics (Total users, Active requests, Revenue).
  - `GET /api/admin/users`: Retrieves all users for moderation.
  - `POST /api/admin/categories`: Creates a new category.
  - `GET /api/report`: Generates CSV/JSON exports for system reports.

## Middleware & Security
- **Auth Guard (`auth.middleware.js`)**: Validates the JWT Bearer token and attaches the decoded user to `req.user`.
- **Role Guard**: Specific routes (like `/api/admin/*`) require the user's role to be verified (e.g., must be `admin`).
- **Error Handling**: Centralized error mapping ensuring structured `{"error": ...}` JSON responses for all HTTP failures.
