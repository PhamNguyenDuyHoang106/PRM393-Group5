# REST API Contract Specification

This document details the REST API endpoints, parameters, request body payloads, and response formats to enable parallel backend (Spring Boot/Express) and client (Flutter) development.

---

## 1. Global JSON Envelope

All APIs communicate via JSON payloads. Errors are returned using a consistent error schema:

### Error Envelope (HTTP Status `400`, `401`, `403`, `404`, `500`)
```json
{
  "timestamp": "2026-06-30T00:26:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid email address format.",
  "path": "/api/v1/auth/login"
}
```

---

## 2. Authentication APIs

### 2.1 Login
* **Method & Path:** `POST /api/v1/auth/login`
* **Request Body:**
```json
{
  "email": "manager@example.com",
  "password": "SecurePassword123"
}
```
* **Success Response (HTTP `200 OK`):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "usr_7719",
    "name": "Hoang Manager",
    "email": "manager@example.com",
    "role": "Manager",
    "created_at": "2026-06-30T00:15:00Z"
  }
}
```

---

### 2.2 Register
* **Method & Path:** `POST /api/v1/auth/register`
* **Request Body:**
```json
{
  "name": "Nguyen Van B",
  "email": "member@example.com",
  "password": "SecurePassword456",
  "role": "Member"
}
```
* **Success Response (HTTP `201 Created`):**
```json
{
  "id": "usr_8231",
  "name": "Nguyen Van B",
  "email": "member@example.com",
  "role": "Member",
  "created_at": "2026-06-30T00:26:00Z"
}
```

---

### 2.3 Forgot Password
* **Method & Path:** `POST /api/v1/auth/reset-password`
* **Request Body:**
```json
{
  "email": "member@example.com"
}
```
* **Success Response (HTTP `200 OK`):**
```json
{
  "message": "Password reset email link sent successfully."
}
```

---

### 2.4 Profile Details
* **Method & Path:** `GET /api/v1/users/profile`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
{
  "id": "usr_8231",
  "name": "Nguyen Van B",
  "email": "member@example.com",
  "role": "Member",
  "created_at": "2026-06-30T00:26:00Z"
}
```

---

## 3. Project Management APIs

### 3.1 Get Projects List (Assigned to calling user)
* **Method & Path:** `GET /api/v1/projects`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
[
  {
    "id": "proj_01",
    "name": "Smart Task Management MVP",
    "description": "Flutter MVVM group assignment",
    "owner_id": "usr_7719",
    "created_at": "2026-06-30T00:15:00Z"
  }
]
```

---

### 3.2 Create Project
* **Method & Path:** `POST /api/v1/projects`
* **Headers:** `Authorization: Bearer <token>` (User must be `Manager`)
* **Request Body:**
```json
{
  "name": "PRM393 Development Team",
  "description": "Scaffolding the repositories and caching."
}
```
* **Success Response (HTTP `201 Created`):**
```json
{
  "id": "proj_02",
  "name": "PRM393 Development Team",
  "description": "Scaffolding the repositories and caching.",
  "owner_id": "usr_7719",
  "created_at": "2026-06-30T00:26:00Z"
}
```

---

### 3.3 Get Project Detail
* **Method & Path:** `GET /api/v1/projects/{id}`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
{
  "id": "proj_01",
  "name": "Smart Task Management MVP",
  "description": "Flutter MVVM group assignment",
  "owner_id": "usr_7719",
  "created_at": "2026-06-30T00:15:00Z",
  "members": [
    {
      "id": "usr_7719",
      "name": "Hoang Manager",
      "email": "manager@example.com",
      "role": "Manager"
    },
    {
      "id": "usr_8231",
      "name": "Nguyen Van B",
      "email": "member@example.com",
      "role": "Member"
    }
  ]
}
```

---

### 3.4 Add Member to Project
* **Method & Path:** `POST /api/v1/projects/add-member`
* **Headers:** `Authorization: Bearer <token>` (User must be `Manager`)
* **Request Body:**
```json
{
  "project_id": "proj_01",
  "user_email": "member@example.com"
}
```
* **Success Response (HTTP `200 OK`):**
```json
{
  "message": "User member@example.com added to project successfully."
}
```

---

### 3.5 Remove Member from Project
* **Method & Path:** `DELETE /api/v1/projects/remove-member`
* **Headers:** `Authorization: Bearer <token>` (User must be `Manager`)
* **Request Body:**
```json
{
  "project_id": "proj_01",
  "user_id": "usr_8231"
}
```
* **Success Response (HTTP `200 OK`):**
```json
{
  "message": "Member removed from project successfully."
}
```

---

## 4. Task Management APIs

### 4.1 Get Tasks List
* **Method & Path:** `GET /api/v1/tasks`
* **Headers:** `Authorization: Bearer <token>`
* **Query Parameters:**
  * `project_id` (optional, filter by project)
  * `search` (optional, query string search)
  * `status` (optional, `'TODO'`, `'IN_PROGRESS'`, `'DONE'`)
* **Success Response (HTTP `200 OK`):**
```json
[
  {
    "id": "task_550",
    "project_id": "proj_01",
    "title": "Design Database Schema",
    "description": "Define sqlite tables and columns",
    "priority": "HIGH",
    "status": "TODO",
    "assigned_to": "usr_8231",
    "due_date": "2026-07-15T18:00:00Z",
    "created_at": "2026-06-30T00:15:00Z"
  }
]
```

---

### 4.2 Create Task
* **Method & Path:** `POST /api/v1/tasks`
* **Headers:** `Authorization: Bearer <token>` (User must be `Manager`)
* **Request Body:**
```json
{
  "project_id": "proj_01",
  "title": "Integrate Dio Client",
  "description": "Configure HTTP interceptors and headers.",
  "priority": "MEDIUM",
  "assigned_to": "usr_8231",
  "due_date": "2026-07-20T18:00:00Z"
}
```
* **Success Response (HTTP `201 Created`):**
```json
{
  "id": "task_551",
  "project_id": "proj_01",
  "title": "Integrate Dio Client",
  "description": "Configure HTTP interceptors and headers.",
  "priority": "MEDIUM",
  "status": "TODO",
  "assigned_to": "usr_8231",
  "due_date": "2026-07-20T18:00:00Z",
  "created_at": "2026-06-30T00:26:00Z"
}
```

---

### 4.3 Get Task Detail
* **Method & Path:** `GET /api/v1/tasks/{id}`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
{
  "id": "task_550",
  "project_id": "proj_01",
  "title": "Design Database Schema",
  "description": "Define sqlite tables and columns",
  "priority": "HIGH",
  "status": "TODO",
  "assigned_to": "usr_8231",
  "due_date": "2026-07-15T18:00:00Z",
  "created_at": "2026-06-30T00:15:00Z"
}
```

---

### 4.4 Update Task (Edit or Change Status)
* **Method & Path:** `PUT /api/v1/tasks/{id}`
* **Headers:** `Authorization: Bearer <token>`
* **Request Body:**
```json
{
  "title": "Design Database Schema & Seed Data",
  "description": "Define sqlite tables and write mock seeds.",
  "priority": "HIGH",
  "status": "IN_PROGRESS",
  "assigned_to": "usr_8231",
  "due_date": "2026-07-16T18:00:00Z"
}
```
* **Success Response (HTTP `200 OK`):**
```json
{
  "id": "task_550",
  "project_id": "proj_01",
  "title": "Design Database Schema & Seed Data",
  "description": "Define sqlite tables and write mock seeds.",
  "priority": "HIGH",
  "status": "IN_PROGRESS",
  "assigned_to": "usr_8231",
  "due_date": "2026-07-16T18:00:00Z",
  "created_at": "2026-06-30T00:15:00Z"
}
```

---

## 5. Dashboard & Notifications APIs

### 5.1 Statistics Summary
* **Method & Path:** `GET /api/v1/statistics`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
{
  "total_projects": 3,
  "total_tasks": 24,
  "completed_tasks": 12,
  "pending_tasks": 10,
  "overdue_tasks": 2,
  "task_status_distribution": {
    "TODO": 8,
    "IN_PROGRESS": 4,
    "DONE": 12
  },
  "task_priority_distribution": {
    "LOW": 10,
    "MEDIUM": 8,
    "HIGH": 6
  }
}
```

---

### 5.2 Get Notifications List
* **Method & Path:** `GET /api/v1/notifications`
* **Headers:** `Authorization: Bearer <token>`
* **Success Response (HTTP `200 OK`):**
```json
[
  {
    "id": "notif_001",
    "user_id": "usr_8231",
    "title": "New Task Assigned",
    "message": "You have been assigned to 'Integrate Dio Client'",
    "read_status": 0,
    "created_at": "2026-06-30T00:26:00Z"
  }
]
```
