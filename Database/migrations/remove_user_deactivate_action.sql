/*
  Migration: bỏ action DEACTIVATE khỏi UserStatusLog
  ────────────────────────────────────────────────────────────
  Bối cảnh:
    - UserStatusServlet từng có action "deactivate" (Users.status -> INACTIVE)
      nhưng UI admin không có nút gọi tới action này — dead code.
    - Action đó đã bị xóa khỏi code (chỉ còn "lock" -> BANNED, "unlock" -> ACTIVE).
    - Users.status vẫn giữ nguyên 3 giá trị (ACTIVE/INACTIVE/BANNED) vì INACTIVE
      còn dùng cho luồng đăng ký + xác thực email (RegisterServlet/VerifyEmailServlet) —
      KHÔNG đụng tới CK_Users_Status trong migration này.
    - UserStatusLog.previous_status vẫn giữ INACTIVE vì admin có thể khóa (lock)
      một tài khoản đang chờ xác thực email (previous_status = INACTIVE hợp lệ).
    - UserStatusLog.new_status thì siết lại bỏ INACTIVE, vì từ nay chỉ còn
      action LOCK (-> BANNED) và UNLOCK (-> ACTIVE) ghi log, không còn action nào
      tạo ra new_status = INACTIVE nữa.

  An toàn chạy lại (idempotent). Không có dữ liệu INACTIVE/DEACTIVATE nào trong
  UserStatusLog tại thời điểm viết migration này (bảng rỗng ở môi trường dev),
  nhưng script vẫn tự kiểm tra và báo lỗi rõ ràng nếu có dữ liệu vi phạm thay vì
  âm thầm xóa.

  Ví dụ:
    sqlcmd -S localhost,1433 -U sa -P *** -d MovieTicketDB -C -i Database\migrations\remove_user_deactivate_action.sql
*/
USE MovieTicketDB;
GO

SET NOCOUNT ON;
GO

-- 0) Chặn sớm nếu còn dữ liệu sẽ vi phạm constraint mới
IF EXISTS (SELECT 1 FROM UserStatusLog WHERE action = N'DEACTIVATE' OR new_status = N'INACTIVE')
BEGIN
    RAISERROR(N'Còn bản ghi UserStatusLog dùng action=DEACTIVATE hoặc new_status=INACTIVE — xử lý dữ liệu trước khi chạy migration này.', 16, 1);
    RETURN;
END
GO

-- 1) Gỡ CHECK cũ (action)
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_UserStatusLog_Action'
      AND parent_object_id = OBJECT_ID(N'UserStatusLog')
)
BEGIN
    ALTER TABLE UserStatusLog DROP CONSTRAINT CK_UserStatusLog_Action;
    PRINT N'[1] Da go CK_UserStatusLog_Action cu.';
END
ELSE
    PRINT N'[1] Khong co CK_UserStatusLog_Action — bo qua.';
GO

-- 2) Gỡ CHECK cũ (new_status)
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_UserStatusLog_NewStatus'
      AND parent_object_id = OBJECT_ID(N'UserStatusLog')
)
BEGIN
    ALTER TABLE UserStatusLog DROP CONSTRAINT CK_UserStatusLog_NewStatus;
    PRINT N'[2] Da go CK_UserStatusLog_NewStatus cu.';
END
ELSE
    PRINT N'[2] Khong co CK_UserStatusLog_NewStatus — bo qua.';
GO

-- 3) Siết CHECK moi: action chi con LOCK/UNLOCK
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_UserStatusLog_Action'
      AND parent_object_id = OBJECT_ID(N'UserStatusLog')
)
BEGIN
    ALTER TABLE UserStatusLog
    ADD CONSTRAINT CK_UserStatusLog_Action
    CHECK (action IN (N'LOCK', N'UNLOCK'));
    PRINT N'[3] Da tao CK_UserStatusLog_Action moi (LOCK, UNLOCK).';
END
ELSE
    PRINT N'[3] CK_UserStatusLog_Action da ton tai — bo qua.';
GO

-- 4) Siết CHECK moi: new_status chi con ACTIVE/BANNED
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_UserStatusLog_NewStatus'
      AND parent_object_id = OBJECT_ID(N'UserStatusLog')
)
BEGIN
    ALTER TABLE UserStatusLog
    ADD CONSTRAINT CK_UserStatusLog_NewStatus
    CHECK (new_status IN (N'ACTIVE', N'BANNED'));
    PRINT N'[4] Da tao CK_UserStatusLog_NewStatus moi (ACTIVE, BANNED).';
END
ELSE
    PRINT N'[4] CK_UserStatusLog_NewStatus da ton tai — bo qua.';
GO

-- 5) Bao cao
SELECT name, definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'UserStatusLog')
ORDER BY name;
GO
