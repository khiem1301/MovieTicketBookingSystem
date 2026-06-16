# Movie Ticket Booking System

Hệ thống đặt vé xem phim — **Java 17 · JSP/Servlet · SQL Server · Maven · Tomcat 10**.

> Chi tiết nghiệp vụ, schema **28 bảng** và 50 FR: [`project_summary_final.md`](project_summary_final.md)  
> Module Admin (tính năng đã triển khai): [`ADMIN_MODULE_DETAIL.md`](ADMIN_MODULE_DETAIL.md)  
> Hướng dẫn Database & migration cho nhóm: [`Database/README.md`](Database/README.md)

---

# Technologies Used

## Backend

### Java Servlet (Jakarta EE 10)

Java Servlet là nền tảng xử lý HTTP Request/Response, đóng vai trò **Controller** trong mô hình MVC.

Framework được sử dụng để:

- Nhận request từ trình duyệt (GET/POST).
- Gọi tầng DAL (DAO) để truy vấn cơ sở dữ liệu.
- Điều phối luồng xử lý và forward/redirect sang JSP.
- Quản lý session (đăng nhập, phân quyền theo role).

---

### JDBC + DAO Pattern

Dự án kết nối SQL Server trực tiếp qua JDBC thông qua `DBContext` và các lớp DAO trong package `dal`.

- Không sử dụng ORM (Hibernate/EF).
- SQL được viết trong từng `*DAO.java`.
- Connection pool đơn giản qua `DBContext.getConnection()`.

---

### SQL Server

SQL Server là hệ quản trị cơ sở dữ liệu quan hệ lưu trữ toàn bộ dữ liệu hệ thống.

- Database: `MovieTicketDB`
- **28 bảng** đặt tên **PascalCase** (`Users`, `Bookings`, `Movies`, `SystemConfigLog`, `UserStatusLog`, …)
- Script khởi tạo: `Database/create_database.sql`
- Cập nhật schema incremental: `Database/migrations/` — chi tiết [`Database/README.md`](Database/README.md)

---

### Apache Maven

Maven quản lý dependency, build và đóng gói ứng dụng dạng **WAR**.

```bash
mvn clean package
```

Artifact output: `target/MovieTicketBookingSystem-1.0-SNAPSHOT.war`

---

## Frontend

### JSP (JavaServer Pages)

JSP là công nghệ render giao diện phía server, đóng vai trò **View** trong MVC.

- JSP đặt trong `WEB-INF/views/` — không truy cập trực tiếp từ URL.
- Chỉ hiển thị dữ liệu do Servlet forward sang.
- Dùng JSTL cho vòng lặp, điều kiện.

**Ví dụ forward từ Servlet:**

```java
request.setAttribute("movies", movieList);
request.getRequestDispatcher("/WEB-INF/views/customer/movie-list.jsp")
       .forward(request, response);
```

---

### HTML / CSS / JavaScript

Tài nguyên tĩnh nằm trong `src/main/webapp/`:

- `css/main.css`
- `js/main.js`
- `images/`

---

## Server

### Apache Tomcat 10.1+

Tomcat 10 hỗ trợ **Jakarta EE 10** (Servlet 6.0, JSP 3.1).

Sau khi deploy WAR, truy cập:

```text
http://localhost:8080/MovieTicketBookingSystem/
```

**IntelliJ IDEA:** Run → Edit Configurations → **Tomcat Server (Local)** → Deployment → thêm artifact WAR → Run.

---

# Getting Started

## Yêu cầu hệ thống


| Công cụ       | Phiên bản gợi ý                           |
| ------------- | ----------------------------------------- |
| JDK           | 17+                                       |
| Maven         | 3.9+ (hoặc Maven tích hợp trong IntelliJ) |
| SQL Server    | 2019+ (Express được)                      |
| Tomcat        | 10.1+ (Jakarta EE 10)                     |
| SSMS / sqlcmd | Tùy chọn — để chạy script DB              |


---

## Clone và chạy nhanh

| Bước | Việc cần làm | Tài liệu |
| ---- | ------------- | -------- |
| **1** | Cấu hình Database (`database.properties` + tạo bảng) | [Cấu hình Database](#1-cấu-hình-database) |
| **2** | Build WAR và chạy Tomcat | [Build và deploy](#2-build-và-deploy) |
| **3** | Cấu hình Email SMTP | [Cấu hình Email SMTP](#3-cấu-hình-email-smtp) |
| **4** | Cấu hình Google OAuth | [Cấu hình Google OAuth](#4-cấu-hình-google-oauth) |

> **Thành viên mới:** Làm bước **1 → 2** trước để chạy được app cơ bản. Bước **3 → 4** dùng mail + OAuth chung nhóm; mỗi người chỉ sửa **URL Tomcat** trên máy mình.

---

## 1. Cấu hình Database

Phần này gồm **hai việc**: (A) cấu hình file `database.properties` kết nối SQL Server, và (B) chạy script tạo database + bảng.

### 1.1. File `database.properties`

#### Các script hỗ trợ (`scripts/`)


| Script                            | Chạy khi nào                         | Tác dụng                                                             |
| --------------------------------- | ------------------------------------ | -------------------------------------------------------------------- |
| `install-git-hooks.bat`           | **Một lần** sau khi clone            | Cài hook Git — tự khôi phục `database.properties` sau mỗi `git pull` |
| `setup.bat`                       | Lần đầu / khi chưa có file config    | Copy `.example` → `database.properties` (không ghi đè nếu đã có)     |
| `setup.ps1`                       | Tương đương `setup.bat`              | Dùng trong PowerShell                                                |
| `backup-database-properties.bat`  | **Trước** `git pull`                 | Lưu bản sao → `database.properties.backup` (gitignored)              |
| `restore-database-properties.bat` | **Sau** `git pull` / khi file bị mất | Khôi phục từ `.backup`, hoặc tạo từ `.example` nếu chưa có backup    |


PowerShell tương ứng: `.\scripts\setup.ps1`

File cấu hình: `src/main/resources/database.properties` — **chỉ tồn tại trên máy bạn**, không đưa lên Git (chỉ có `database.properties.example` trên repo).

#### A. Lần đầu clone (làm theo thứ tự)

**1.** Cài Git hook (chỉ một lần):

```bat
scripts\install-git-hooks.bat
```

**2.** Tạo file cấu hình:

```bat
scripts\setup.bat
```

**3.** Mở `src/main/resources/database.properties`, sửa **2 dòng**:

```properties
db.server=TEN_MAY_SQL_CUA_BAN
db.password=MAT_KHAU_SA_CUA_BAN
```

Đảm bảo `db.name` trùng script SQL (mặc định `MovieTicketDB`).

**4.** Lưu backup local (giữ mật khẩu sau này):

```bat
scripts\backup-database-properties.bat
```

> **Quan trọng:** Không commit `database.properties` hay `database.properties.backup` lên Git.

---

#### B. Mỗi lần `git pull` — tránh mất file cấu hình

Pull từ `master` có thể **xóa** `database.properties` trên máy (vì file này đã bị gỡ khỏi repo). `.gitignore` không ngăn được hành vi đó.

**Cách khuyến nghị — backup thủ công:**

```bat
scripts\backup-database-properties.bat
git pull origin master
scripts\restore-database-properties.bat
```

**Cách tự động** (nếu đã chạy `install-git-hooks.bat`):

Hook `post-merge` tự chạy sau pull và:

1. Khôi phục từ `database.properties.backup` nếu có, hoặc
2. Tạo mới từ `.example` → cần sửa lại `db.server` / `db.password`

**Cách thủ công** (khi chưa có backup):

```bat
git pull origin master
scripts\setup.bat
```

Rồi sửa lại `db.server` và `db.password`.

---

#### C. File bị mất / lỗi `Missing database.properties`

```bat
scripts\restore-database-properties.bat
```

Nếu chưa từng backup:

```bat
scripts\setup.bat
```

Sau đó sửa mật khẩu và chạy `backup-database-properties.bat`.

---

### 1.2. Tạo database và bảng

#### Lần đầu (máy chưa có `MovieTicketDB`)

1. Bật SQL Server, bật **SQL Server Authentication** cho user `sa` (nếu dùng `sa`).
2. Mở [`Database/create_database.sql`](Database/create_database.sql) trong SSMS hoặc Azure Data Studio.
3. Chạy **toàn bộ file** (Ctrl+A → F5) → tạo `MovieTicketDB`, **28 bảng** và **seed data** (users, phim, genres, loyalty config, VAT, …).
4. **Không cần** chạy `migrations/` nếu vừa dùng bản `create_database.sql` mới nhất trên repo.

Đảm bảo `db.name` trong `database.properties` trùng tên DB:

```properties
db.name=MovieTicketDB
```

**Tài khoản seed** (mật khẩu `Password@123`): `admin@movieticket.vn`, `manager@movieticket.vn`, `staff@movieticket.vn`.

Chi tiết bảng & migration: [`Database/README.md`](Database/README.md).

#### Đã có DB cũ — sau `git pull` (thành viên trong nhóm)

Khi pull code có thay đổi schema, chạy migration trong `Database/migrations/` **theo thứ tự**:

| Migration | Khi nào chạy |
|-----------|----------------|
| `migrations/add_system_config_log.sql` | Dùng lịch sử chỉnh sửa tích điểm tại `/admin/config` |

```text
SSMS → mở file migration → F5
```

Script migration an toàn khi chạy lại (kiểm tra `IF NOT EXISTS`).

---

## 2. Build và deploy

```bash
mvn clean package
```

Deploy file WAR lên Tomcat 10:

```text
target/MovieTicketBookingSystem-1.0-SNAPSHOT.war
```

**IntelliJ:** Run → Edit Configurations → **Tomcat Server (Local)** → Deployment → thêm artifact WAR → Run.

---

## 3. Cấu hình Email SMTP

File cấu hình: `src/main/resources/email.properties` — **chỉ tồn tại trên máy bạn**, không commit lên Git (repo chỉ có `email.properties.example`).

**Mục đích:** App gửi **email xác thực đăng ký** (FR-01). Sau khi khách bấm **Tạo tài khoản**, hệ thống gửi link *Xác thực email* vào hộp thư.

### 3.1. Tạo file cấu hình (làm 1 lần)

Mở **CMD** hoặc **PowerShell** tại **thư mục gốc project** (nơi có `pom.xml`), chạy:

```bat
copy src\main\resources\email.properties.example src\main\resources\email.properties
```

Mở file `src/main/resources/email.properties` bằng IntelliJ hoặc Notepad để sửa ở các bước tiếp theo.

---

### 3.2. Cấu hình SMTP — **dùng chung cả nhóm** (copy y nguyên)

Nhóm ÉPCINE dùng **một Gmail hệ thống**: `epcine88@gmail.com`. Admin đã cấu hình App Password sẵn — **copy 8 dòng dưới vào `email.properties`** (4 dòng SMTP + 4 dòng tài khoản):

```properties
mail.smtp.host=smtp.gmail.com
mail.smtp.port=587
mail.smtp.auth=true
mail.smtp.starttls.enable=true
mail.smtp.username=epcine88@gmail.com
mail.smtp.password=<app-password-16-ky-tu>
mail.from=epcine88@gmail.com
mail.from.name=ÉPCINE
```

| Key | Giá trị nhóm | Ghi chú |
| --- | ------------ | ------- |
| `mail.smtp.host` | `smtp.gmail.com` | Server Gmail — **không sửa** |
| `mail.smtp.port` | `587` | Cổng TLS — **không sửa** |
| `mail.smtp.auth` | `true` | Bật đăng nhập SMTP — **không sửa** |
| `mail.smtp.starttls.enable` | `true` | Mã hóa STARTTLS — **không sửa** |
| `mail.smtp.username` | `epcine88@gmail.com` | Gmail gửi mail — **giống cả nhóm** |
| `mail.smtp.password` | *(lấy từ admin qua Zalo/Discord)* | **App Password** 16 ký tự — **không** phải mật khẩu đăng nhập Gmail |
| `mail.from` | `epcine88@gmail.com` | Địa chỉ hiển thị người gửi |
| `mail.from.name` | `ÉPCINE` | Tên hiển thị: `ÉPCINE <epcine88@gmail.com>` |

> **Lưu ý:** `mail.smtp.password` là **Mật khẩu ứng dụng** (App Password), không phải mật khẩu bạn dùng đăng nhập Gmail trên trình duyệt.

> **Nếu App Password hết hạn / bị thu hồi:** Vào [Google App Passwords](https://myaccount.google.com/apppasswords) (cần bật Xác minh 2 bước), tạo mật khẩu mới tên `ÉPCINE`, cập nhật `mail.smtp.password` trên **mọi máy** dev.

---

### 3.3. Điền `app.base.url` — **mỗi máy khác nhau** (bắt buộc)

Đây là URL gốc app trên Tomcat **máy bạn**. Link xác thực trong email được ghép từ dòng này — **sai URL → link trong mail bị 404**.

**Cách lấy URL Tomcat trong IntelliJ:**

1. Góc **phải trên** màn hình → bấm tên cấu hình **Tomcat** (cạnh nút ▶ Run).
2. Chọn **Edit Configurations...**
3. Tab **Deployment** (hoặc xem thanh URL khi chạy) → copy URL, **bỏ dấu `/` cuối**.

**Ví dụ A — port 9999, deploy exploded WAR:**

```text
URL Tomcat: http://localhost:9999/MovieTicketBookingSystem_war_exploded/
```

→ Thêm vào `email.properties`:

```properties
app.base.url=http://localhost:9999/MovieTicketBookingSystem_war_exploded
```

**Ví dụ B — port 8080, deploy WAR:**

```properties
app.base.url=http://localhost:8080/MovieTicketBookingSystem
```

**Quy tắc:**

- Không thêm `/` ở cuối
- Đúng **port** (`8080`, `9999`, …)
- Đúng **context path** (`MovieTicketBookingSystem` hoặc `MovieTicketBookingSystem_war_exploded`)

---

### 3.4. Mẫu `email.properties` hoàn chỉnh (tham khảo)

```properties
mail.smtp.host=smtp.gmail.com
mail.smtp.port=587
mail.smtp.auth=true
mail.smtp.starttls.enable=true
mail.smtp.username=epcine88@gmail.com
mail.smtp.password=<app-password-16-ky-tu>
mail.from=epcine88@gmail.com
mail.from.name=ÉPCINE
app.base.url=http://localhost:9999/MovieTicketBookingSystem_war_exploded
```

Dòng cuối (`app.base.url`) — **sửa theo Tomcat trên máy bạn**.

---

### 3.5. Rebuild và kiểm tra gửi mail

1. IntelliJ: **Build → Rebuild Project**
2. **Restart Tomcat** (icon restart cạnh nút Run)
3. Mở `/register` → đăng ký tài khoản mới (email **chưa có** trong DB)
4. Kiểm tra hộp thư (kể cả **Spam**)

| Kết quả | Ý nghĩa |
| ------- | ------- |
| Trang pending báo **đã gửi email** | SMTP đúng |
| Trang pending hiện **link xác thực dev** | SMTP chưa đúng — vẫn tạo được tài khoản, dùng link trên trang để test |
| Link trong mail mở **404** | Sửa `app.base.url` cho khớp URL Tomcat |

---

### 3.6. Lỗi thường gặp (email)

| Lỗi | Cách xử lý |
| --- | ---------- |
| `535 Authentication failed` | Kiểm tra App Password; không dùng mật khẩu đăng nhập Gmail thường |
| Không nhận mail | Xem **Spam**; Rebuild + Restart Tomcat |
| Link verify `localhost:<PORT>/...` | Chưa điền `app.base.url` — sửa theo mục **3.3** |
| Sửa file không có hiệu lực | **Rebuild Project** + **Restart Tomcat** |

> Không commit `email.properties` lên Git (đã có trong `.gitignore`).

---

## 4. Cấu hình Google OAuth

File cấu hình: `src/main/resources/google.properties` — **chỉ tồn tại trên máy bạn**, không commit lên Git.

**Mục đích:** Bật nút **Đăng nhập bằng Google** trên `/login` và `/register`. Tài khoản Google mới sẽ được yêu cầu nhập ngày sinh + SĐT trước khi vào hệ thống.

> Nên hoàn thành mục **3. Cấu hình Email SMTP** trước — `google.redirect.uri` lấy cùng port/context với `app.base.url`.

---

### 4.1. Tạo file cấu hình (làm 1 lần)

```bat
copy src\main\resources\google.properties.example src\main\resources\google.properties
```

Mở `src/main/resources/google.properties` để sửa.

---

### 4.2. Client ID + Client Secret — **dùng chung cả nhóm** (copy y nguyên)

OAuth client đã được tạo trên Google Cloud Console cho project ÉPCINE. **Copy 2 dòng sau vào `google.properties`:**

```properties
google.client.id=<google-client-id>.apps.googleusercontent.com
google.client.secret=<google-client-secret>
```

| Key | Giá trị nhóm |
| --- | ------------ |
| `google.client.id` | *(lấy từ admin qua Zalo/Discord)* |
| `google.client.secret` | *(lấy từ admin qua Zalo/Discord)* |

> **Cả nhóm dùng chung** — không cần tạo OAuth client riêng trừ khi dev offline hoàn toàn.

---

### 4.3. Điền `google.redirect.uri` — **mỗi máy khác nhau** (bắt buộc)

URL callback sau khi Google xác thực. Phải **khớp 100%** với một dòng trong **Authorized redirect URIs** trên Google Cloud Console.

**Cách tính:**

1. Lấy `app.base.url` từ `email.properties` (mục **3.3**)
2. Thêm đuôi: `/auth/google/callback`

**Ví dụ — cùng máy với mục 3.3 (port 9999):**

```properties
google.redirect.uri=http://localhost:9999/MovieTicketBookingSystem_war_exploded/auth/google/callback
```

**Ví dụ — port 8080:**

```properties
google.redirect.uri=http://localhost:8080/MovieTicketBookingSystem/auth/google/callback
```

**Quy tắc:**

- Không thêm `/` ở cuối
- Port và context path phải **giống hệt** `app.base.url` + `/auth/google/callback`
- Sai 1 ký tự → Google báo `redirect_uri_mismatch`

**Thành viên mới:** Gửi **URL callback đầy đủ** của bạn cho admin (Gia Long) qua Zalo/Discord để được **thêm** vào Google Console → **APIs & Services** → **Credentials** → OAuth client → **Authorized redirect URIs** (nếu chưa có dòng URL của bạn).

---

### 4.4. Mẫu `google.properties` hoàn chỉnh (tham khảo)

```properties
google.client.id=<google-client-id>.apps.googleusercontent.com
google.client.secret=<google-client-secret>
google.redirect.uri=http://localhost:9999/MovieTicketBookingSystem_war_exploded/auth/google/callback
```

Dòng cuối — **sửa theo Tomcat trên máy bạn**.

---

### 4.5. Rebuild và kiểm tra Google login

1. **Build → Rebuild Project** → **Restart Tomcat**
2. Mở `/login` → phải thấy nút **Đăng nhập bằng Google**
3. Bấm nút → chọn Gmail

| Kết quả | Ý nghĩa |
| ------- | ------- |
| Vào trang chủ | Gmail đã có trong DB |
| Form hoàn tất Google (ngày sinh + SĐT) | Gmail mới — điền form rồi vào hệ thống |
| `redirect_uri_mismatch` | Sai `google.redirect.uri` hoặc chưa add URL trên Console |
| Trang **404** styled | Chưa có / sai `google.properties` — app coi OAuth chưa cấu hình |
| `invalid_client` | Kiểm tra lại Client ID / Secret |

---

### 4.6. Lỗi thường gặp (Google OAuth)

| Lỗi | Cách xử lý |
| --- | ---------- |
| `redirect_uri_mismatch` | Sửa `google.redirect.uri`; nhờ admin thêm URL callback trên Console |
| `invalid_client` | Copy lại ID/Secret từ mục **4.2** |
| Google chặn app (Testing) | Admin thêm Gmail của bạn vào **Test users** trên OAuth consent screen |
| Sửa file không có hiệu lực | Rebuild + Restart Tomcat |

> Không commit `google.properties` lên Git.

---

### 4.7. (Tham khảo) Admin — thêm redirect URI trên Google Console

Dành cho người quản lý OAuth client (`epcine88@gmail.com` / project ÉPCINE):

1. Vào [Google Cloud Console](https://console.cloud.google.com/) → chọn project **EPCINE**
2. **APIs & Services** → **Credentials** → mở OAuth 2.0 Client
3. **Authorized redirect URIs** → **Add URI** → dán URL callback của từng thành viên (mỗi port/context một dòng)
4. **Save**

Ví dụ nhiều máy trong nhóm:

```text
http://localhost:8080/MovieTicketBookingSystem/auth/google/callback
http://localhost:9999/MovieTicketBookingSystem_war_exploded/auth/google/callback
```

---

### Phân chia cấu hình Email + Google (tóm tắt)

| Mục | Cả nhóm giống nhau? | Ghi chú |
| --- | ------------------- | ------- |
| SMTP host/port/auth/starttls | **Có** | Gmail mặc định |
| `mail.smtp.username` / `password` / `from` | **Có** | `epcine88@gmail.com` |
| `mail.from.name` | **Có** | `ÉPCINE` |
| `app.base.url` | **Không** | URL Tomcat từng máy |
| `google.client.id` / `secret` | **Có** | OAuth client nhóm |
| `google.redirect.uri` | **Không** | Gửi admin để add trên Console nếu cần |

---

## Xử lý lỗi thường gặp


| Lỗi                                 | Cách xử lý                                                              |
| ----------------------------------- | ----------------------------------------------------------------------- |
| `Missing database.properties`       | Chạy `scripts\restore-database-properties.bat` hoặc `scripts\setup.bat` |
| Pull xong mất `database.properties` | `backup` → pull → `restore` (xem mục **1 — B**)                    |
| Login failed for user `sa`          | Kiểm tra mật khẩu, bật Mixed Mode trong SQL Server                      |
| Cannot open database                | Chạy `create_database.sql` hoặc sửa `db.name` cho khớp                  |
| Lỗi bảng `SystemConfigLog` không tồn tại | Chạy `Database/migrations/add_system_config_log.sql`              |
| Trang admin thiếu lịch sử loyalty   | Chạy migration `add_system_config_log.sql` (xem `Database/README.md`)   |
| Driver not found                    | `mvn clean package` để tải dependency JDBC                              |
| Tiếng Việt bị lỗi trên form         | Kiểm tra `EncodingFilter` và `pageEncoding="UTF-8"` trên JSP            |
| `535 Authentication failed` (email) | Kiểm tra App Password Gmail, không dùng mật khẩu đăng nhập thường       |
| Link xác thực email bị 404          | Sửa `app.base.url` trong `email.properties` cho khớp URL Tomcat         |
| `redirect_uri_mismatch` (Google)    | Sửa `google.redirect.uri`; nhờ admin thêm URL callback trên Console     |


---

## Checklist thành viên mới

- Clone repo
- `scripts\install-git-hooks.bat` (một lần)
- **Bước 1 — Database:** `scripts\setup.bat` → sửa `db.server`, `db.password` → chạy `Database/create_database.sql` (hoặc migration nếu DB đã có) → `scripts\backup-database-properties.bat`
- **Bước 2 — Build:** `mvn clean package` → cấu hình Tomcat 10 và chạy WAR
- **Bước 3 — Email:** `copy email.properties.example → email.properties` → copy SMTP nhóm, sửa `app.base.url` (mục **3**)
- **Bước 4 — Google:** `copy google.properties.example → google.properties` → copy Client ID/Secret, sửa `google.redirect.uri` (mục **4**)

> Trước mỗi lần pull: `backup-database-properties.bat` → pull → `restore-database-properties.bat`

---

# Git Workflow & Branching Rules

## 1. Branch Strategy

Dự án sử dụng mô hình phân nhánh:

```text
master
 ├── morgan/user-authentication
 ├── khiemnx/movie-management
 ├── minhnt/booking-payment
 ├── gialong/staff-counter
 ├── morgan/bugfix-login-validation
 └── khiemnx/hotfix-database-connection
```

### Master Branch

- `master` là nhánh ổn định.
- Chỉ chứa mã nguồn đã được kiểm tra và hoạt động ổn định.
- **Không commit trực tiếp lên `master`.**

---

## 2. Naming Convention

Mỗi branch gắn với **PIC** (Person In Charge — mã/tên viết tắt thành viên phụ trách).

Cú pháp:

```text
<pic>/<task-name>
```

Trong đó:

- `<pic>` — mã thành viên (vd: `morgan`, `khiemnx`, `minhnt`, `gialong`).
- `<task-name>` — mô tả công việc, dùng **kebab-case** (chữ thường, nối bằng dấu `-`).

### Ví dụ — Feature

```text
morgan/user-registration
khiemnx/showtime-management
minhnt/vnpay-integration
gialong/chatbot-support
```

### Ví dụ — Bug fix

```text
morgan/bugfix-seat-hold-expired
khiemnx/bugfix-age-validation
```

### Ví dụ — Hot fix

```text
minhnt/hotfix-sql-connection
gialong/hotfix-payment-callback
```

> Mỗi thành viên dùng **một mã PIC cố định** cho mọi branch của mình. Không dùng prefix `feature/`, `bugfix/`, `hotfix/` ở đầu branch nữa — ghi rõ loại việc trong `<task-name>` nếu cần.

---

## 3. Commit Message Convention

Cấu trúc:

```text
<type>: <description>
```

### Các loại commit


| Type     | Ý nghĩa                         |
| -------- | ------------------------------- |
| feat     | Thêm chức năng mới              |
| fix      | Sửa lỗi                         |
| refactor | Tái cấu trúc mã nguồn           |
| style    | Chỉnh sửa giao diện hoặc format |
| docs     | Cập nhật tài liệu               |
| test     | Thêm hoặc sửa test              |
| chore    | Công việc hỗ trợ, cấu hình      |


### Ví dụ

```text
feat: add user registration with date_of_birth validation

feat: create online booking and seat selection flow

fix: resolve UTF-8 encoding on registration form

refactor: extract booking price calculation to utility

docs: update README git workflow section

chore: stop tracking database.properties
```

---

## 4. Development Workflow

### Bước 1: Cập nhật mã nguồn mới nhất

```bash
git checkout master
git pull origin master
```

### Bước 2: Tạo branch mới

```bash
git checkout -b <pic>/<task-name>
```

Ví dụ:

```bash
git checkout -b morgan/user-registration
```

### Bước 3: Thực hiện phát triển

```bash
git add .
git commit -m "feat: add login servlet and auth filter"
```

### Bước 4: Push branch

```bash
git push -u origin <pic>/<task-name>
```

Ví dụ:

```bash
git push -u origin morgan/user-registration
```

### Bước 5: Tạo Pull Request

- Tạo Pull Request vào `master`.
- Chờ review trước khi merge.

---

## 5. Pull Request Rules

Trước khi tạo Pull Request:

- Code phải build thành công (`mvn clean package`).
- Không còn lỗi compile.
- Đã kiểm tra chức năng liên quan trên Tomcat.
- Không commit file tạm hoặc file cá nhân.

---

## 6. Files Ignored By Git

Sử dụng `.gitignore` để loại bỏ:

```text
target/
.idea/
*.class
*.war
*.iml

**/database.properties
!**/database.properties.example
**/database.properties.backup
**/email.properties
!**/email.properties.example
**/google.properties
!**/google.properties.example
```

### Không được push lên repository

- File build (`target/`, `*.war`, `*.class`).
- File cấu hình IDE (`.idea/`, `*.iml`).
- `**database.properties**` — chứa server name và mật khẩu SQL cá nhân.
- `**email.properties**` — chứa Gmail và App Password SMTP.
- `**google.properties**` — chứa Google OAuth Client Secret.

### Cấu hình database đúng cách


| File                          | Trên Git? | Mục đích                    |
| ----------------------------- | --------- | --------------------------- |
| `database.properties.example` | Có        | Mẫu cấu hình cho team       |
| `database.properties`         | **Không** | Cấu hình local từng máy     |
| `database.properties.backup`  | **Không** | Backup local trước/sau pull |
| `email.properties.example`    | Có        | Mẫu hướng dẫn Gmail SMTP    |
| `email.properties`            | **Không** | Gmail + App Password local  |
| `google.properties.example`   | Có        | Mẫu hướng dẫn Google OAuth  |
| `google.properties`           | **Không** | Client ID/Secret local      |


**Thành viên mới sau khi clone:**

```bat
scripts\install-git-hooks.bat
scripts\setup.bat
```

Rồi sửa `db.server`, `db.password`, chạy `scripts\backup-database-properties.bat`.

**Trước mỗi lần pull:**

```bat
scripts\backup-database-properties.bat
git pull origin master
scripts\restore-database-properties.bat
```

Chi tiết đầy đủ: mục **1. Cấu hình Database** trong Getting Started.

**Nếu lỡ commit `database.properties` lên Git:**

```bash
git rm --cached src/main/resources/database.properties
git add .gitignore
git commit -m "chore: stop tracking database.properties"
git push
```

File vẫn còn trên máy local — chỉ bị gỡ khỏi Git tracking. Nên **đổi mật khẩu SQL** nếu mật khẩu thật đã từng bị push.

---

## 7. Code Review Rules

Trước khi merge:

- Đọc lại code Servlet/DAO/JSP liên quan.
- Kiểm tra naming convention (PascalCase bảng DB, package MVC).
- Kiểm tra logic nghiệp vụ (tuổi T13/T16/T18, payment method, …).
- Loại bỏ code thừa, `System.out.println` debug.
- Không để lại code comment tạm không cần thiết.

Ví dụ không nên:

```java
// TODO: Fix later
// Temporary code
```

---

## 8. General Rules

### Nên làm

- Commit nhỏ và rõ ràng.
- Đặt tên branch theo `<pic>/<task-name>`, dễ hiểu và đúng người phụ trách.
- Viết commit message có ý nghĩa.
- Pull code mới nhất trước khi làm việc.
- Dùng `database.properties.example` làm mẫu, không share mật khẩu qua chat/commit.

### Không nên

- Commit trực tiếp lên `master`.
- Push code chưa build được.
- Commit nhiều chức năng không liên quan trong một commit.
- Đưa mật khẩu SQL, connection string thật vào repository.

---

## Recommended Workflow

```text
Pull master
    ↓
Create Branch (<pic>/<task-name>)
    ↓
Develop Feature (Servlet → DAO → JSP)
    ↓
Commit Changes
    ↓
Push Branch
    ↓
Create Pull Request
    ↓
Code Review
    ↓
Merge Into Master
```

---

# Design Patterns

### MVC (Model - View - Controller)

Tách biệt xử lý request, dữ liệu và giao diện.

**Lợi ích:**

- Dễ bảo trì và phân công theo role (Customer/Staff/Manager).
- View (JSP) không truy cập DB trực tiếp.
- Controller mỏng, logic DB nằm ở DAL.

---

### DAO Pattern (Data Access Object)

Mỗi bảng/nhóm bảng có một lớp DAO trong package `dal`.

**Lợi ích:**

- Tập trung SQL tại một chỗ (`UserDAO`, `MovieDAO`, …).
- Dễ thay đổi truy vấn mà không ảnh hưởng Servlet.
- Tái sử dụng `DBContext.getConnection()`.

---

### Filter Pattern

Servlet Filter xử lý logic dùng chung trước khi request vào Controller.

**Ví dụ hiện có:**

- `EncodingFilter` — UTF-8 cho toàn bộ request/response.

**Dự kiến thêm:**

- `AuthFilter` — kiểm tra đăng nhập.
- `RoleFilter` — phân quyền CUSTOMER / STAFF / MANAGER / ADMIN.

---

## Architecture

Dự án được xây dựng theo kiến trúc **MVC + DAL**:

```text
Browser
    ↓
Filter (Encoding, Auth, Role)
    ↓
Controller (Servlet)
    ↓
Model (Entity / DTO)
    ↓
DAL (DAO + DBContext)
    ↓
SQL Server (MovieTicketDB)
    ↑
View (JSP) ← forward từ Controller
```

### Controller Layer

- Servlet trong `controller.auth`, `controller.customer`, `controller.staff`, …
- Nhận HTTP request, gọi DAO, set attribute, forward JSP.
- Không viết SQL trực tiếp trong Servlet.

### View Layer

- JSP trong `WEB-INF/views/{role}/`.
- Layout dùng chung: `WEB-INF/views/common/header.jsp`, `footer.jsp`.
- Trang lỗi: `WEB-INF/views/error/404.jsp`, `500.jsp`.

### Model Layer

- `model.entity` — ánh xạ bảng DB (`User`, `Movie`, `Booking`, …).
- `model.dto` — object cho form/request.

### DAL Layer

- `DBContext` — kết nối SQL Server qua `database.properties`.
- `*DAO.java` — CRUD và truy vấn nghiệp vụ.

### Filter Layer

- Xử lý encoding, authentication, authorization toàn cục.

### Utils Layer

- BCrypt, email helper, hằng số dùng chung.

---

# Project Structure

```text
MovieTicketBookingSystem
├── src/main/java/
│   ├── controller/
│   │   ├── auth/              # FR-01 – FR-04
│   │   ├── customer/          # FR-06 – FR-20, FR-43, FR-44
│   │   ├── staff/             # FR-35 – FR-40, FR-42
│   │   ├── manager/           # FR-21 – FR-32, FR-45 – FR-48
│   │   └── admin/
│   ├── model/
│   │   ├── entity/            # Users, Movies, Bookings, …
│   │   └── dto/
│   ├── dal/
│   │   ├── DBContext.java
│   │   └── *DAO.java
│   ├── filter/
│   │   └── EncodingFilter.java
│   └── utils/
├── src/main/webapp/
│   ├── index.jsp
│   ├── css/
│   ├── js/
│   ├── images/
│   └── WEB-INF/
│       ├── web.xml
│       └── views/
│           ├── common/
│           ├── auth/
│           ├── customer/
│           ├── staff/
│           ├── manager/
│           ├── admin/
│           └── error/
├── src/main/resources/
│   ├── database.properties.example   # Trên Git
│   ├── database.properties           # Local only — gitignored
│   ├── database.properties.backup    # Local backup — gitignored
│   ├── email.properties.example      # Trên Git — hướng dẫn Gmail SMTP
│   ├── email.properties              # Local only — gitignored
│   ├── google.properties.example     # Trên Git — hướng dẫn Google OAuth
│   └── google.properties             # Local only — gitignored
├── src/test/java/
├── Database/
│   ├── README.md                    # Hướng dẫn DB & migration cho nhóm
│   ├── create_database.sql          # Khởi tạo đầy đủ 28 bảng + seed
│   └── migrations/                # Script cập nhật schema incremental
│       └── add_system_config_log.sql
├── scripts/
│   ├── setup.bat
│   ├── setup.ps1
│   ├── install-git-hooks.bat
│   ├── backup-database-properties.bat
│   ├── restore-database-properties.bat
│   └── githooks/post-merge
├── pom.xml
└── project_summary_final.md
```

---

## Layer Responsibilities

### Controller (`controller.*`)

- Nhận HTTP Request từ người dùng.
- Gọi DAO tương ứng trong tầng `dal`.
- Set attribute và forward sang JSP, hoặc redirect.
- Không truy cập JDBC trực tiếp.
- Không chứa HTML.

### View (`WEB-INF/views/`)

- Hiển thị dữ liệu cho người dùng.
- Sử dụng JSP + JSTL.
- Không truy vấn database.
- Không xử lý nghiệp vụ phức tạp.

### Model (`model.entity`, `model.dto`)

- Entity ánh xạ cột bảng SQL Server.
- DTO mang dữ liệu form giữa View và Controller.
- Không phụ thuộc Servlet API.

### DAL (`dal`)

- `DBContext` — đọc `database.properties`, cung cấp `Connection`.
- `*DAO` — viết SQL, map `ResultSet` → Entity.
- Không xử lý HTTP hay render JSP.

### Filter (`filter`)

- Chạy trước mọi Servlet.
- Encoding UTF-8, kiểm tra session/role (khi triển khai).

### Resources (`src/main/resources/`)

- `database.properties.example` — mẫu cấu hình DB trên Git.
- `database.properties` — cấu hình thật, **mỗi dev tự tạo local**.
- `email.properties.example` — mẫu Gmail SMTP nhóm; chi tiết: mục **3. Cấu hình Email SMTP** trong README.
- `email.properties` — Gmail + App Password, **mỗi dev tự tạo local**.
- `google.properties.example` — mẫu Google OAuth nhóm; chi tiết: mục **4. Cấu hình Google OAuth** trong README.
- `google.properties` — Client ID/Secret + redirect URI, **mỗi dev tự tạo local**.

### Database (`Database/`)

- `create_database.sql` — tạo `MovieTicketDB`, **28 bảng** + seed.
- `migrations/` — script cập nhật cho DB đã tồn tại (sau `git pull`).
- Chi tiết: [`Database/README.md`](Database/README.md).

---

## Quy ước khi code feature mới

1. **Entity** → `model.entity.User`
2. **DAO** → `dal.UserDAO` (dùng `DBContext.getConnection()`)
3. **Servlet** → `controller.auth.LoginServlet` với `@WebServlet("/login")`
4. **JSP** → `WEB-INF/views/auth/login.jsp`
5. **Forward:**

```java
request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
```

---

## Design Principles

- Separation of Concerns (SoC)
- Model - View - Controller (MVC)
- DAO Pattern
- Filter Pattern cho cross-cutting concerns
- Cấu hình local tách khỏi source code (`.properties` + `.gitignore`)
- Naming nhất quán: PascalCase bảng DB, snake_case cột DB

