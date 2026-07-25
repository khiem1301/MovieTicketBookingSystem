/*
  Migration: đồng bộ trạng thái suất chiếu với code hiện tại
  ────────────────────────────────────────────────────────────
  Mục tiêu:
    - CHECK: SCHEDULED | SHOWING | CANCELLED | FINISHED
    - Bỏ OPEN, SOLD_OUT (schema cũ)
    - UPDATE status theo start_time / end_time (không đụng CANCELLED)

  An toàn chạy lại (idempotent).
  Chạy trên DB đã tồn tại (MovieTicketDB).

  Ví dụ:
    sqlcmd -S MORGAN,1433 -U sa -P *** -d MovieTicketDB -i Database\migrations\update_showtime_status_lifecycle.sql
*/
USE MovieTicketDB;
GO

SET NOCOUNT ON;
GO

-- 1) Gỡ CHECK cũ (có thể còn OPEN / SOLD_OUT, thiếu SHOWING)
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_Showtimes_Status'
      AND parent_object_id = OBJECT_ID(N'Showtimes')
)
BEGIN
    ALTER TABLE Showtimes DROP CONSTRAINT CK_Showtimes_Status;
    PRINT N'[1] Da go CK_Showtimes_Status cu.';
END
ELSE
    PRINT N'[1] Khong co CK_Showtimes_Status — bo qua.';
GO

-- 2) Map legacy (neu con) roi dong bo theo thoi gian
UPDATE Showtimes SET status = N'SCHEDULED' WHERE status = N'OPEN';
UPDATE Showtimes SET status = N'FINISHED'  WHERE status = N'SOLD_OUT';

UPDATE Showtimes
SET status = CASE
    WHEN end_time   <= SYSDATETIME() THEN N'FINISHED'
    WHEN start_time <= SYSDATETIME() AND end_time > SYSDATETIME() THEN N'SHOWING'
    ELSE N'SCHEDULED'
END
WHERE status <> N'CANCELLED';

PRINT N'[2] Da sync status theo SYSDATETIME() (giu CANCELLED).';
GO

-- 3) Siết CHECK mới (chi add neu chua co)
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_Showtimes_Status'
      AND parent_object_id = OBJECT_ID(N'Showtimes')
)
BEGIN
    ALTER TABLE Showtimes
    ADD CONSTRAINT CK_Showtimes_Status
    CHECK (status IN (N'SCHEDULED', N'SHOWING', N'CANCELLED', N'FINISHED'));
    PRINT N'[3] Da tao CK_Showtimes_Status moi.';
END
ELSE
    PRINT N'[3] CK_Showtimes_Status da ton tai — bo qua.';
GO

-- 4) Bao cao
PRINT N'--- Phan bo status sau migrate ---';
SELECT status, COUNT(*) AS cnt
FROM Showtimes
GROUP BY status
ORDER BY status;

SELECT name, definition
FROM sys.check_constraints
WHERE name = N'CK_Showtimes_Status'
  AND parent_object_id = OBJECT_ID(N'Showtimes');
GO
