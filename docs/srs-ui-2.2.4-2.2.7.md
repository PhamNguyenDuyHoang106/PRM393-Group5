# SRS – User Interface Specification (Module 4)

> Draft content for SRS sections **2.2.4 – 2.2.7**, written to match the existing
> UI Specification format (2.2.1 Login, 2.2.2 Register, 2.2.3 Edit Profile).
> Field labels are shown in English; the value in parentheses is the Vietnamese
> label rendered when the app language is set to Vietnamese.

---

## 2.2.4: Dashboard

The **Dashboard Screen** is the landing screen after a successful login. It gives the
user a role-based overview of their work: Managers see project-wide totals for the
projects they own, while Members see figures scoped to the tasks assigned to them.
The screen summarizes key metrics, shows an overall completion rate, and provides
quick navigation to detailed screens.

The screen provides the following functions:

- Display summary statistics (total projects, total tasks, completed tasks).
- Display the overall task completion rate as a progress bar.
- Provide quick navigation to the Project list and Task list through metric cards.
- Navigate to the detailed statistics charts (View Chart screen).
- Open the Notification Center through the bell icon, showing an unread badge.
- Refresh statistics from the backend using pull-to-refresh.
- Switch between main sections through the bottom navigation bar.

| Field Name | Description |
|---|---|
| **Notification Bell Icon** | Located on the right side of the AppBar. Displays a red badge with the number of unread notifications when push notifications are enabled and at least one notification is unread. Tapping it opens the Notification Center. |
| **Greeting Header** | Displays a personalized greeting: "Good morning, {full name}!" (Xin chào, {tên}!). |
| **Total Projects Card** (Tổng số dự án) | Displays the number of projects. For a Manager it counts owned/participating projects; for a Member it is labeled "My Projects" and counts joined projects. Tapping the card opens the Project list. |
| **Total Tasks Card** (Tổng số công việc) | Displays the total number of tasks. For a Manager it counts all tasks in managed projects; for a Member it is labeled "Tasks Assigned" and counts tasks assigned to them. Tapping the card opens the Task list. |
| **Completed Tasks Card** (Công việc hoàn thành) | Displays the number of tasks whose status is DONE. |
| **Progress Statistics Section** (Thống kê tiến độ) | A section header with a "View Charts" (Xem biểu đồ) button that navigates to the View Chart (Statistics) screen. |
| **Overall Completion Rate Bar** (Tỉ lệ hoàn thành chung) | A linear progress bar with the completion percentage (completed ÷ total). A subtitle shows "{completed} of {total} tasks completed". |
| **Pull-to-Refresh** | Pulling the content down reloads the latest statistics from the backend (falls back to local SQLite data when offline). |
| **Bottom Navigation Bar** | Fixed bar with five destinations: Dashboard, Projects, Tasks, Profile, Settings. |

**Behaviour notes**

- Statistics are re-fetched automatically after a project or task is created, updated,
  or deleted, so the counts stay in sync with the Project/Task screens.
- When offline, cached statistics from SQLite are displayed; an error state with a
  retry option is shown if no data can be loaded.

---

## 2.2.5: Setting

The **Setting Screen** allows the user to customize application preferences and manage
local data. All preference toggles are persisted in SharedPreferences and applied
immediately across the whole application.

The screen provides the following functions:

- Display a summary of the current account (avatar, name, email, role).
- Toggle between Light and Dark theme.
- Switch the application language between English and Vietnamese.
- Enable or disable push notifications.
- Enable or disable notification sounds.
- Clear the local (offline) SQLite cache.
- View the Terms & Privacy Policy.
- View application information (About).

| Field Name | Description |
|---|---|
| **User Profile Header** | A card at the top showing the user's avatar (first letter of the name), full name, email address, and a role badge (MANAGER/MEMBER). Read-only. |
| **Dark Mode Toggle** (Chế độ tối) | A switch that toggles between Light and Dark theme. The choice is saved to SharedPreferences (key `theme_mode`) and applied to the whole app. |
| **Language Toggle (EN / VI)** (Ngôn ngữ) | A segmented control that switches the interface language between English (EN) and Vietnamese (VI). The choice is saved (key `app_language`) and re-renders all localized labels instantly. |
| **Push Notifications Toggle** (Thông báo đẩy) | A switch that enables/disables task-deadline and activity alerts. Saved to SharedPreferences (key `push_notifications_enabled`). When disabled, the unread badge on the Dashboard bell is hidden. |
| **Notification Sounds Toggle** (Âm thanh thông báo) | A switch that enables/disables the sound played on new alerts. Saved (key `notification_sound_enabled`). |
| **Clear Local Cache** (Xoá bộ nhớ đệm) | Opens a confirmation dialog. On confirmation, it wipes offline SQLite data (cached notifications and the pending-sync queue). Server data is not affected. A success message is shown afterwards. |
| **Terms & Privacy Policy** (Điều khoản & Chính sách bảo mật) | Opens a dialog describing the Terms of Use, Data Privacy, and Policy Updates. |
| **About Application** (Về ứng dụng) | Opens a dialog showing the application name, version (v1.0.0 – PRM393 MVP), and a short description. |

---

## 2.2.6: Notification

The **Notification Screen** (Notification Center) lists the history of system
notifications delivered to the current user. Notifications are generated by the
backend for project and task events and are stored per user. The screen lets the user
review, filter, read, and remove notifications.

The screen provides the following functions:

- Display the list of notifications in reverse chronological order.
- Filter notifications by All, Unread, or Read.
- Mark all notifications as read.
- Open a notification to view its full detail (which also marks it as read).
- Delete a notification by swiping it away.
- Refresh the list using pull-to-refresh.

| Field Name | Description |
|---|---|
| **Mark All As Read Button** (Đánh dấu đã đọc tất cả) | Shown on the AppBar only when there is at least one unread notification. Marks every notification as read. |
| **Filter Chips** | Three chips: All (Tất cả), Unread (Chưa đọc – shows the unread count), and Read (Đã đọc). Selecting a chip filters the list accordingly. |
| **Notification Item** | A list row with a leading icon (highlighted for unread, muted for read), a title (bold when unread), the message body, and a relative timestamp ("Just now", "{n} minutes ago", "{n} hours ago", or a date). Tapping the row marks it read and opens the detail dialog. |
| **Swipe-to-Delete** | Swiping a notification from right to left removes it; a "Notification deleted" snackbar confirms the action. |
| **Notification Detail Dialog** | Displays the notification title, full message, the time it was received, and a Close button. |
| **Empty State** | When no notifications match the current filter, an icon and the message "No notifications found" (Không có thông báo nào) are shown. |

### Notification Types

The system displays the following notification types (generated by the NestJS backend
when the corresponding event occurs):

| Type | Title | Trigger | Recipient |
|---|---|---|---|
| `PROJECT_CREATED` | Project Created | A Manager creates a new project | Project owner (Manager) |
| `PROJECT_CREATED` | Added to Project | A user is added as a member of a project | The newly added member |
| `TASK_ASSIGNED` | Task Assigned | A task is created and assigned, or an existing task is reassigned to a different member | The assignee (Member) |
| `TASK_UPDATED` | Task Completed | An assigned task's status is changed to DONE | The project owner (Manager) |

---

## 2.2.7: View Chart

The **View Chart Screen** (Statistics) visualizes task distribution for the user's
projects using charts rendered with the `fl_chart` library. It helps Managers monitor
progress and identify workload distribution by status and by priority.

The screen provides the following functions:

- Display the task status distribution as a pie/donut chart.
- Display the task priority distribution as a bar chart.
- Switch the breakdown between task status and task priority.
- Filter the statistics by time range (All Time, This Week, This Month).
- Display a detailed list showing the count and percentage of each category.
- Export the statistics as a report.
- Retry loading when data is unavailable.

| Field Name | Description |
|---|---|
| **Export Statistics Button** (Xuất thống kê) | An action on the AppBar (share icon) that generates a CSV report of the current statistics. A loading indicator is shown while generating, followed by a success message. |
| **Time Filter** | A segmented control with three options: All (Tất cả), Week (Tuần), Month (Tháng). Changing the selection reloads the statistics for the chosen range. |
| **Status / Priority Toggle** | A segmented control: "By Status" (Theo trạng thái) and "By Priority" (Theo độ ưu tiên). It switches which distribution the chart and details list represent. |
| **Status Pie Chart** | Shown when "By Status" is selected. A donut chart whose sections represent TODO, IN_PROGRESS, and DONE with their percentages. Colors: TODO = blue, IN_PROGRESS = orange, DONE = green. |
| **Priority Bar Chart** | Shown when "By Priority" is selected. A vertical bar chart with one bar per priority level (LOW, MEDIUM, HIGH) whose height represents the task count; the category label is shown below each bar. Colors: LOW = grey, MEDIUM = indigo, HIGH = red. |
| **Legend** | Below the chart: a colored dot for each category together with its localized name and count, e.g. "Cần làm (1)", "Đang làm (1)", "Hoàn thành (3)". |
| **Details List** | One row per category with a colored dot, the category name, the number of tasks ("{n} tasks"), and its percentage of the total. |
| **Empty State** | When there is no data, "No statistics data available" (Không có dữ liệu thống kê) is shown with a Retry button. When the total for the selected breakdown is 0, "No tasks found" is displayed inside the chart area. |

**Behaviour notes**

- The chart shares its data source with the Dashboard, so it reflects the latest task
  changes; the time filter re-queries the statistics endpoint.
- Category labels (TODO/IN_PROGRESS/DONE, LOW/MEDIUM/HIGH) are shown translated when
  the app language is Vietnamese.
