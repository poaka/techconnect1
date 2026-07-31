# TechConnect - Mobile App Documentation

This document outlines the architecture, state management, and features of the TechConnect Flutter application.

## Overview
The mobile app is built using **Flutter** and utilizes **Riverpod** for robust state management. It provides distinct interfaces based on user roles (Client, Technician, Admin) while sharing common components. Network requests are handled by **Dio** with automatic token injection.

## Project Structure
The app follows a feature-first folder architecture within `lib/features/`:

```text
lib/
├── core/            # Core utilities (network, storage, themes, utils)
├── shared/          # Shared widgets (MainShell, AppButton, AppTextField)
└── features/        # Feature modules
```

## Features

### 1. Authentication (`features/auth`)
- **State Management**: `auth_provider.dart` manages the current user session and authentication status.
- **Network (`DioClient`)**: Uses a `JwtInterceptor` to attach the Bearer token stored securely via `flutter_secure_storage`.
- **UI Screens**: 
  - Login & Registration screens with inline validation.
  - Integration with the Profile screen for "Change Password".

### 2. Technicians (`features/technicians`)
- **Role**: Allows clients to browse, search, and filter available technicians.
- **Components**:
  - `HomeScreen`: Landing page displaying featured technicians and categories.
  - `TechnicianListScreen`: Comprehensive list with search by name and category filtering.
  - `TechnicianProfileScreen`: Displays detailed bios, total jobs, and reviews.

### 3. Service Requests (`features/requests`)
- **Role**: The core workflow of the app where clients request services and technicians manage them.
- **Components**:
  - Status management (Pending, Accepted, In Progress, Completed, Rejected).
  - List views tailored for the authenticated user (Incoming requests for Technicians, Outgoing for Clients).
  - Dynamic status badges with color-coded UI indicators.

### 4. Reviews (`features/reviews`)
- **Role**: Enables clients to rate technicians after a job is completed.
- **Components**:
  - Modal sheets for submitting a 1-5 star rating and text feedback.
  - Read-only list views on technician profiles displaying aggregate ratings.

### 5. Favorites (`features/favorites`)
- **Role**: Allows clients to bookmark technicians for future reference.
- **Components**:
  - Toggleable heart icons on technician profiles.
  - A dedicated "Favorites" tab within the `MainShell` bottom navigation.

### 6. Notifications (`features/notifications`)
- **Role**: Alerts users to status changes (e.g., when a request is accepted).
- **Components**:
  - App bar bell icon displaying an unread counter.
  - Notification list screen distinguishing between read and unread items.

### 7. Dashboards (`features/client_dashboard` & `features/technician_dashboard`)
- **Client Dashboard**: Overview of active requests and quick actions.
- **Technician Dashboard**: Specialized view showing incoming requests, average rating, and job completion statistics.

### 8. Admin Panel (`features/admin`)
- **Role**: Exclusive features for users with the `admin` role.
- **Components**: System statistics dashboard, user moderation tools, and category management.

### 9. Profile Settings (`features/profile`)
- **Role**: Manages user details and app preferences.
- **Components**:
  - Avatar and personal info display.
  - Settings options: Edit Profile, Notification Preferences, Change Password (via Bottom Sheet), and Logout.

## Networking Details
- **Dio Client**: Configured in `lib/core/network/dio_client.dart`.
- **Local Dev Support**: Automatically maps `10.0.2.2` to `localhost` depending on whether it's running on an Android Emulator or Web/Desktop to easily connect to the local Node.js backend.
- **Logging**: Detailed network request/response logging using `dart:developer`.
