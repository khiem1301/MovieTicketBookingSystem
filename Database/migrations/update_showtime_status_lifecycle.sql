/*
  Migration: trạng thái suất chiếu thực tế
  SCHEDULED | SHOWING | FINISHED | CANCELLED
  (bỏ OPEN, SOLD_OUT)

  Chạy trên DB đã tồn tại (MovieTicketDB).
*/
USE MovieTicketDB;
GO

-- 1) Gỡ CHECK cũ (còn OPEN/SOLD_OUT) trước khi ghi SHOWING
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_Showtimes_Status' AND parent_object_id = OBJECT_ID('Showtimes')
)
    ALTER TABLE Showtimes DROP CONSTRAINT CK_Showtimes_Status;
GO

-- 2) Map status theo thời gian (không đụng CANCELLED)
UPDATE Showtimes
SET status = CASE
    WHEN end_time   <= SYSDATETIME() THEN 'FINISHED'
    WHEN start_time <= SYSDATETIME() AND end_time > SYSDATETIME() THEN 'SHOWING'
    ELSE 'SCHEDULED'
END
WHERE status <> 'CANCELLED';
GO

-- 3) Siết CHECK mới
ALTER TABLE Showtimes
ADD CONSTRAINT CK_Showtimes_Status
CHECK (status IN ('SCHEDULED', 'SHOWING', 'CANCELLED', 'FINISHED'));
GO

PRINT N'Da cap nhat CK_Showtimes_Status: SCHEDULED / SHOWING / CANCELLED / FINISHED';
GO
