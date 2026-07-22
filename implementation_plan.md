# Smart Task Management - Project Implementation Specification (MVP)

This document represents the finalized, scope-controlled **Project Implementation Specification** for the **Smart Task Management** group project. It is optimized to meet all PRM393 syllabus grading criteria with zero scope creep.

---

## User Review Required

> [!IMPORTANT]
> - **Scope Control:** Non-essential features (e.g. Chat, Comments, File upload, Calendar, Kanban, AI, Realtime collaboration) are strictly excluded.
> - **Deliverables Matrix:** Development is mapped directly to 4 core modules (16 screens total) with clear owners, shared components, database schemas, and offline synchronization rules.

---

## 1. Project Scope & Architecture

The application will implement the following MVP layers:

```text
       UI Layer (Shared Widgets & Common library)
                         ↓
         View Layer (16 Screens: 4 per member)
                         ↓
             ViewModel Layer (Riverpod States)
                         ↓
                 Repository Layer
                         ↓
                   Data Sources
             ┌───────────┴───────────┐
             ↓                       ↓
         REST API Cache            SQLite
        (Dio Networking)      (Offline Storage)
```

---

## 2. RACI Ownership Matrix

| Core Area | Component | Owner | Deliverables |
|---|---|---|---|
| **Module 1** | **Authentication** | Member 1 | - Screens: Login, Register, Forgot Password, Profile<br>- Code: `user.dart`, `auth_repository.dart`, `auth_viewmodel.dart`, `auth_provider.dart`<br>- Integration: Firebase Auth |
| **Module 2** | **Project Management** | Member 2 | - Screens: Project List, Create Project, Project Detail, Member Management<br>- Code: `project.dart`, `project_repository.dart`, `project_viewmodel.dart`, `project_provider.dart` |
| **Module 3** | **Task Management** | Member 3 | - Screens: Task List, Create Task, Task Detail, Edit Task<br>- Code: `task.dart`, `task_repository.dart`, `task_viewmodel.dart`, `task_provider.dart`<br>- Shared Services: SQLite database helper, Connectivity status, Sync service |
| **Module 4** | **Dashboard & Settings** | Member 4 | - Screens: Dashboard, Statistics (Pie Chart), Notification Center, Settings<br>- Code: `notification.dart`, `statistics.dart`, `notification_repository.dart`, `notification_viewmodel.dart`<br>- Integration: Firebase Cloud Messaging (FCM), SharedPreferences theme toggle |
| **Shared Core** | **Scaffolding** | Team Leader | - Code: `main.dart`, `app.dart`, `go_router.dart`, `dio_client.dart`<br>- Shared widgets layout configuration |

---

## 3. Module Specifications & API Connections

### Module 1: Authentication (Member 1)
* **Screen 1: Login** - Email, password inputs, form validations, "Remember Me" session caching. API: `POST /auth/login`.
* **Screen 2: Register** - Username, email, password, password confirmation form. API: `POST /auth/register`.
* **Screen 3: Forgot Password** - Initiate password recovery email. API: `POST /auth/reset-password`.
* **Screen 4: Profile** - View current profile information, sign out. API: `GET /users/profile`.

### Module 2: Project Management (Member 2)
* **Screen 1: Project List** - View associated projects. API: `GET /projects`.
* **Screen 2: Create Project** - Manager interface to create new projects. API: `POST /projects`.
* **Screen 3: Project Detail** - Detailed metadata overview. API: `GET /projects/{id}`.
* **Screen 4: Member Management** - Manager interface to link/unlink members. API: `POST /projects/add-member`, `DELETE /projects/remove-member`.

### Module 3: Task Management (Member 3)
* **Screen 1: Task List** - View associated tasks. Search filters & status filters. API: `GET /tasks`.
* **Screen 2: Create Task** - Manager interface to define task name, assign member, select priority (Low/Medium/High), due date. API: `POST /tasks`.
* **Screen 3: Task Detail** - Detailed task metadata. API: `GET /tasks/{id}`.
* **Screen 4: Edit Task** - Modify title/description (Manager only) or update status (Member & Manager). API: `PUT /tasks/{id}`.

### Module 4: Dashboard & Notifications (Member 4)
* **Screen 1: Dashboard** - Displays total projects count, total tasks count, completed tasks count. API: `GET /statistics`.
* **Screen 2: Statistics** - Renders a Task Status Distribution Pie Chart (`fl_chart`). API: `GET /statistics`.
* **Screen 3: Notification Center** - Lists background notifications history. API: `GET /notifications`.
* **Screen 4: Settings** - Toggle Dark Mode (persisted in SharedPreferences) & toggle notifications.

---

## 4. SQLite Schema Definitions
We will maintain 6 local database tables:
1. `users` (id TEXT PRIMARY KEY, name TEXT, email TEXT, role TEXT, created_at TEXT)
2. `projects` (id TEXT PRIMARY KEY, name TEXT, description TEXT, owner_id TEXT, created_at TEXT)
3. `project_members` (project_id TEXT, user_id TEXT, PRIMARY KEY (project_id, user_id))
4. `tasks` (id TEXT PRIMARY KEY, project_id TEXT, title TEXT, description TEXT, priority TEXT, status TEXT, assigned_to TEXT, due_date TEXT, created_at TEXT)
5. `notifications` (id TEXT PRIMARY KEY, user_id TEXT, title TEXT, message TEXT, read_status INTEGER, created_at TEXT)
6. `pending_actions` (id TEXT PRIMARY KEY, action_type TEXT, payload TEXT, created_at TEXT)

---

## 5. Offline Flow & Sync Strategy
* **Online Mode:** Repositories call the REST API client. Upon receiving data, it updates the corresponding SQLite database table, then triggers UI state rebuilds.
* **Offline Mode:** Connectivity listener detects failure. Repositories read directly from SQLite tables to populate the UI. Write operations store details in SQLite tables and append a queue item to the `pending_actions` table.
* **Sync Mode:** Once connectivity is restored, the `SyncService` reads `pending_actions` chronologically, sends the requests to the backend, and drops successfully synced queue items.

---

## 6. Shared Reusable Widget Library
We will maintain standard UI elements under `lib/widgets/`:
* `CustomButton` (Standardized colors, styles, loading indicators)
* `CustomTextField` (Inputs with validation styling)
* `TaskCard` (Item listing preview)
* `ProjectCard` (Item listing preview)
* `DashboardCard` (Metrics stats box)
* `LoadingWidget` (Center spinner overlay)
* `EmptyWidget` (Zero search / zero list states placeholder)
* `ErrorWidget` (Standard fail visualizer)

---

## 7. Acceptance Criteria

- [ ] **Authentication:** Login, signup, and logout operate successfully with token caching.
- [ ] **Project Management:** Project list rendering, CRUD, and membership modifications function correctly.
- [ ] **Task Management:** Search operations, priority tags, status updates, and assignment maps function correctly.
- [ ] **Dashboard:** Correct counts displayed, and `fl_chart` Pie Chart loads correctly.
- [ ] **SQLite Offline:** App runs and queries cached data when connectivity is severed. Syncing begins automatically upon reconnection.
- [ ] **Riverpod & MVVM:** State classes are separate from Views. Repositories manage data calls.
- [ ] **LOC:** Each member exceeds `360 LOC` (total project 1500-2000+ LOC).
