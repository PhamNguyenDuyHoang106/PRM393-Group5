/// Bảng chuỗi song ngữ (Anh/Việt) cho Module 4 — Dashboard & Settings.
///
/// Đây là giải pháp i18n gọn nhẹ (không dùng flutter_localizations/.arb):
/// mỗi màn hình đọc `AppStrings(isVietnamese)` từ `SettingsState.isVietnamese`
/// (đã lưu persistent qua SharedPreferences) rồi lấy chuỗi theo getter tương ứng.
///
/// Khi các module khác (1/2/3) cần đa ngôn ngữ, có thể mở rộng thêm getter
/// vào đúng class này để giữ một nguồn chuỗi duy nhất cho toàn app.
class AppStrings {
  const AppStrings(this.isVietnamese);

  final bool isVietnamese;

  String _t(String en, String vi) => isVietnamese ? vi : en;

  // ─── Dashboard (Manager & Member) ─────────────────────────────────────
  String get managerDashboardTitle => _t('Smart Task Dashboard', 'Bảng điều khiển');
  String get memberHomeTitle => _t('Smart Task Home', 'Trang chủ');
  String greeting(String name) => _t('Good morning, $name!', 'Xin chào, $name!');
  String get totalProjects => _t('Total Projects', 'Tổng số dự án');
  String get myProjects => _t('My Projects', 'Dự án của tôi');
  String get totalTasks => _t('Total Tasks', 'Tổng số công việc');
  String get tasksAssigned => _t('Tasks Assigned', 'Công việc được giao');
  String get completedTasks => _t('Completed Tasks', 'Công việc hoàn thành');
  String get progressStatistics => _t('Progress Statistics', 'Thống kê tiến độ');
  String get viewCharts => _t('View Charts', 'Xem biểu đồ');
  String get overallCompletionRate => _t('Overall Completion Rate', 'Tỉ lệ hoàn thành chung');
  String tasksCompletedOf(int completed, int total) =>
      _t('$completed of $total tasks completed', '$completed/$total công việc đã hoàn thành');
  String get unableToLoadData => _t('Unable to load your data', 'Không thể tải dữ liệu');
  String get inProgressTasksLabel => _t('In Progress', 'Đang làm');
  String get overdueTasksLabel => _t('Overdue', 'Trễ hạn');
  String get tasksByMember => _t('Tasks by Member', 'Công việc theo thành viên');
  String get overdueTasksSection => _t('Overdue Tasks', 'Công việc trễ hạn');
  String get tasksDueSoon => _t('Tasks Due Soon (Next 3 Days)', 'Sắp đến hạn (3 ngày tới)');
  String get myOverdueTasks => _t('My Overdue Tasks', 'Công việc trễ hạn của tôi');
  String get myUpcomingTasks => _t('My Upcoming Tasks', 'Công việc sắp đến hạn của tôi');
  String dueLabel(String date) => _t('Due: $date', 'Hạn: $date');

  // ─── Statistics ────────────────────────────────────────────────────────
  String get taskStatisticsTitle => _t('Task Statistics', 'Thống kê công việc');
  String get exportStatistics => _t('Export Statistics', 'Xuất thống kê');
  String get exportingReport => _t('Exporting report...', 'Đang xuất báo cáo...');
  String get exportSuccess =>
      _t('Statistics report exported successfully as CSV!', 'Đã xuất báo cáo CSV thành công!');
  String get exportFailed => _t('Could not export the report.', 'Không thể xuất báo cáo.');
  String get csvReportTitle => _t('Task Statistics Report', 'Báo cáo thống kê công việc');
  String generatedOnLabel(String date) => _t('Generated: $date', 'Xuất lúc: $date');
  String get columnCount => _t('Count', 'Số lượng');
  String get columnPercentage => _t('Percentage', 'Phần trăm');
  String get noStatisticsData => _t('No statistics data available', 'Không có dữ liệu thống kê');
  String get retry => _t('Retry', 'Thử lại');
  String get filterAll => _t('All', 'Tất cả');
  String get filterWeek => _t('Week', 'Tuần');
  String get filterMonth => _t('Month', 'Tháng');
  String get byStatus => _t('By Status', 'Theo trạng thái');
  String get byPriority => _t('By Priority', 'Theo độ ưu tiên');
  String get statusDistribution => _t('Status Distribution', 'Phân bố trạng thái');
  String get priorityDistribution => _t('Priority Distribution', 'Phân bố độ ưu tiên');
  String get noTasksFound => _t('No tasks found', 'Không tìm thấy công việc');
  String taskCount(int count) => _t('$count tasks', '$count công việc');

  /// Nhãn hiển thị cho các category trạng thái/độ ưu tiên trả về từ backend
  /// (TODO/IN_PROGRESS/DONE, LOW/MEDIUM/HIGH). Giữ nguyên khoá gốc nếu không khớp.
  String categoryLabel(String key) {
    if (!isVietnamese) return key;
    switch (key.toUpperCase()) {
      case 'TODO':
        return 'Cần làm';
      case 'IN_PROGRESS':
        return 'Đang làm';
      case 'DONE':
        return 'Hoàn thành';
      case 'LOW':
        return 'Thấp';
      case 'MEDIUM':
        return 'Trung bình';
      case 'HIGH':
        return 'Cao';
      default:
        return key;
    }
  }

  // ─── Notification Center ──────────────────────────────────────────────
  String get notificationsTitle => _t('Notifications', 'Thông báo');
  String get markAllAsRead => _t('Mark all as read', 'Đánh dấu đã đọc tất cả');
  String get filterUnread => _t('Unread', 'Chưa đọc');
  String get filterRead => _t('Read', 'Đã đọc');
  String get noNotificationsFound => _t('No notifications found', 'Không có thông báo nào');
  String get notificationDeleted => _t('Notification deleted', 'Đã xoá thông báo');
  String get close => _t('Close', 'Đóng');
  String receivedAt(String time) => _t('Received: $time', 'Nhận lúc: $time');
  String get justNow => _t('Just now', 'Vừa xong');
  String minutesAgo(int minutes) => _t('$minutes minutes ago', '$minutes phút trước');
  String hoursAgo(int hours) => _t('$hours hours ago', '$hours giờ trước');

  // ─── Settings ──────────────────────────────────────────────────────────
  String get settingsTitle => _t('Settings', 'Cài đặt');
  String get sectionPreferences => _t('PREFERENCES', 'TÙY CHỈNH');
  String get darkMode => _t('Dark Mode', 'Chế độ tối');
  String get darkModeSubtitle => _t('Adjust application color theme', 'Điều chỉnh giao diện màu ứng dụng');
  String get language => _t('Language', 'Ngôn ngữ');
  String get languageSubtitle => _t('Switch between English and Vietnamese', 'Chuyển đổi giữa Tiếng Anh và Tiếng Việt');
  String get sectionNotifications => _t('NOTIFICATIONS', 'THÔNG BÁO');
  String get pushNotifications => _t('Push Notifications', 'Thông báo đẩy');
  String get pushNotificationsSubtitle =>
      _t('Receive warnings for task deadlines', 'Nhận cảnh báo hạn công việc');
  String get notificationSounds => _t('Notification Sounds', 'Âm thanh thông báo');
  String get notificationSoundsSubtitle =>
      _t('Play sound on new alerts', 'Phát âm thanh khi có thông báo mới');
  String get sectionSystemData => _t('SYSTEM & DATA', 'HỆ THỐNG & DỮ LIỆU');
  String get clearLocalCache => _t('Clear Local Cache', 'Xoá bộ nhớ đệm');
  String get clearLocalCacheSubtitle =>
      _t('Wipe offline SQLite database data', 'Xoá dữ liệu SQLite ngoại tuyến');
  String get termsAndPrivacy => _t('Terms & Privacy Policy', 'Điều khoản & Chính sách bảo mật');
  String get termsAndPrivacySubtitle =>
      _t('Read terms of service and privacy rules', 'Đọc điều khoản dịch vụ và quy định bảo mật');
  String get aboutApp => _t('About Application', 'Về ứng dụng');
  String get aboutAppSubtitle =>
      _t('Smart Task Management v1.0.0 (PRM393 MVP)', 'Smart Task Management v1.0.0 (PRM393 MVP)');
  String get wipeCacheTitle => _t('Wipe Local Cache?', 'Xoá bộ nhớ đệm cục bộ?');
  String get wipeCacheContent => _t(
        'This action will delete all offline cached database tables (notifications, pending sync queues). Server data remains untouched.',
        'Thao tác này sẽ xoá toàn bộ dữ liệu cache ngoại tuyến (thông báo, hàng đợi đồng bộ). Dữ liệu trên máy chủ không bị ảnh hưởng.',
      );
  String get cancel => _t('Cancel', 'Huỷ');
  String get clearCache => _t('Clear Cache', 'Xoá cache');
  String get cacheClearedSuccess =>
      _t('SQLite cache has been cleared successfully!', 'Đã xoá bộ nhớ đệm SQLite thành công!');
  String get termsTitle => _t('Terms & Privacy Policy', 'Điều khoản & Chính sách bảo mật');
  String get termsSection1Title => _t('1. Terms of Use', '1. Điều khoản sử dụng');
  String get termsSection1Body => _t(
        'By using the Smart Task Management application, you agree to comply with our policies and rules regarding task and project data.',
        'Khi sử dụng ứng dụng Smart Task Management, bạn đồng ý tuân thủ các chính sách và quy định về dữ liệu công việc và dự án.',
      );
  String get termsSection2Title => _t('2. Data Privacy', '2. Quyền riêng tư dữ liệu');
  String get termsSection2Body => _t(
        'Your task data is stored securely in your offline SQLite database and is only synchronized when you connect to our authorized network services.',
        'Dữ liệu công việc của bạn được lưu trữ an toàn trong SQLite ngoại tuyến và chỉ đồng bộ khi bạn kết nối tới dịch vụ mạng được uỷ quyền.',
      );
  String get termsSection3Title => _t('3. Policy Updates', '3. Cập nhật chính sách');
  String get termsSection3Body => _t(
        'We reserve the right to modify these terms. Continued usage of the application implies consent to all revisions.',
        'Chúng tôi có quyền thay đổi các điều khoản này. Việc tiếp tục sử dụng ứng dụng đồng nghĩa với việc bạn chấp nhận mọi thay đổi.',
      );
  String get agreeAndClose => _t('Agree & Close', 'Đồng ý & Đóng');
  String get aboutTitle => _t('About Application', 'Về ứng dụng');
  String get aboutAppName => _t('Smart Task Management', 'Smart Task Management');
  String get aboutVersion => _t('Version 1.0.0 (PRM393 MVP)', 'Phiên bản 1.0.0 (PRM393 MVP)');
  String get aboutDescription => _t(
        'This application is built for the PRM393 course project to provide offline-first task tracking, statistics visualization, and sync capabilities.',
        'Ứng dụng được xây dựng cho đồ án môn PRM393, cung cấp khả năng quản lý công việc ưu tiên ngoại tuyến, trực quan hoá thống kê và đồng bộ dữ liệu.',
      );

  // ─── Shared / generic ──────────────────────────────────────────────────
  String get delete => _t('Delete', 'Xoá');
  String get remove => _t('Remove', 'Xoá');
  String get reset => _t('Reset', 'Đặt lại');
  String get dismiss => _t('Dismiss', 'Đóng');
  String get save => _t('Save', 'Lưu');
  String get keepEditing => _t('Keep editing', 'Tiếp tục chỉnh sửa');
  String get discard => _t('Discard', 'Huỷ bỏ');
  String get accessDenied => _t('Access denied', 'Không có quyền truy cập');
  String get checkingPermissions => _t('Checking permissions...', 'Đang kiểm tra quyền...');
  String get clearSearch => _t('Clear search', 'Xoá tìm kiếm');
  String get statusLabel => _t('Status', 'Trạng thái');
  String get priorityLabel => _t('Priority', 'Độ ưu tiên');
  String get descriptionLabel => _t('Description', 'Mô tả');
  String get dueDateLabel => _t('Due Date', 'Hạn chót');
  String get noDueDate => _t('No due date', 'Không có hạn chót');
  String get createdLabel => _t('Created', 'Ngày tạo');
  String get unassigned => _t('Unassigned', 'Chưa giao');
  String get noDescriptionProvided => _t('No description provided.', 'Chưa có mô tả.');
  String get noDeadline => _t('No deadline', 'Không có hạn chót');
  String get edit => _t('Edit', 'Sửa');
  String get projectActionsTooltip => _t('Project actions', 'Tùy chọn dự án');
  String createdOnLabel(String date) => _t('Created on: $date', 'Tạo ngày: $date');

  // ─── Bottom navigation bar ─────────────────────────────────────────────
  String get navDashboard => _t('Dashboard', 'Tổng quan');
  String get navProjects => _t('Projects', 'Dự án');
  String get navTasks => _t('Tasks', 'Công việc');
  String get navProfile => _t('Profile', 'Hồ sơ');
  String get navSettings => _t('Settings', 'Cài đặt');

  // ─── Profile ───────────────────────────────────────────────────────────
  String get userProfileTitle => _t('User Profile', 'Hồ sơ người dùng');
  String get editProfile => _t('Edit Profile', 'Chỉnh sửa hồ sơ');
  String get profileInformation => _t('Profile Information', 'Thông tin hồ sơ');
  String get profileSaveSuccess => _t('Profile saved successfully!', 'Đã lưu hồ sơ thành công!');
  String failedToPickImage(String error) => _t('Failed to pick image: $error', 'Không thể chọn ảnh: $error');
  String get fullNameLabel => _t('Full Name', 'Họ và tên');
  String get enterYourName => _t('Enter your name', 'Nhập tên của bạn');
  String get nameRequired => _t('Name is required', 'Vui lòng nhập tên');
  String get changePassword => _t('Change Password', 'Đổi mật khẩu');
  String get currentPasswordLabel => _t('Current Password', 'Mật khẩu hiện tại');
  String get currentPasswordHint => _t('Required to confirm changes', 'Cần để xác nhận thay đổi');
  String get currentPasswordRequired =>
      _t('Current password is required to change password', 'Cần nhập mật khẩu hiện tại để đổi mật khẩu');
  String get newPasswordLabel => _t('New Password', 'Mật khẩu mới');
  String get newPasswordHint => _t('Enter new password', 'Nhập mật khẩu mới');
  String get passwordMinLength => _t('Password must be at least 6 characters', 'Mật khẩu phải có ít nhất 6 ký tự');
  String get nameFieldLabel => _t('Name', 'Tên');
  String get emailFieldLabel => _t('Email', 'Email');
  String get roleFieldLabel => _t('Role', 'Vai trò');
  String get notSet => _t('Not set', 'Chưa đặt');
  String get anonymousUser => _t('Anonymous User', 'Người dùng ẩn danh');
  String get noEmailAssociated => _t('No email associated', 'Chưa có email');
  String get saveChanges => _t('Save Changes', 'Lưu thay đổi');
  String get logout => _t('Logout', 'Đăng xuất');

  // ─── Project List ──────────────────────────────────────────────────────
  String get managedProjects => _t('Managed Projects', 'Dự án quản lý');
  String get refreshProjectsTooltip => _t('Refresh projects', 'Làm mới danh sách dự án');
  String get newProject => _t('New project', 'Dự án mới');
  String get loadingProjects => _t('Loading projects...', 'Đang tải dự án...');
  String get unableToLoadProjects => _t('Unable to load projects', 'Không thể tải dự án');
  String get searchProjects => _t('Search projects', 'Tìm kiếm dự án');
  String get projectsYouManage => _t('Projects you manage', 'Dự án bạn quản lý');
  String get projectsYouParticipateIn => _t('Projects you participate in', 'Dự án bạn tham gia');
  String projectCountLabel(int count) =>
      _t('$count ${count == 1 ? 'project' : 'projects'}', '$count dự án');
  String get noProjectsYet => _t('No projects yet', 'Chưa có dự án nào');
  String get noMatchingProjects => _t('No matching projects', 'Không tìm thấy dự án phù hợp');
  String get createProjectToStart => _t('Create a project to get started.', 'Tạo một dự án để bắt đầu.');
  String get projectsAssignedWillAppear =>
      _t('Projects assigned to you will appear here.', 'Các dự án được giao cho bạn sẽ hiện ở đây.');
  String get tryChangingSearchOrSort =>
      _t('Try changing your search or sorting option.', 'Thử thay đổi tìm kiếm hoặc cách sắp xếp.');
  String get deleteProjectQuestion => _t('Delete project?', 'Xoá dự án?');
  String deleteProjectConfirm(String name) => _t(
        '"$name" and its cached tasks will be removed. This action cannot be undone.',
        '"$name" và các công việc đã lưu sẽ bị xoá. Hành động này không thể hoàn tác.',
      );
  String projectDeletedMsg(String name) => _t('"$name" deleted.', 'Đã xoá "$name".');
  String get sortProjectsTooltip => _t('Sort projects', 'Sắp xếp dự án');
  String get sortNewestFirst => _t('Newest first', 'Mới nhất trước');
  String get sortOldestFirst => _t('Oldest first', 'Cũ nhất trước');
  String get sortNameAZ => _t('Name A–Z', 'Tên A–Z');
  String get sortNameZA => _t('Name Z–A', 'Tên Z–A');

  // ─── Create Project ────────────────────────────────────────────────────
  String get createProjectTitle => _t('Create Project', 'Tạo dự án');
  String get projectInformation => _t('Project information', 'Thông tin dự án');
  String get projectInfoSubtitle =>
      _t('Use a concise name and explain the project goal.', 'Dùng tên ngắn gọn và mô tả rõ mục tiêu dự án.');
  String get projectNameLabel => _t('Project name', 'Tên dự án');
  String get projectNameHint => _t('e.g. Mobile App Redesign', 'VD: Thiết kế lại ứng dụng di động');
  String get projectNameRequired => _t('Project name is required', 'Vui lòng nhập tên dự án');
  String get projectNameMinLength =>
      _t('Project name must be at least 3 characters', 'Tên dự án phải có ít nhất 3 ký tự');
  String get projectNameMaxLength =>
      _t('Project name must not exceed 100 characters', 'Tên dự án không được vượt quá 100 ký tự');
  String get describeProjectHint =>
      _t('Describe the project goals and scope', 'Mô tả mục tiêu và phạm vi dự án');
  String get clearDescriptionTooltip => _t('Clear description', 'Xoá mô tả');
  String get initialMembers => _t('Initial members', 'Thành viên ban đầu');
  String get initialMembersSubtitle => _t(
        'Optional. Each account is verified before it is added.',
        'Không bắt buộc. Mỗi tài khoản sẽ được xác minh trước khi thêm.',
      );
  String get memberEmailLabel => _t('Member email', 'Email thành viên');
  String get enterEmailBeforeAdding => _t('Enter an email before adding it', 'Nhập email trước khi thêm');
  String get enterValidEmail => _t('Enter a valid email address', 'Nhập địa chỉ email hợp lệ');
  String get ownerAddedAutomatically =>
      _t('The project owner is added automatically', 'Chủ dự án sẽ được thêm tự động');
  String get emailAlreadyInList => _t('This email is already in the list', 'Email này đã có trong danh sách');
  String get addEmailTooltip => _t('Add email', 'Thêm email');
  String get createProjectButton => _t('Create Project', 'Tạo dự án');
  String createAndAddMembers(int count) => _t('Create & Add $count Members', 'Tạo & thêm $count thành viên');
  String projectCreatedMsg(String name) => _t('Project "$name" created.', 'Đã tạo dự án "$name".');
  String projectCreatedWithMembersMsg(String name) =>
      _t('Project "$name" created with invited members.', 'Đã tạo dự án "$name" cùng các thành viên được mời.');
  String get onlyManagersCanCreateProjects =>
      _t('Only managers can create projects.', 'Chỉ quản lý mới có thể tạo dự án.');
  String get managerAccessRequired => _t('Manager access required', 'Cần quyền quản lý');

  // ─── Project Detail ────────────────────────────────────────────────────
  String get projectDetailsTitle => _t('Project Details', 'Chi tiết dự án');
  String get editProjectTooltip => _t('Edit project', 'Sửa dự án');
  String get moreActionsTooltip => _t('More actions', 'Thêm tùy chọn');
  String get manageMembers => _t('Manage members', 'Quản lý thành viên');
  String get deleteProjectMenuItem => _t('Delete project', 'Xoá dự án');
  String get loadingProjectDetails => _t('Loading project details...', 'Đang tải chi tiết dự án...');
  String get projectUnavailable => _t('Project unavailable', 'Không tìm thấy dự án');
  String get projectNotFound => _t('Project not found.', 'Không tìm thấy dự án.');
  String get projectIdLabel => _t('Project ID', 'Mã dự án');
  String get membersLabel => _t('Members', 'Thành viên');
  String get taskProgress => _t('Task progress', 'Tiến độ công việc');
  String get viewAll => _t('View all', 'Xem tất cả');
  String get projectMembersSection => _t('Project members', 'Thành viên dự án');
  String get manage => _t('Manage', 'Quản lý');
  String get noMemberInfoYet => _t('No member information is available yet.', 'Chưa có thông tin thành viên.');
  String get ownerChip => _t('Owner', 'Chủ dự án');
  String get viewProjectTasks => _t('View Project Tasks', 'Xem công việc dự án');
  String get loadingLiveTaskData => _t('Loading live task data...', 'Đang tải dữ liệu công việc...');
  String get allTasksLabel => _t('All tasks', 'Tất cả công việc');
  String get completedLabel => _t('Completed', 'Hoàn thành');
  String get toDoLabel => _t('To do', 'Cần làm');
  String get inProgressLabel => _t('In progress', 'Đang làm');
  String get projectIdCopied => _t('Project ID copied.', 'Đã sao chép mã dự án.');
  String deleteProjectDetailConfirm(String name) => _t(
        'Delete "$name"? Its tasks and member links will also be removed.',
        'Xoá "$name"? Công việc và liên kết thành viên cũng sẽ bị xoá.',
      );

  // ─── Edit Project ──────────────────────────────────────────────────────
  String get editProjectTitle => _t('Edit Project', 'Sửa dự án');
  String get updateProjectDetails => _t('Update project details', 'Cập nhật thông tin dự án');
  String get unsavedChanges => _t('Unsaved changes', 'Có thay đổi chưa lưu');
  String get everythingUpToDate => _t('Everything is up to date', 'Mọi thứ đã được cập nhật');
  String peopleInProject(int count) => _t('$count people in this project', '$count người trong dự án');
  String get projectChangesSaved => _t('Project changes saved.', 'Đã lưu thay đổi dự án.');
  String get dangerZone => _t('Danger zone', 'Vùng nguy hiểm');
  String get deletingProjectAlsoRemoves => _t(
        'Deleting a project also removes its task and member links.',
        'Xoá dự án cũng sẽ xoá công việc và liên kết thành viên liên quan.',
      );
  String get deleteProjectButton => _t('Delete Project', 'Xoá dự án');
  String get ownerAccessRequired => _t('Owner access required', 'Cần quyền chủ dự án');
  String get onlyOwnerCanEditOrDelete => _t(
        'Only the project owner can edit or delete this project.',
        'Chỉ chủ dự án mới có thể sửa hoặc xoá dự án này.',
      );
  String get deleteProjectPermanentlyQuestion =>
      _t('Delete project permanently?', 'Xoá vĩnh viễn dự án?');
  String deleteProjectPermanentlyBody(String name) => _t(
        '"$name" and all related tasks will be deleted. This action cannot be undone.',
        '"$name" và toàn bộ công việc liên quan sẽ bị xoá. Hành động này không thể hoàn tác.',
      );
  String get keepProject => _t('Keep project', 'Giữ lại dự án');
  String get deletePermanently => _t('Delete permanently', 'Xoá vĩnh viễn');
  String get discardChangesQuestion => _t('Discard changes?', 'Huỷ bỏ thay đổi?');
  String get discardChangesBody => _t(
        'You have unsaved project changes. Leave without saving them?',
        'Bạn có thay đổi dự án chưa lưu. Rời đi mà không lưu?',
      );
  String get loadingProject => _t('Loading project...', 'Đang tải dự án...');

  // ─── Member Management ─────────────────────────────────────────────────
  String get manageMembersTitle => _t('Manage Members', 'Quản lý thành viên');
  String get ownerCannotBeRemoved => _t('The project owner cannot be removed.', 'Không thể xoá chủ dự án.');
  String get cannotRemoveYourself => _t(
        'You cannot remove yourself from a project you manage.',
        'Bạn không thể tự xoá mình khỏi dự án đang quản lý.',
      );
  String get reassignActiveTasksFirst => _t('Reassign active tasks first', 'Cần bàn giao công việc trước');
  String memberHasUnfinishedTasks(String name, int count) => _t(
        '$name still has $count unfinished ${count == 1 ? 'task' : 'tasks'}. Reassign or finish them before removing this member.',
        '$name vẫn còn $count công việc chưa hoàn thành. Hãy bàn giao hoặc hoàn thành trước khi xoá thành viên này.',
      );
  String get viewTasksButton => _t('View tasks', 'Xem công việc');
  String get removeMemberQuestion => _t('Remove member?', 'Xoá thành viên?');
  String removeMemberBody(String name) => _t(
        'Remove $name from this project? Their account and other projects will not be affected.',
        'Xoá $name khỏi dự án này? Tài khoản và các dự án khác của họ sẽ không bị ảnh hưởng.',
      );
  String get memberAddedSuccess => _t('Member added successfully.', 'Đã thêm thành viên thành công.');
  String memberRemovedMsg(String name) => _t('$name removed from the project.', 'Đã xoá $name khỏi dự án.');
  String get searchMembersHint =>
      _t('Search members by name or email', 'Tìm thành viên theo tên hoặc email');
  String get filterOwner => _t('Owner', 'Chủ dự án');
  String get filterMembers => _t('Members', 'Thành viên');
  String get sortMembersTooltip => _t('Sort members', 'Sắp xếp thành viên');
  String get addAMember => _t('Add a member', 'Thêm thành viên');
  String get addMemberButton => _t('Add Member', 'Thêm thành viên');
  String get emailRequired => _t('Email is required', 'Vui lòng nhập email');
  String get teamMembers => _t('Team members', 'Thành viên nhóm');
  String get noMembersFound => _t('No members found', 'Không tìm thấy thành viên');
  String get addMemberOrChangeFilter => _t(
        'Add a member or change the current search and filter.',
        'Thêm thành viên hoặc thay đổi tìm kiếm/bộ lọc hiện tại.',
      );
  String get removeMemberTooltip => _t('Remove member', 'Xoá thành viên');
  String get membersUnavailable => _t('Members unavailable', 'Không tải được thành viên');
  String get onlyOwnerCanManageMembers =>
      _t('Only the project owner can manage its members.', 'Chỉ chủ dự án mới có thể quản lý thành viên.');
  String get loadingProjectMembers => _t('Loading project members...', 'Đang tải thành viên dự án...');
  String get onlyManagersCanAddRemoveMembers => _t(
        'Only managers can add or remove project members.',
        'Chỉ quản lý mới có thể thêm hoặc xoá thành viên dự án.',
      );
  String memberCountLabel(int count) => _t('$count ${count == 1 ? 'member' : 'members'}', '$count thành viên');

  // ─── Task List ─────────────────────────────────────────────────────────
  String get myTasksTitle => _t('My Tasks', 'Công việc của tôi');
  String get projectTasksTitle => _t('Project Tasks', 'Công việc dự án');
  String get searchTitleOrDescription => _t('Search title or description', 'Tìm theo tiêu đề hoặc mô tả');
  String get newTaskButton => _t('New task', 'Công việc mới');
  String get loadingTasks => _t('Loading tasks...', 'Đang tải công việc...');
  String get unableToLoadTasks => _t('Unable to load tasks', 'Không thể tải công việc');
  String get noTasksYet => _t('No tasks yet', 'Chưa có công việc nào');
  String get createTaskAndAssign => _t(
        'Create a task and assign it to see it here.',
        'Tạo một công việc và giao cho ai đó để xem tại đây.',
      );
  String get noTasksInProject => _t('No tasks in this project yet.', 'Dự án này chưa có công việc nào.');
  String get tryAnotherSearchOrFilter => _t(
        'Try another search term or status filter.',
        'Thử từ khoá tìm kiếm hoặc bộ lọc trạng thái khác.',
      );

  // ─── Create Task ───────────────────────────────────────────────────────
  String get createTaskTitle => _t('Create Task', 'Tạo công việc');
  String get defineTheWork => _t('Define the work', 'Mô tả công việc');
  String get projectFieldLabel => _t('Project', 'Dự án');
  String get selectAProject => _t('Select a project', 'Chọn một dự án');
  String get taskNameLabel => _t('Task Name', 'Tên công việc');
  String get taskNameHint => _t('e.g. Integrate Dio Client', 'VD: Tích hợp Dio Client');
  String get taskNameRequired => _t('Task name is required', 'Vui lòng nhập tên công việc');
  String get taskNameMinLength =>
      _t('Task name must be at least 3 characters', 'Tên công việc phải có ít nhất 3 ký tự');
  String get taskNameMaxLength =>
      _t('Task name must not exceed 120 characters', 'Tên công việc không được vượt quá 120 ký tự');
  String get assignMember => _t('Assign Member', 'Giao cho thành viên');
  String taskCreatedMsg(String title) => _t('Task "$title" created.', 'Đã tạo công việc "$title".');
  String meLabel(String name) => _t('$name (me)', '$name (tôi)');
  String get onlyManagersCanCreateTasks =>
      _t('Only managers can create tasks.', 'Chỉ quản lý mới có thể tạo công việc.');

  // ─── Task Detail ───────────────────────────────────────────────────────
  String get taskDetailTitle => _t('Task Detail', 'Chi tiết công việc');
  String get editTaskTooltip => _t('Edit task', 'Sửa công việc');
  String get deleteTaskTooltip => _t('Delete task', 'Xoá công việc');
  String get updateStatusTooltip => _t('Update status', 'Cập nhật trạng thái');
  String get loadingTaskDetails => _t('Loading task details...', 'Đang tải chi tiết công việc...');
  String get taskUnavailable => _t('Task unavailable', 'Không tìm thấy công việc');
  String get taskNotFound => _t('Task not found.', 'Không tìm thấy công việc.');
  String get assignedToLabel => _t('Assigned to', 'Giao cho');
  String get editTaskButton => _t('Edit Task', 'Sửa công việc');
  String get updateStatusButton => _t('Update Status', 'Cập nhật trạng thái');
  String get deleteTaskButton => _t('Delete Task', 'Xoá công việc');

  // ─── Edit Task ─────────────────────────────────────────────────────────
  String get editTaskTitle => _t('Edit Task', 'Sửa công việc');
  String get membersCanUpdateStatusNote => _t(
        'Members can update task status. Other fields are manager-only.',
        'Thành viên chỉ có thể cập nhật trạng thái. Các trường khác chỉ quản lý mới sửa được.',
      );
  String get updateTaskButton => _t('Update Task', 'Cập nhật công việc');
  String get taskUpdatedMsg => _t('Task updated.', 'Đã cập nhật công việc.');
  String get loadingTask => _t('Loading task...', 'Đang tải công việc...');
  String get clearDueDateTooltip => _t('Clear due date', 'Xoá hạn chót');

  // ─── Update Task Status ────────────────────────────────────────────────
  String get selectStatusBeforeSaving =>
      _t('Select a status before saving.', 'Chọn trạng thái trước khi lưu.');
  String get statusAlreadyUpToDate => _t('Status is already up to date.', 'Trạng thái đã được cập nhật.');
  String statusUpdatedTo(String status) => _t('Status updated to $status.', 'Đã cập nhật trạng thái thành $status.');
  String get couldNotUpdateStatus => _t('Could not update status.', 'Không thể cập nhật trạng thái.');
  String currentStatusLabel(String status) => _t('Current status: $status', 'Trạng thái hiện tại: $status');
  String get selectNewStatus => _t('Select new status', 'Chọn trạng thái mới');
  String get statusHintTodo => _t('Not started yet', 'Chưa bắt đầu');
  String get statusHintInProgress => _t('Currently being worked on', 'Đang thực hiện');
  String get statusHintDone => _t('Completed', 'Đã hoàn thành');
  String get saveStatusButton => _t('Save Status', 'Lưu trạng thái');
  String get onlyAssigneeOrManagerCanUpdate => _t(
        'Only the assignee or a manager can update this task status.',
        'Chỉ người được giao hoặc quản lý mới có thể cập nhật trạng thái công việc này.',
      );

  // ─── Delete Task ───────────────────────────────────────────────────────
  String get deleteTaskTitle => _t('Delete Task', 'Xoá công việc');
  String get confirmDeletionFirst =>
      _t('Confirm deletion before continuing.', 'Vui lòng xác nhận trước khi tiếp tục.');
  String taskDeletedMsg(String title) => _t('"$title" deleted.', 'Đã xoá "$title".');
  String get couldNotDeleteTask => _t('Could not delete task.', 'Không thể xoá công việc.');
  String get onlyManagersCanDeleteTasks =>
      _t('Only managers can delete tasks.', 'Chỉ quản lý mới có thể xoá công việc.');
  String get deleteTaskPermanentlyQuestion =>
      _t('Delete this task permanently?', 'Xoá vĩnh viễn công việc này?');
  String get deleteTaskPermanentlyBody => _t(
        'This action cannot be undone. Related offline sync entries for this task will also be cleared.',
        'Hành động này không thể hoàn tác. Các mục đồng bộ ngoại tuyến liên quan cũng sẽ bị xoá.',
      );
  String statusColonLabel(String status) => _t('Status: $status', 'Trạng thái: $status');
  String priorityColonLabel(String priority) => _t('Priority: $priority', 'Độ ưu tiên: $priority');
  String assigneeColonLabel(String assignee) => _t('Assignee: $assignee', 'Người được giao: $assignee');
  String get iUnderstandDeleteForever => _t(
        'I understand this task will be deleted forever.',
        'Tôi hiểu công việc này sẽ bị xoá vĩnh viễn.',
      );
  String get deletingEllipsis => _t('Deleting...', 'Đang xoá...');
  String get keepTask => _t('Keep task', 'Giữ lại công việc');
}
