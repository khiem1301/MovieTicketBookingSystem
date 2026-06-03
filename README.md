# Movie Ticket Booking System

Hệ thống đặt vé xem phim — Java 17 · JSP/Servlet · SQL Server · Maven.

## Yêu cầu

| Công cụ | Phiên bản gợi ý |
|---------|------------------|
| JDK | 17+ |
| Maven | 3.9+ (hoặc dùng Maven tích hợp trong IntelliJ) |
| SQL Server | 2019+ (Express được) |
| Tomcat | 10.1+ (Jakarta EE 10) |

## Clone và chạy nhanh (3 bước)

### Bước 1 — Cấu hình database local

```bat
scripts\setup.bat
```

Hoặc PowerShell: `.\scripts\setup.ps1`

Sau đó mở `src/main/resources/database.properties` và sửa **2 dòng** (thường chỉ cần vậy):

```properties
db.server=TEN_MAY_SQL_CUA_BAN
db.password=MAT_KHAU_SA_CUA_BAN
```

> File `database.properties` **không** đưa lên Git (mỗi người một cấu hình). Trên repo chỉ có `database.properties.example` làm mẫu.

### Bước 2 — Tạo database và bảng

1. Bật SQL Server, bật **SQL Server Authentication** cho user `sa` (nếu dùng `sa`).
2. Mở `Database/create_database.sql` trong SSMS hoặc Azure Data Studio.
3. Chạy toàn bộ script → tạo database `MovieTicketDB` và 26 bảng.

Đảm bảo `db.name` trong `database.properties` trùng tên DB trong script (`MovieTicketDB`).

### Bước 3 — Build và deploy

```bash
mvn clean package
```

File WAR: `target/MovieTicketBookingSystem-1.0-SNAPSHOT.war`

Deploy lên Tomcat 10, truy cập: `http://localhost:8080/MovieTicketBookingSystem/`

**IntelliJ IDEA:** Run → Edit Configurations → thêm **Tomcat Server (Local)** → Deployment → thêm artifact WAR → Run.

---

## Cấu trúc thư mục chính

```
src/main/java/dal/          # DBContext, DAO
src/main/resources/         # database.properties (local, gitignored)
src/main/webapp/            # JSP, web.xml
Database/create_database.sql
scripts/setup.bat           # Tạo database.properties từ mẫu
```

## Xử lý lỗi thường gặp

| Lỗi | Cách xử lý |
|-----|------------|
| `Missing database.properties` | Chạy `scripts\setup.bat` |
| Login failed for user `sa` | Kiểm tra mật khẩu, bật Mixed Mode trong SQL Server |
| Cannot open database | Chạy `create_database.sql` hoặc sửa `db.name` cho khớp |
| Driver not found | `mvn clean package` để tải dependency JDBC |

## Thành viên mới — checklist

- [ ] Clone repo
- [ ] Chạy `scripts\setup.bat`, sửa `db.server` và `db.password`
- [ ] Chạy `Database/create_database.sql`
- [ ] `mvn clean package` (hoặc Build trong IDE)
- [ ] Cấu hình Tomcat 10 và chạy WAR

## Tài liệu dự án

Chi tiết nghiệp vụ và schema: `project_summary_final.md`
