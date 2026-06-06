# Movie Ticket Booking System

Hệ thống đặt vé xem phim — **Java 17 · JSP/Servlet · SQL Server · Maven · Tomcat 10**.

> Chi tiết nghiệp vụ, schema 26 bảng và 50 FR: `[project_summary_final.md](project_summary_final.md)`

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
- **26 bảng** đặt tên **PascalCase** (`Users`, `Bookings`, `Movies`, …)
- Script khởi tạo: `Database/create_database.sql`

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

## Clone và chạy nhanh (3 bước)

### Bước 1 — Cấu hình database local

File cấu hình kết nối SQL Server nằm tại `src/main/resources/database.properties`. File này **chỉ tồn tại trên máy bạn** — không đưa lên Git (chỉ có `database.properties.example` trên repo).

#### Các script hỗ trợ (`scripts/`)

| Script | Chạy khi nào | Tác dụng |
|--------|--------------|----------|
| `install-git-hooks.bat` | **Một lần** sau khi clone | Cài hook Git — tự khôi phục `database.properties` sau mỗi `git pull` |
| `setup.bat` | Lần đầu / khi chưa có file config | Copy `.example` → `database.properties` (không ghi đè nếu đã có) |
| `setup.ps1` | Tương đương `setup.bat` | Dùng trong PowerShell |
| `backup-database-properties.bat` | **Trước** `git pull` | Lưu bản sao → `database.properties.backup` (gitignored) |
| `restore-database-properties.bat` | **Sau** `git pull` / khi file bị mất | Khôi phục từ `.backup`, hoặc tạo từ `.example` nếu chưa có backup |

PowerShell tương ứng: `.\scripts\setup.ps1`

---

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

### Bước 2 — Tạo database và bảng

1. Bật SQL Server, bật **SQL Server Authentication** cho user `sa` (nếu dùng `sa`).
2. Mở `Database/create_database.sql` trong SSMS hoặc Azure Data Studio.
3. Chạy **một file duy nhất** `Database/create_database.sql` (Ctrl+A → F5) → tạo database `MovieTicketDB`, **26 bảng** và **toàn bộ seed data** (users, phim homepage, genres, …). Không cần chạy thêm file migration nào khác.

Đảm bảo `db.name` trong `database.properties` trùng tên DB trong script:

```properties
db.name=MovieTicketDB
```

**Tài khoản seed** (sau khi chạy script): mật khẩu mặc định `Password@123` (BCrypt).

---

### Bước 3 — Build và deploy

```bash
mvn clean package
```

Deploy file WAR lên Tomcat 10:

```text
target/MovieTicketBookingSystem-1.0-SNAPSHOT.war
```

---

## Xử lý lỗi thường gặp


| Lỗi                           | Cách xử lý                                                   |
| ----------------------------- | ------------------------------------------------------------ |
| `Missing database.properties` | Chạy `scripts\restore-database-properties.bat` hoặc `scripts\setup.bat` |
| Pull xong mất `database.properties` | `backup` → pull → `restore` (xem **Bước 1 — mục B**) |
| Login failed for user `sa`    | Kiểm tra mật khẩu, bật Mixed Mode trong SQL Server           |
| Cannot open database          | Chạy `create_database.sql` hoặc sửa `db.name` cho khớp       |
| Driver not found              | `mvn clean package` để tải dependency JDBC                   |
| Tiếng Việt bị lỗi trên form   | Kiểm tra `EncodingFilter` và `pageEncoding="UTF-8"` trên JSP |


---

## Checklist thành viên mới

- [ ] Clone repo
- [ ] `scripts\install-git-hooks.bat` (một lần)
- [ ] `scripts\setup.bat` → sửa `db.server`, `db.password`
- [ ] `scripts\backup-database-properties.bat`
- [ ] Chạy `Database/create_database.sql`
- [ ] `mvn clean package` (hoặc Build trong IDE)
- [ ] Cấu hình Tomcat 10 và chạy WAR

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

* `<pic>` — mã thành viên (vd: `morgan`, `khiemnx`, `minhnt`, `gialong`).
* `<task-name>` — mô tả công việc, dùng **kebab-case** (chữ thường, nối bằng dấu `-`).

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
```

### Không được push lên repository

- File build (`target/`, `*.war`, `*.class`).
- File cấu hình IDE (`.idea/`, `*.iml`).
- `**database.properties**` — chứa server name và mật khẩu SQL cá nhân.

### Cấu hình database đúng cách


| File                          | Trên Git? | Mục đích                |
| ----------------------------- | --------- | ----------------------- |
| `database.properties.example` | Có        | Mẫu cấu hình cho team   |
| `database.properties`         | **Không** | Cấu hình local từng máy |
| `database.properties.backup`  | **Không** | Backup local trước/sau pull |


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

Chi tiết đầy đủ: mục **Getting Started → Bước 1**.

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
│   └── database.properties.backup    # Local backup — gitignored
├── src/test/java/
├── Database/
│   └── create_database.sql
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

### Database (`Database/`)

- Script tạo database `MovieTicketDB`.
- 26 bảng PascalCase + seed data mẫu.

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

