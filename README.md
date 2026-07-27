# Movie Ticket Booking System

Hệ thống đặt vé xem phim — **Java 17 · JSP/Servlet · SQL Server · Maven · Tomcat 10**.

> Chi tiết nghiệp vụ, schema **28 bảng** và 50 FR: `[project_summary_final.md](project_summary_final.md)`  
> Module Admin (tính năng đã triển khai): `[ADMIN_MODULE_DETAIL.md](ADMIN_MODULE_DETAIL.md)`  
> Hướng dẫn Database & migration cho nhóm: `[Database/README.md](Database/README.md)`

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
- **30 bảng** đặt tên **PascalCase** (`Users`, `Bookings`, `Movies`, `PendingRegistrations`, `SystemConfigLog`, …)
- Schema: `Database/create_database.sql` — seed: `Database/seed_data.sql` (đã gộp mọi migration vào schema)
- DB cũ không reset được: xem `[Database/migrations/README.md](Database/migrations/README.md)`
- Chi tiết: `[Database/README.md](Database/README.md)`

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


| Bước  | Việc cần làm | Bắt buộc? | Tài liệu |
| ----- | ------------ | --------- | -------- |
| **0** | Clone repo + cài Git hook (`scripts\install-git-hooks.bat`) | Có (một lần) | Bên dưới |
| **1** | `database.properties` + `create_database.sql` rồi `seed_data.sql` | Có | [1. Cấu hình Database](#1-cấu-hình-database) |
| **2** | `mvn clean package` + deploy Tomcat 10 | Có | [2. Build và deploy](#2-build-và-deploy) |
| **3** | `email.properties` (SMTP nhóm + `app.base.url` máy bạn) | Cần nếu đăng ký / quên MK / mail vé | [3. Cấu hình Email SMTP](#3-cấu-hình-email-smtp) |
| **4** | `google.properties` (Client nhóm + `redirect.uri` máy bạn) | Cần nếu đăng nhập Google | [4. Cấu hình Google OAuth](#4-cấu-hình-google-oauth) |
| **5** | VietQR (+ SePay/ngrok nếu tự xác nhận) | Cần nếu thanh toán online | [Mục 5](#5-thanh-toán-online-vietqr--sepay) — **5.1** VietQR; **5.3→5.9** ngrok+SePay |


> **Lần đầu clone — chạy được web ngay:** làm **0 → 1 → 2**, rồi mở URL Tomcat (vd. `http://localhost:8080/MovieTicketBookingSystem_war_exploded/`). Đăng nhập seed: `customer.adult@email.com` / `Password@123` (hoặc admin/manager/staff cùng mật khẩu).  
> Bước **3 → 4** lấy secret từ admin nhóm (`epcine88@gmail.com`); mỗi máy sửa **URL Tomcat**.  
> Bước **5**: VietQR đủ để thanh toán thủ công; **tự xác nhận** cần SePay + **ngrok** (mục **5.3 → 5.9**).  
> `scripts\setup.bat` **chỉ** tạo `database.properties` — các file `email` / `google` / `vietqr` / `sepay` phải copy từ `.example` thủ công.

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
2. Chạy lần lượt trong SSMS / Azure Data Studio (mỗi file Ctrl+A → F5):
   1. [`Database/create_database.sql`](Database/create_database.sql) → `MovieTicketDB` + **30 bảng** + index
   2. [`Database/seed_data.sql`](Database/seed_data.sql) → Roles, users, phim, voucher, đơn mẫu…
3. **Không cần** chạy gì trong `Database/migrations/` — mọi thay đổi schema đã nằm trong `create_database.sql`.

Đảm bảo `db.name` trong `database.properties` trùng tên DB:

```properties
db.name=MovieTicketDB
```

**Tài khoản seed** (mật khẩu chung `Password@123`):

| Role | Email |
|------|-------|
| ADMIN | `admin@movieticket.vn` |
| MANAGER | `manager@movieticket.vn` |
| STAFF | `staff@movieticket.vn` |
| CUSTOMER (≥18) | `customer.adult@email.com` |
| CUSTOMER (teen) | `customer.teen@email.com` |

Chi tiết: `[Database/README.md](Database/README.md)`.

#### Đã có DB cũ — sau `git pull`

- **Dev / có thể mất data:** chạy lại `create_database.sql` rồi `seed_data.sql` — cách nhanh nhất, đủ schema + seed.
- **Phải giữ data:** xem `[Database/migrations/README.md](Database/migrations/README.md)` và chỉ chạy file legacy còn thiếu.

---

## 2. Build và deploy

```bash
mvn clean package
```

Deploy file WAR lên Tomcat 10:

```text
target/MovieTicketBookingSystem-1.0-SNAPSHOT.war
```

**IntelliJ:** Run → Edit Configurations → **Tomcat Server (Local)** → Deployment → thêm artifact **WAR** hoặc **WAR exploded** → Run.

URL thường gặp (xem tab Deployment / Application context):

```text
http://localhost:8080/MovieTicketBookingSystem_war_exploded/
http://localhost:8080/MovieTicketBookingSystem/
```

Sau bước **1 + 2**, trang chủ / đăng nhập seed đã dùng được. Tiếp tục mục **3–5** khi cần đăng ký email, Google login, hoặc thanh toán VietQR.

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
mail.from.name=\u00C9PCINE
```


| Key                         | Giá trị nhóm                      | Ghi chú                                                             |
| --------------------------- | --------------------------------- | ------------------------------------------------------------------- |
| `mail.smtp.host`            | `smtp.gmail.com`                  | Server Gmail — **không sửa**                                        |
| `mail.smtp.port`            | `587`                             | Cổng TLS — **không sửa**                                            |
| `mail.smtp.auth`            | `true`                            | Bật đăng nhập SMTP — **không sửa**                                  |
| `mail.smtp.starttls.enable` | `true`                            | Mã hóa STARTTLS — **không sửa**                                     |
| `mail.smtp.username`        | `epcine88@gmail.com`              | Gmail gửi mail — **giống cả nhóm**                                  |
| `mail.smtp.password`        | *(lấy từ admin qua Zalo/Discord)* | **App Password** 16 ký tự — **không** phải mật khẩu đăng nhập Gmail |
| `mail.from`                 | `epcine88@gmail.com`              | Địa chỉ hiển thị người gửi                                          |
| `mail.from.name`            | `ÉPCINE`                          | Tên hiển thị: `ÉPCINE <epcine88@gmail.com>`                         |


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
mail.from.name=\u00C9PCINE
app.base.url=http://localhost:9999/MovieTicketBookingSystem_war_exploded
```

Dòng cuối (`app.base.url`) — **sửa theo Tomcat trên máy bạn**.

---

### 3.5. Rebuild và kiểm tra gửi mail

1. IntelliJ: **Build → Rebuild Project**
2. **Restart Tomcat** (icon restart cạnh nút Run)
3. Mở `/register` → đăng ký tài khoản mới (email **chưa có** trong DB)
4. Kiểm tra hộp thư (kể cả **Spam**)


| Kết quả                                  | Ý nghĩa                                                               |
| ---------------------------------------- | --------------------------------------------------------------------- |
| Trang pending báo **đã gửi email**       | SMTP đúng                                                             |
| Trang pending hiện **link xác thực dev** | SMTP chưa đúng — vẫn tạo được tài khoản, dùng link trên trang để test |
| Link trong mail mở **404**               | Sửa `app.base.url` cho khớp URL Tomcat                                |


---

### 3.6. Lỗi thường gặp (email)


| Lỗi                                | Cách xử lý                                                        |
| ---------------------------------- | ----------------------------------------------------------------- |
| `535 Authentication failed`        | Kiểm tra App Password; không dùng mật khẩu đăng nhập Gmail thường |
| Không nhận mail                    | Xem **Spam**; Rebuild + Restart Tomcat                            |
| Link verify `localhost:<PORT>/...` | Chưa điền `app.base.url` — sửa theo mục **3.3**                   |
| Sửa file không có hiệu lực         | **Rebuild Project** + **Restart Tomcat**                          |


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


| Key                    | Giá trị nhóm                      |
| ---------------------- | --------------------------------- |
| `google.client.id`     | *(lấy từ admin qua Zalo/Discord)* |
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


| Kết quả                                | Ý nghĩa                                                         |
| -------------------------------------- | --------------------------------------------------------------- |
| Vào trang chủ                          | Gmail đã có trong DB                                            |
| Form hoàn tất Google (ngày sinh + SĐT) | Gmail mới — điền form rồi vào hệ thống                          |
| `redirect_uri_mismatch`                | Sai `google.redirect.uri` hoặc chưa add URL trên Console        |
| Trang **404** styled                   | Chưa có / sai `google.properties` — app coi OAuth chưa cấu hình |
| `invalid_client`                       | Kiểm tra lại Client ID / Secret                                 |


---

### 4.6. Lỗi thường gặp (Google OAuth)


| Lỗi                        | Cách xử lý                                                            |
| -------------------------- | --------------------------------------------------------------------- |
| `redirect_uri_mismatch`    | Sửa `google.redirect.uri`; nhờ admin thêm URL callback trên Console   |
| `invalid_client`           | Copy lại ID/Secret từ mục **4.2**                                     |
| Google chặn app (Testing)  | Admin thêm Gmail của bạn vào **Test users** trên OAuth consent screen |
| Sửa file không có hiệu lực | Rebuild + Restart Tomcat                                              |


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


| Mục                                        | Cả nhóm giống nhau? | Ghi chú                               |
| ------------------------------------------ | ------------------- | ------------------------------------- |
| SMTP host/port/auth/starttls               | **Có**              | Gmail mặc định                        |
| `mail.smtp.username` / `password` / `from` | **Có**              | `epcine88@gmail.com`                  |
| `mail.from.name`                           | **Có**              | `ÉPCINE`                              |
| `app.base.url`                             | **Không**           | URL Tomcat từng máy                   |
| `google.client.id` / `secret`              | **Có**              | OAuth client nhóm                     |
| `google.redirect.uri`                      | **Không**           | Gửi admin để add trên Console nếu cần |


---

## 5. Thanh toán online (VietQR + SePay)

Thanh toán online dùng **VietQR** (bắt buộc để hiện QR) và tùy chọn **SePay** (webhook tự xác nhận khi tiền vào).

| Thành phần | Bắt buộc? | File |
| ---------- | --------- | ---- |
| VietQR | Có (để tạo QR) | `vietqr.properties` |
| SePay + ngrok | Không — chỉ khi muốn **tự xác nhận** | `sepay.properties` + tunnel HTTPS |

Không có SePay: khách vẫn bấm **Tôi đã chuyển khoản** để hoàn tất.

> File thật **không commit** Git. Repo chỉ có `.example`.

---

### 5.1. Cấu hình VietQR (làm trước)

Tại thư mục gốc project (nơi có `pom.xml`):

```bat
copy src\main\resources\vietqr.properties.example src\main\resources\vietqr.properties
```

Mở `src/main/resources/vietqr.properties`, điền:

| Key | Ý nghĩa | Ví dụ |
| --- | ------- | ----- |
| `vietqr.bank.bin` | Mã BIN Napas | `970422` (MB) |
| `vietqr.bank.name` | Tên ngân hàng hiển thị | `MB Bank` |
| `vietqr.account.number` | STK nhận tiền (chỉ số) | `0123456789` |
| `vietqr.account.name` | Chủ TK (hoa, không dấu) | `NGUYEN VAN A` |
| `vietqr.template` | Kiểu ảnh QR | `compact2` |

Tra BIN: [vietqr.io](https://vietqr.io/) hoặc [api.vietqr.io/v2/banks](https://api.vietqr.io/v2/banks).

**Rebuild + Restart Tomcat.** Mở `/payment` → nút tạo QR phải **bật** (không xám).

> Nhóm có thể dùng chung một STK test; mỗi người copy cùng giá trị vào máy mình.

---

### 5.2. SePay + ngrok — khi nào cần?

SePay gọi **server-to-server** vào app của bạn. Trình duyệt mở `localhost` **không** đủ — SePay cần URL **HTTPS công khai**.

Trên máy local → dùng **ngrok** để lộ Tomcat ra internet tạm thời.

```text
[Khách quét VietQR / SePay Test]
        ↓ tiền vào (hoặc mô phỏng)
[SePay cloud]
        ↓ POST HTTPS
[ngrok] → [Tomcat máy bạn] → /payment/sepay/webhook
        ↓
[App xác nhận đơn + phát vé] → trang poll → /payment/success
```

Docs SePay: [Tích hợp webhooks](https://docs.sepay.vn/tich-hop-webhooks.html) · [Developer](https://developer.sepay.vn/vi)

---

### 5.3. Cài ngrok (Windows) — làm 1 lần

#### 5.3.1. Tải và giải nén

1. Vào [https://ngrok.com/download](https://ngrok.com/download) → chọn **Windows**.
2. Giải nén `ngrok.exe` vào thư mục cố định, ví dụ:

```text
C:\Tools\ngrok\ngrok.exe
```

3. (Tuỳ chọn) Thêm thư mục đó vào **PATH** hệ thống để gõ `ngrok` ở mọi cửa sổ CMD/PowerShell.

#### 5.3.2. Đăng ký tài khoản + Authtoken

1. Đăng ký / đăng nhập [https://dashboard.ngrok.com](https://dashboard.ngrok.com) (gói free đủ dùng).
2. Vào **Your Authtoken** (hoặc [https://dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)).
3. Copy token → chạy **một lần** trên máy:

```bat
ngrok config add-authtoken <DÁN_TOKEN_CỦA_BẠN>
```

Thành công sẽ có dòng kiểu `Authtoken saved to configuration file`.

#### 5.3.3. Kiểm tra ngrok chạy được

```bat
ngrok version
```

Nếu báo không tìm thấy lệnh → dùng full path:

```bat
C:\Tools\ngrok\ngrok.exe version
```

---

### 5.4. Mỗi lần test SePay — Tomcat + tunnel ngrok

#### 5.4.1. Xác định port và context path Tomcat

Trong IntelliJ: **Run → Edit Configurations → Tomcat**

| Mục | Cách lấy | Ví dụ |
| --- | -------- | ----- |
| **Port HTTP** | Tomcat Server → Server → HTTP port | `8080` hoặc `9999` |
| **Context path** | Deployment → Application context | `/MovieTicketBookingSystem_war_exploded` hoặc `/MovieTicketBookingSystem` |

URL app trên máy bạn thường là:

```text
http://localhost:<PORT><CONTEXT_PATH>/
```

Ví dụ:

```text
http://localhost:8080/MovieTicketBookingSystem_war_exploded/
```

#### 5.4.2. Chạy app trước

1. Start Tomcat trong IntelliJ.
2. Mở URL local ở trên — trang chủ phải load được.
3. **Giữ Tomcat chạy** trong suốt lúc test webhook.

#### 5.4.3. Mở tunnel ngrok

Mở **CMD / PowerShell mới** (để chạy song song với Tomcat), gõ đúng **port HTTP** của bạn:

```bat
ngrok http 8080
```

Nếu Tomcat dùng port `9999`:

```bat
ngrok http 9999
```

Cửa sổ ngrok hiện bảng tương tự:

```text
Forwarding    https://lash-enlarging-stainable.ngrok-free.dev -> http://localhost:8080
```

- Phần `https://….ngrok-free.dev` = **NGROK_HOST** (không có `/` cuối).
- Gói free: mỗi lần tắt/mở ngrok, host **đổi** → phải cập nhật lại URL webhook trên SePay.

Để mở dashboard ngrok trên trình duyệt: [http://127.0.0.1:4040](http://127.0.0.1:4040) (xem request vào tunnel).

#### 5.4.4. Kiểm tra tunnel mở được app

Ghép:

```text
https://<NGROK_HOST><CONTEXT_PATH>/
```

Ví dụ:

```text
https://lash-enlarging-stainable.ngrok-free.dev/MovieTicketBookingSystem_war_exploded/
```

Mở URL đó trên trình duyệt:

- Lần đầu ngrok free có thể hiện trang cảnh báo → bấm **Visit Site**.
- Sau đó phải thấy trang chủ ÉPCINE giống `localhost`.

Nếu **502 / connection refused**: Tomcat chưa chạy hoặc `ngrok http` sai port.

Kiểm tra endpoint webhook (PowerShell — bỏ qua trang cảnh báo ngrok):

```powershell
curl.exe -sS -H "ngrok-skip-browser-warning: true" "https://<NGROK_HOST><CONTEXT_PATH>/payment/sepay/webhook"
```

Servlet có thể trả lỗi method/body (vì cần POST + JSON) — quan trọng là **không 404** (đúng context path).

---

### 5.5. Tạo file `sepay.properties`

```bat
copy src\main\resources\sepay.properties.example src\main\resources\sepay.properties
```

Mở `sepay.properties`, điền tối thiểu:

```properties
sepay.enabled=true
sepay.webhook.api.key=<API_KEY_BẠN_TẠO_TRÊN_SEPAY>

# Tuỳ chọn — nên trùng vietqr.account.number
# sepay.account.number=0123456789
```

| Key | Bắt buộc | Ghi chú |
| --- | -------- | ------- |
| `sepay.enabled` | Có | `true` để bật tự xác nhận |
| `sepay.webhook.api.key` | Có khi bật | Khớp header SePay gửi: `Authorization: Apikey <key>` |
| `sepay.account.number` | Không | Để trống = không lọc STK; có thì phải khớp số tài khoản trong payload |

> Chưa có API Key thì để placeholder rồi làm mục **5.6** trước, sau đó quay lại điền key + Rebuild.

---

### 5.6. Cấu hình webhook trên SePay (portal)

1. Đăng nhập [https://my.sepay.vn](https://my.sepay.vn) (hoặc môi trường **Test mode** theo hướng dẫn SePay).
2. Vào mục **Webhooks** / tích hợp webhook (xem [docs](https://docs.sepay.vn/tich-hop-webhooks.html)).
3. Tạo webhook mới:
   - **URL** (full path, HTTPS, **không** `/` cuối):

```text
https://<NGROK_HOST><CONTEXT_PATH>/payment/sepay/webhook
```

Ví dụ đúng:

```text
https://lash-enlarging-stainable.ngrok-free.dev/MovieTicketBookingSystem_war_exploded/payment/sepay/webhook
```

Ví dụ sai thường gặp:

```text
https://….ngrok-free.dev/payment/sepay/webhook          ← thiếu context path
https://….ngrok-free.dev/.../payment/sepay/webhook/     ← thừa /
http://localhost:8080/.../payment/sepay/webhook         ← SePay không gọi được localhost
```

4. Kiểu chứng thực: **API Key**.
5. Copy API Key → dán vào `sepay.webhook.api.key` trong `sepay.properties`.
6. Lưu webhook trên portal.
7. **Rebuild + Restart Tomcat** (để nạp `sepay.properties`).

> **Một webhook URL tại một thời điểm trên portal.** Khi bạn test: báo nhóm → cập nhật URL = ngrok **máy bạn**. Không nên 2 người test webhook cùng lúc với 1 tài khoản SePay.

> Mỗi lần restart ngrok (host đổi): sửa lại URL webhook trên SePay cho khớp host mới.

---

### 5.7. Test end-to-end (SePay tự xác nhận)

**Điều kiện:** Tomcat chạy, ngrok online, `vietqr.properties` + `sepay.properties` đúng, URL webhook trên SePay khớp ngrok.

1. Login seed: `customer.adult@email.com` / `Password@123`.
2. Chọn phim → suất → ghế → **Tiếp tục thanh toán**.
3. Trên `/payment`: tạo QR VietQR.
4. Khi `sepay.enabled=true`, trang hiện dòng chờ SePay (poll `/payment/status`).
5. Thực hiện một trong hai:
   - **Test mode / mô phỏng** trên SePay (nếu portal hỗ trợ) — gửi webhook giả lập khớp **số tiền** + **nội dung CK** (mã đơn / transfer content trên QR).
   - **Live:** chuyển khoản thật đúng STK + số tiền + nội dung CK.
6. Kỳ vọng: trang tự chuyển `/payment/success`, DB `Payments` = `VIETQR`/`SUCCESS`, có `Tickets`, email xác nhận (nếu đã cấu hình mục **3**).
7. Xem log Tomcat / ngrok dashboard (`127.0.0.1:4040`) nếu không khớp.

**Fallback:** nếu webhook lỗi — vẫn dùng nút xác nhận thủ công trên trang QR.

---

### 5.8. Lỗi thường gặp (ngrok / SePay)


| Hiện tượng | Nguyên nhân / cách xử lý |
| ---------- | ------------------------ |
| Ngrok `ERR_NGROK_4018` / chưa auth | Chạy lại `ngrok config add-authtoken …` |
| `502 Bad Gateway` qua ngrok | Tomcat chưa chạy hoặc `ngrok http` sai port |
| Mở URL ngrok ra 404 app | Sai **context path** (`_war_exploded` vs không) |
| Trang cảnh báo ngrok free | Bấm Visit Site; webhook server-to-server thường không bị chặn như trình duyệt |
| SePay không gọi được | URL webhook dùng `http://localhost` — phải HTTPS ngrok |
| Webhook 401 / invalid API key | `sepay.webhook.api.key` ≠ key trên portal; thiếu prefix `Apikey ` phía SePay (app đã hỗ trợ) |
| Webhook OK nhưng đơn không paid | Sai **số tiền** hoặc **nội dung CK** so với payment PENDING; xem log `NO MATCH` |
| Host ngrok đổi sau khi tắt | Cập nhật lại URL trên SePay portal |
| Nút QR disabled | Chưa có / sai `vietqr.properties` → mục **5.1** |
| SePay không “tự” dù đã cấu hình | `sepay.enabled` không phải `true`, hoặc chưa Restart Tomcat sau khi sửa properties |


> Không commit `vietqr.properties` / `sepay.properties` lên Git.

---

### 5.9. Checklist nhanh — SePay lần đầu

```text
[ ] 5.1  vietqr.properties → Rebuild → QR bật trên /payment
[ ] 5.3  Cài ngrok + authtoken
[ ] 5.4  Tomcat chạy + ngrok http <PORT> + mở được app qua HTTPS ngrok
[ ] 5.5  copy sepay.properties.example → sepay.properties
[ ] 5.6  Tạo webhook SePay (API Key) = https://<NGROK>/<CONTEXT>/payment/sepay/webhook
[ ] 5.5  Dán API Key vào sepay.webhook.api.key, enabled=true → Rebuild + Restart
[ ] 5.7  Test đặt vé → QR → webhook / Test mode → /payment/success
```

**Mỗi lần test lại sau khi tắt máy:**

```text
[ ] Start Tomcat
[ ] ngrok http <PORT>  → copy host mới
[ ] Cập nhật URL webhook trên SePay cho khớp host mới
[ ] Test lại luồng thanh toán
```

---

## Xử lý lỗi thường gặp


| Lỗi                                      | Cách xử lý                                                              |
| ---------------------------------------- | ----------------------------------------------------------------------- |
| `Missing database.properties`            | Chạy `scripts\restore-database-properties.bat` hoặc `scripts\setup.bat` |
| Pull xong mất `database.properties`      | `backup` → pull → `restore` (xem mục **1 — B**)                         |
| Login failed for user `sa`               | Kiểm tra mật khẩu, bật Mixed Mode trong SQL Server                      |
| Cannot open database                     | Chạy `create_database.sql` hoặc sửa `db.name` cho khớp                  |
| Thiếu bảng / constraint sau pull         | Chạy lại `create_database.sql` (reset), hoặc xem `Database/migrations/README.md` |
| Trang admin thiếu lịch sử loyalty        | DB cũ thiếu `SystemConfigLog` — sync theo `Database/README.md`          |
| Driver not found                         | `mvn clean package` để tải dependency JDBC                              |
| Tiếng Việt bị lỗi trên form              | Kiểm tra `EncodingFilter` và `pageEncoding="UTF-8"` trên JSP            |
| `535 Authentication failed` (email)      | Kiểm tra App Password Gmail, không dùng mật khẩu đăng nhập thường       |
| Link xác thực email bị 404               | Sửa `app.base.url` trong `email.properties` cho khớp URL Tomcat         |
| `redirect_uri_mismatch` (Google)         | Sửa `google.redirect.uri`; nhờ admin thêm URL callback trên Console     |
| VietQR không hiện QR / nút disabled      | Tạo/điền `vietqr.properties` → Rebuild + Restart                        |
| SePay không tự xác nhận                  | Mục **5.3–5.8**: ngrok online, URL webhook khớp host+context, API Key, Restart Tomcat |
| `502` qua URL ngrok                      | Tomcat chưa chạy hoặc `ngrok http` sai port (mục **5.4**)                               |
| Ngrok 404 app / webhook                  | Sai context path (`_war_exploded`…) — mục **5.4.1 / 5.6**                               |


---

## Checklist thành viên mới (lần đầu clone)

Làm **theo thứ tự**. Sau bước 2 web đã chạy; 3–5 chỉ khi cần tính năng tương ứng.

```text
[ ] Clone repo về máy
[ ] scripts\install-git-hooks.bat
[ ] scripts\setup.bat
[ ] Sửa src/main/resources/database.properties → db.server, db.password (db.name=MovieTicketDB)
[ ] SSMS: chạy Database/create_database.sql rồi Database/seed_data.sql
[ ] scripts\backup-database-properties.bat
[ ] mvn clean package
[ ] IntelliJ: Tomcat 10 + deploy WAR/WAR exploded → Run
[ ] Mở URL context path máy bạn → login seed (vd. customer.adult@email.com / Password@123)

--- Khi cần đăng ký / mail ---
[ ] copy email.properties.example → email.properties
[ ] Copy SMTP nhóm từ admin; sửa app.base.url = URL Tomcat máy bạn (mục 3)
[ ] Rebuild + Restart → thử đăng ký / quên mật khẩu

--- Khi cần Google login ---
[ ] copy google.properties.example → google.properties
[ ] Copy Client ID/Secret nhóm; sửa google.redirect.uri (mục 4)
[ ] Nhờ admin thêm redirect URI trên Google Console nếu máy bạn port/context khác
[ ] Rebuild + Restart → thử Đăng nhập với Google

--- Khi cần thanh toán VietQR ---
[ ] copy vietqr.properties.example → vietqr.properties → điền STK (mục 5.1)
[ ] (Tuỳ chọn SePay tự xác nhận) làm checklist mục 5.9: ngrok + webhook + sepay.properties
[ ] Rebuild + Restart → đặt ghế → /payment → tạo QR → test thủ công hoặc SePay
```

> Trước mỗi lần `git pull`: `backup-database-properties.bat` → pull → `restore-database-properties.bat`  
> Nếu pull có schema mới: ưu tiên chạy lại `create_database.sql` (reset). DB cũ giữ data → `Database/migrations/README.md`.

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
**/vietqr.properties
!**/vietqr.properties.example
**/sepay.properties
!**/sepay.properties.example
```

### Không được push lên repository

- File build (`target/`, `*.war`, `*.class`).
- File cấu hình IDE (`.idea/`, `*.iml`).
- `**database.properties**` — chứa server name và mật khẩu SQL cá nhân.
- `**email.properties**` — chứa Gmail và App Password SMTP.
- `**google.properties**` — chứa Google OAuth Client Secret.
- `**vietqr.properties**` / `**sepay.properties**` — STK / API Key webhook local.

### Cấu hình database đúng cách


| File                          | Trên Git? | Mục đích                       |
| ----------------------------- | --------- | ------------------------------ |
| `database.properties.example` | Có        | Mẫu cấu hình cho team          |
| `database.properties`         | **Không** | Cấu hình local từng máy        |
| `database.properties.backup`  | **Không** | Backup local trước/sau pull    |
| `email.properties.example`    | Có        | Mẫu hướng dẫn Gmail SMTP       |
| `email.properties`            | **Không** | Gmail + App Password local     |
| `google.properties.example`   | Có        | Mẫu hướng dẫn Google OAuth     |
| `google.properties`           | **Không** | Client ID/Secret local         |
| `vietqr.properties.example`   | Có        | Mẫu hướng dẫn VietQR           |
| `vietqr.properties`           | **Không** | STK nhận tiền local            |
| `sepay.properties.example`    | Có        | Mẫu hướng dẫn SePay webhook    |
| `sepay.properties`            | **Không** | API Key webhook local          |


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
│   ├── README.md                    # Hướng dẫn DB
│   ├── create_database.sql          # Schema only — 30 bảng + index (đã gộp migrations)
│   ├── seed_data.sql                # Seed mặc định (users, phim, SEED-STATS-*)
│   ├── seed_showtime_load_test.sql  # Tuỳ chọn load-test suất chiếu
│   └── migrations/                  # Legacy — chỉ DB cũ không reset được
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
- `vietqr.properties.example` — mẫu VietQR; chi tiết: mục **5** trong README.
- `vietqr.properties` / `sepay.properties` — STK + SePay API Key, **mỗi dev tự tạo local**.

### Database (`Database/`)

- `create_database.sql` — tạo `MovieTicketDB`, **30 bảng** + index (schema only).
- `seed_data.sql` — dữ liệu mẫu (Roles, users, phim, voucher, đơn báo cáo…).
- `migrations/` — legacy cho DB cũ; xem `migrations/README.md`.
- Chi tiết: `[Database/README.md](Database/README.md)`.

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

