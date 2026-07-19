# Bản đặc tả yêu cầu Module 4: Dashboard & Settings (Member 4)

Tài liệu này đặc tả chi tiết yêu cầu chức năng, giao diện, và phân tích độ phức tạp (LOC) cho 4 màn hình thuộc Module 4 do Member 4 phụ trách, đáp ứng đầy đủ yêu cầu nghiệp vụ và kỹ thuật (SQLite, REST API, FCM, Riverpod, Bất đồng bộ).

---

## 1. Màn hình 1: Dashboard (Màn hình chính)

### 1.1. Mô tả yêu cầu (Description)
Hiển thị thông tin tổng quan về các dự án và công việc của người dùng hiện tại (Manager hoặc Member). Hỗ trợ xem nhanh các số liệu và trạng thái kết nối.

- **Tác nhân (Actors):** Manager, Member.
- **Lập trình bất đồng bộ:** Tải thông tin bất đồng bộ từ SQLite hoặc REST API.
- **Quản lý trạng thái:** Riverpod `dashboardViewModelProvider`.

### 1.2. Đặc tả giao diện (Fields - 8 thành phần)
1. **Lời chào (Greeting):** Hiển thị lời chào theo thời gian thực (Chào buổi sáng/chiều/tối) + Tên người dùng.
2. **Ảnh đại diện (Avatar):** Hiển thị ký tự viết tắt của tên người dùng.
3. **Thẻ thống kê dự án (Total Projects Card):** Hiển thị tổng số dự án hiện có.
4. **Thẻ thống kê công việc (Total Tasks Card):** Hiển thị tổng số công việc được giao.
5. **Thẻ công việc hoàn thành (Completed Tasks Card):** Hiển thị số công việc trạng thái "DONE".
6. **Thanh tiến độ (Progress Bar):** Thể hiện trực quan tỷ lệ % hoàn thành công việc.
7. **Nút Làm mới (Refresh Button):** Icon tải lại dữ liệu mới nhất từ Server.
8. **Chỉ báo mạng (Connectivity Indicator):** Hiển thị trạng thái Online/Offline.

### 1.3. Luồng xử lý chính & Ngoại lệ (Flow of Events)
* **Happy Case (Online):** 
  - Ứng dụng gửi request `GET /statistics` lên Backend API.
  - Nhận về JSON chứa các trường thống kê, lưu cache vào SQLite thông qua `DbHelper`.
  - ViewModel cập nhật UI hiển thị số liệu mới nhất.
* **Unhappy Case (Offline):** 
  - Mất kết nối internet, request API thất bại.
  - Hệ thống tự động chuyển sang đọc dữ liệu từ local SQLite thông qua `DbHelper.getLocalStatistics()`.
  - Hiển thị chỉ báo "Offline" và cập nhật các thẻ số liệu dựa trên dữ liệu cache gần nhất.

### 1.4. Phân tích độ phức tạp & LOC quy đổi
- **Số lượng Transaction:** 4 (API statistics, SQLite write, SQLite read, SharedPreferences read).
- **Mức độ phức tạp:** **Level 3 (Trung bình)** -> Quy đổi: **120 LOC**.
- **Chất lượng kiểm thử:** **L3_Optimized (Hệ số 1.0)** do xử lý hoàn hảo offline mode & pull-to-refresh.
- **Evaluated LOC:** **120 LOC**.

---

## 2. Màn hình 2: Thống kê (Statistics Screen)

### 2.1. Mô tả yêu cầu (Description)
Biểu diễn trực quan tỷ lệ phân bổ công việc dưới dạng biểu đồ hình quạt (Pie Chart) giúp người quản lý hoặc thành viên dễ dàng đánh giá hiệu suất.

- **Tác nhân (Actors):** Manager, Member.
- **Gói thư viện tích hợp:** `fl_chart`.

### 2.2. Đặc tả giao diện (Fields - 8 thành phần)
1. **Bộ chọn chế độ (Segmented Toggle):** Chọn xem biểu đồ "Theo trạng thái" hoặc "Theo mức độ ưu tiên".
2. **Biểu đồ tròn (Pie Chart):** Vẽ biểu đồ phân bổ phần trăm động.
3. **Chú thích màu sắc (Legend Grid):** Giải thích ý nghĩa của các màu sắc (Ví dụ: Đỏ = HIGH, Xanh = DONE).
4. **Thống kê chi tiết dạng danh sách (Details List):** Hiện số lượng task cụ thể của từng loại.
5. **Dropdown chọn Dự án (Project Selector):** Lọc số liệu thống kê riêng cho từng dự án.
6. **Nút Làm mới (Refresh Icon):** Tải lại dữ liệu thống kê từ Server.
7. **Nút Export báo cáo (Export Button):** Nút giả lập (Mock UI) hỗ trợ chia sẻ báo cáo.
8. **Chữ số tổng kết (Summary Text):** Hiển thị tổng số công việc được đưa vào biểu đồ.

### 2.3. Luồng xử lý chính & Ngoại lệ (Flow of Events)
* **Happy Case (Online):**
  - Người dùng mở màn hình hoặc thay đổi bộ lọc (Dự án, chế độ lọc).
  - ViewModel gửi yêu cầu lấy dữ liệu thống kê biểu đồ.
  - UI vẽ lại biểu đồ với các lát cắt có kích thước và phần trăm tương ứng, kèm hiệu ứng animation.
* **Unhappy Case (Offline):**
  - Không có mạng, hệ thống truy vấn bảng `tasks` cục bộ để đếm và tự động tính toán phần trăm trực tiếp từ SQLite. Vẽ biểu đồ dựa trên dữ liệu offline.

### 2.4. Phân tích độ phức tạp & LOC quy đổi
- **Số lượng Transaction:** 4 (Fetch stats filter, Cache to SQLite, Local DB compute, UI filter toggles).
- **Mức độ phức tạp:** **Level 3 (Trung bình)** -> Quy đổi: **120 LOC**.
- **Chất lượng kiểm thử:** **L3_Optimized (Hệ số 1.0)**.
- **Evaluated LOC:** **120 LOC**.

---

## 3. Màn hình 3: Trung tâm thông báo (Notification Center)

### 3.1. Mô tả yêu cầu (Description)
Nơi nhận và lưu trữ lịch sử các thông báo đẩy (FCM) liên quan đến phân công công việc, cập nhật trạng thái dự án. Hỗ trợ thao tác đánh dấu đã đọc hoặc xóa thông báo.

- **Tác nhân (Actors):** Manager, Member.
- **Gói thư viện tích hợp:** `firebase_messaging` (FCM), SQLite.

### 3.2. Đặc tả giao diện (Fields - 9 thành phần)
1. **Thanh lọc (Filter Chips):** Chọn xem "Tất cả", "Chưa đọc", hoặc "Đã đọc".
2. **Nút Đọc tất cả (Mark All Read Button):** Cho phép đổi trạng thái toàn bộ thông báo sang đã đọc bằng 1 chạm.
3. **Danh sách thông báo (Notification ListView):** Danh sách cuộn hiển thị các card thông báo.
4. **Icon trạng thái (Status Icon):** Thể hiện thư mở (đã đọc) hoặc thư đóng (chưa đọc).
5. **Tiêu đề thông báo (Title Text):** Tiêu đề của thông báo (chữ in đậm nếu chưa đọc).
6. **Nội dung thông báo (Body Text):** Chi tiết sự kiện xảy ra.
7. **Thời gian nhận (Time Tag):** Định dạng dạng "X phút trước" hoặc ngày cụ thể.
8. **Nút xóa nhanh (Swipe to Delete):** Thao tác vuốt ngang để xóa nhanh một thông báo.
9. **Số đếm chưa đọc (Badge):** Hiển thị số lượng thông báo chưa đọc trên App Bar.

### 3.3. Luồng xử lý chính & Ngoại lệ (Flow of Events)
* **Happy Case (Online):**
  - Thiết bị nhận được tin nhắn FCM từ Firebase -> Hiện thông báo trên thanh trạng thái hệ thống.
  - Người dùng mở danh sách, app gọi `GET /notifications` để lấy danh sách đầy đủ.
  - Người dùng chạm vào thông báo -> Gọi API `PUT /notifications/{id}/read` để đánh dấu đã đọc trên Server và cập nhật SQLite.
* **Unhappy Case (Offline):**
  - Người dùng đọc các thông báo đã lưu trong SQLite cục bộ.
  - Người dùng vuốt xóa thông báo -> Hệ thống xóa bản ghi đó trong SQLite trước (Optimistic update) và đưa tác vụ xóa vào hàng đợi `pending_actions` để đồng bộ lại khi có mạng.

### 3.4. Phân tích độ phức tạp & LOC quy đổi
- **Số lượng Transaction:** 4 (Get notifications API, Cache to SQLite, Mark as read API/DB, Delete API/DB).
- **Mức độ phức tạp:** **Level 3 (Trung bình)** -> Quy đổi: **120 LOC**.
- **Chất lượng kiểm thử:** **L3_Optimized (Hệ số 1.0)** do có tích hợp cơ chế vuốt xóa (Dismissible) phức tạp.
- **Evaluated LOC:** **120 LOC**.

---

## 4. Màn hình 4: Cài đặt (Settings Screen)

### 4.1. Mô tả yêu cầu (Description)
Cấu hình giao diện và tùy chọn cá nhân hóa của ứng dụng. Dữ liệu cài đặt phải được lưu trữ vĩnh viễn (persistent).

- **Tác nhân (Actors):** Manager, Member.
- **Gói thư viện tích hợp:** `shared_preferences`.

### 4.2. Đặc tả giao diện (Fields - 7 thành phần)
1. **Thông tin tài khoản (Profile Card):** Hiển thị avatar, tên, email và vai trò (Role).
2. **Switch Giao diện tối (Dark Mode Switch):** Bật/tắt chế độ nền tối toàn ứng dụng.
3. **Switch Thông báo đẩy (FCM Switch):** Bật/tắt nhận thông báo từ Firebase.
4. **Switch Âm thanh (Sound Switch):** Tùy chọn bật/tắt chuông báo.
5. **Nút Dọn dẹp bộ nhớ (Clear Cache Button):** Xóa toàn bộ dữ liệu SQLite cache cục bộ.
6. **Bộ chọn Ngôn ngữ (Language Dropdown):** Chọn hiển thị Tiếng Anh/Tiếng Việt.
7. **Nút Đăng xuất (Logout Button):** Nút đăng xuất màu đỏ nổi bật ở cuối màn hình.

### 4.3. Luồng xử lý chính & Ngoại lệ (Flow of Events)
* **Happy Case:**
  - Người dùng chuyển đổi Dark Mode Switch -> ViewModel cập nhật State -> Ghi trực tiếp giá trị bool vào `SharedPreferences`.
  - `MaterialApp` ở tầng gốc lắng nghe thay đổi thông qua Riverpod và thay đổi `ThemeMode` tức thì trên toàn app.
  - Người dùng bấm đăng xuất -> Hiện dialog xác nhận -> Xóa token và chuyển hướng về màn hình `/login`.
* **Ngoại lệ (Clear Cache):**
  - Người dùng bấm Xóa Cache -> Xóa sạch các bảng `notifications` và `tasks` offline trong SQLite để giải phóng dung lượng.

### 4.4. Phân tích độ phức tạp & LOC quy đổi
- **Số lượng Transaction:** 3 (Save SharedPreferences, Register/Unregister FCM Topic, Clear local DB tables).
- **Mức độ phức tạp:** **Level 2 (Đơn giản)** -> Quy đổi: **90 LOC**.
- **Chất lượng kiểm thử:** **L3_Optimized (Hệ số 1.0)** do có Dialog xác nhận và đổi theme tức thì.
- **Evaluated LOC:** **90 LOC**.

---

## 5. Tổng kết khối lượng công việc Member 4

| STT | Tên màn hình | Mức độ phức tạp | Số Transaction/Fields | Quality Level | LOC quy đổi |
|---|---|---|---|---|---|
| 1 | **Dashboard** | Level 3 | 4 trans / 8 fields | 1.0 (L3_Optimized) | **120 LOC** |
| 2 | **Thống kê (Statistics)** | Level 3 | 4 trans / 8 fields | 1.0 (L3_Optimized) | **120 LOC** |
| 3 | **Thông báo (Notification)** | Level 3 | 4 trans / 9 fields | 1.0 (L3_Optimized) | **120 LOC** |
| 4 | **Cài đặt (Settings)** | Level 2 | 3 trans / 7 fields | 1.0 (L3_Optimized) | **90 LOC** |
| **Tổng** | **4 Screens** | | | | **450 LOC** |

*Kết luận: Tổng khối lượng LOC của Member 4 đạt **450 LOC**, vượt xa yêu cầu tối thiểu là **360 LOC** (4 screens * 90 LOC) của môn học.*
