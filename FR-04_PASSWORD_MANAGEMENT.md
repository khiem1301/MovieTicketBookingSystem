# FR-04 — Password Management (Quản lý mật khẩu)

> **PIC:** Gia Long (`gialong`)  
> **Branch:** `gialong/password-management`  
> **Spec:** `project_summary_final.md` — FR-04  
> **Liên quan:** FR-01 (token đăng ký), FR-05 (profile stub), Admin reset MK

Tài liệu tham chiếu hành vi runtime sau khi triển khai — đọc lại khi test, review PR hoặc demo.

---

## 1. Ba luồng chính

| Luồng | URL | Cần login? |
|-------|-----|------------|
| Quên MK (guest) | `/forgot-password` → email → `/reset-password?token=` | Không |
| Xác minh bảo mật profile | `/profile/security-verify` | Có (mọi role) |
| Đổi MK trên profile | POST `/profile/password` (sau xác minh) | Có (mọi role) |

---

## 2. Phân quyền (AccessControl + servlet)

### Public — không cần đăng nhập

- `/forgot-password`
- `/reset-password`

*Nghiệp vụ:* chỉ user **ACTIVE** mới nhận email quên MK (không lộ email qua thông báo chung).

### Authenticated — mọi role (CUSTOMER / STAFF / MANAGER / ADMIN)

- `/profile`
- `/profile/security-verify`
- `/profile/security-verify/confirm`
- POST `/profile/password`

*Điều kiện đổi MK:* xác minh trước (MK hiện tại hoặc link email); chỉ đổi MK **của chính mình**.

### Admin only (ngoài luồng profile)

- POST `/admin/users/reset-password` — Admin reset MK user khác (không reset Admin, không reset chính mình).

---

## 3. Token & thời hạn

### Token trong DB (`PasswordResetTokens.purpose`)

| purpose | TTL | Consumer |
|---------|-----|----------|
| `REGISTER_VERIFY` | 24 giờ | `/verify-email?token=` (FR-01) |
| `PASSWORD_RESET` | 30 phút | `/reset-password?token=` |
| `PROFILE_SECURITY` | 15 phút | `/profile/security-verify/confirm?token=` |

`findValidByToken` trả về rỗng khi: không tìm thấy, sai purpose, `used_at` đã set, hoặc `expired_at < now`.

Token **one-time**: sau `markUsed()` không dùng lại được.

Tạo token mới cùng purpose → `invalidateUnusedForUser()` vô hiệu hóa token cũ chưa dùng.

### Cờ session sau xác minh profile (`ProfileSecurityUtil`)

- Attribute: `profileSecurityVerifiedAt`
- Hiệu lực: **15 phút** kể từ `markVerified()`
- Quyết định hiển thị form đổi MK trên `/profile` — **không nằm trong URL**

---

## 4. Khi token / session hết hạn — user thấy gì?

### Link quên MK (`/reset-password?token=`) — hết 30p / đã dùng / sai

- GET hoặc POST không hợp lệ → redirect `/login?reset=invalid`
- Thông báo: *"Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn."*
- **Xử lý:** vào lại Quên mật khẩu

### Link xác minh profile email — hết 15p / đã dùng

- Redirect `/profile/security-verify?error=invalid`
- Thông báo: *"Liên kết xác minh không hợp lệ hoặc đã hết hạn."*
- **Xử lý:** gửi email xác minh lại

### Đã xác minh nhưng quá 15 phút chưa đổi MK (session)

- `/profile`: ẩn form, chỉ nút **"Xác minh tài khoản"**
- POST `/profile/password` → `/profile?security=required`
- **Hai cách xác minh (MK / email) sau khi đã vào form — hành vi giống nhau** (đều do session 15p)

#### Khác biệt trước khi vào form (chỉ luồng email)

- Gửi email xong, **chưa click link** trong 15p → token DB hết hạn, chưa bao giờ có cờ session
- Click link trong 15p → `markVerified()` → đồng hồ session 15p bắt đầu

> Hệ thống **không** tách thông báo "hết hạn" vs "đã dùng" vs "sai token" — gộp chung `invalid` / `reset=invalid`.

---

## 5. Copy link sang trình duyệt khác (ẩn danh)

### Copy `/profile` sau khi đã xác minh

- Trạng thái verified **không** đi theo URL
- Ẩn danh: không session → login → session mới **không** có cờ verified → phải xác minh lại

### Copy link email `/profile/security-verify/confirm?token=`

- Phải **login đúng user** trên trình duyệt đó
- Token phải còn hạn và chưa dùng
- Login sai user → `error=mismatch`

### Copy `/reset-password?token=` (quên MK)

- **Không** cần login — dùng được trên mọi trình duyệt nếu token còn hiệu lực

---

## 6. Spam gửi email xác minh profile

**Hiện tại không có rate limit / cooldown.**

Mỗi lần bấm "Gửi email xác minh":

1. Invalidate mọi token `PROFILE_SECURITY` cũ (chưa dùng)
2. Tạo token mới (15 phút)
3. Gửi email SMTP thật

| Hệ quả | Chi tiết |
|--------|----------|
| Nhiều email | Mỗi lần bấm = 1 email |
| Chỉ link **cuối** hợp lệ | Link cũ → `invalid` |
| Đã verified (session còn hiệu lực) | Redirect `/profile`, không gửi thêm |

Luồng **Quên mật khẩu** tương tự: mỗi lần gửi invalidate token cũ + email mới (TTL 30 phút).

---

## 7. Quy tắc mật khẩu (`PasswordValidator`)

- 8–16 ký tự
- Chữ hoa + thường + số + ký tự đặc biệt, không khoảng trắng

### Đã áp dụng (server-side)

| Luồng | File |
|-------|------|
| Đăng ký | `RegisterValidator` |
| Reset quên MK | `ResetPasswordServlet` |
| Đổi MK profile | `ChangePasswordServlet` |
| Admin reset MK | `UserResetPasswordServlet` |

### Chưa áp dụng đầy đủ

| Luồng | Ghi chú |
|-------|---------|
| Admin tạo Staff/Manager | `UserCreateServlet` — chỉ check độ dài ≥ 8 |

### Không cần regex

- Login (verify MK cũ)
- Xác minh profile bằng MK hiện tại
- Google đăng ký (MK hệ thống sinh ngẫu nhiên)

---

## 8. SMTP (FR-04)

- **Không** dùng devLink (khác FR-01 `register-pending.jsp`)
- Chưa cấu hình SMTP → lỗi rõ ràng, không giả "đã gửi"
- Cần `email.properties` + `app.base.url` đúng Tomcat

---

## 9. Database

### DB mới

`create_database.sql` đã có cột `PasswordResetTokens.purpose` + CHECK constraint.

### DB cũ (sau pull)

Chạy migration:

```text
Database/migrations/add_token_purpose.sql
```

---

## 10. File triển khai chính

### Servlet

| File | URL |
|------|-----|
| `ForgotPasswordServlet` | `/forgot-password` |
| `ResetPasswordServlet` | `/reset-password` |
| `ProfileServlet` | `/profile` |
| `ProfileSecurityVerifyServlet` | `/profile/security-verify` |
| `ProfileSecurityConfirmServlet` | `/profile/security-verify/confirm` |
| `ChangePasswordServlet` | POST `/profile/password` |

### Utils

- `PasswordValidator`, `ProfileSecurityUtil`, `AuthConstants` (purpose + TTL)
- `PasswordResetTokenDAO` (insert/find/invalidate theo purpose)
- `EmailUtil` (reset + profile security email)
- `AccessControl` (public forgot/reset)

### View

- `auth/forgot-password.jsp`, `auth/reset-password.jsp`
- `common/profile.jsp`, `profile-security.jspf`, `profile-security-verify.jsp`
- `css/profile.css`

---

## 11. Checklist test nhanh

- [ ] Quên MK: email ACTIVE → link 30p → đặt MK → login
- [ ] Quên MK: email không tồn tại → thông báo chung (không lộ)
- [ ] SMTP tắt → lỗi rõ, không tạo token giả
- [ ] Profile: xác minh MK → đổi MK trong 15p
- [ ] Profile: xác minh email → click link → đổi MK
- [ ] Google user: dùng tab email (không biết MK ngẫu nhiên)
- [ ] Quá 15p sau xác minh → form ẩn, `security=required` khi POST
- [ ] Token đã dùng / hết hạn → thông báo invalid
- [ ] Staff/Manager/Admin: vào `/profile` và đổi MK được
