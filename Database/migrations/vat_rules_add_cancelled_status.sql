-- Cho phép status CANCELLED trên VatRules (hủy lịch tương lai).
-- Idempotent — an toàn chạy lại trên DB đã có CANCELLED.

USE MovieTicketDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_VatRules_Status' AND parent_object_id = OBJECT_ID(N'dbo.VatRules')
)
    ALTER TABLE dbo.VatRules DROP CONSTRAINT CK_VatRules_Status;
GO

ALTER TABLE dbo.VatRules
    ADD CONSTRAINT CK_VatRules_Status
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'CANCELLED'));
GO

-- Chuẩn hóa: lịch tương lai từng hủy kiểu cũ (INACTIVE) → CANCELLED
UPDATE dbo.VatRules
SET status = 'CANCELLED'
WHERE status = 'INACTIVE'
  AND start_date > GETDATE()
  AND end_date IS NULL;
GO

PRINT N'=== VatRules: CANCELLED status enabled ===';
GO
