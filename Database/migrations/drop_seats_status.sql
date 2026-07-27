-- Bỏ cột Seats.status (ACTIVE/BROKEN/BLOCKED) — không có nghiệp vụ set status ghế.
-- Idempotent — chạy trên DB đã có data.
-- Lưu ý: phải DROP default constraint (DF__Seats__status__*) trước khi DROP COLUMN.

USE MovieTicketDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Seats')
      AND name = N'IX_Seats_Status'
)
BEGIN
    DROP INDEX IX_Seats_Status ON dbo.Seats;
END
GO

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.Seats')
      AND name = N'CK_Seats_Status'
)
BEGIN
    ALTER TABLE dbo.Seats DROP CONSTRAINT CK_Seats_Status;
END
GO

-- Default constraint auto-generated (DF__Seats__status__xxxx)
DECLARE @dfName SYSNAME;
SELECT @dfName = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c
  ON c.default_object_id = dc.object_id
WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Seats')
  AND c.name = N'status';

IF @dfName IS NOT NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.Seats DROP CONSTRAINT [' + @dfName + N']');
END
GO

IF COL_LENGTH(N'dbo.Seats', N'status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Seats DROP COLUMN status;
END
GO

PRINT N'=== Dropped Seats.status (+ default/check/index) ===';
GO
