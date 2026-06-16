-- ============================================================
-- Sprint 2 — Counter POS migrations (FR-36/37/42/18/19)
-- Chạy file này 1 lần trên DB đang dùng để cập nhật schema.
-- Tất cả lệnh idempotent (có thể chạy lại mà không bị lỗi).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Genres: thêm description, is_active (nếu DB cũ chưa có)
-- ------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Genres' AND COLUMN_NAME = 'description'
)
BEGIN
    ALTER TABLE Genres ADD description NVARCHAR(500) NULL;
    PRINT 'Added column: Genres.description';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Genres' AND COLUMN_NAME = 'is_active'
)
BEGIN
    ALTER TABLE Genres ADD is_active BIT NOT NULL DEFAULT 1;
    PRINT 'Added column: Genres.is_active';
END
GO

-- ------------------------------------------------------------
-- 2. Tickets: thêm is_printed (FR-37 — đánh dấu vé đã in)
-- ------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Tickets' AND COLUMN_NAME = 'is_printed'
)
BEGIN
    ALTER TABLE Tickets ADD is_printed BIT NOT NULL DEFAULT 0;
    PRINT 'Added column: Tickets.is_printed';
END
GO

-- ------------------------------------------------------------
-- 3. Payments: thêm cash_received, change_amount (FR-36 — thanh toán tiền mặt)
-- ------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Payments' AND COLUMN_NAME = 'cash_received'
)
BEGIN
    ALTER TABLE Payments ADD cash_received DECIMAL(12,2) NULL;
    PRINT 'Added column: Payments.cash_received';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Payments' AND COLUMN_NAME = 'change_amount'
)
BEGIN
    ALTER TABLE Payments ADD change_amount DECIMAL(12,2) NULL;
    PRINT 'Added column: Payments.change_amount';
END
GO

-- ------------------------------------------------------------
-- 4. Payments: cập nhật CHECK constraint — chỉ VNPAY, MOMO, CASH, VIETQR
--    (bỏ CARD, thay thế add_card_payment_method.sql và add_vietqr_payment_method.sql)
-- ------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Payments_Method')
BEGIN
    ALTER TABLE Payments DROP CONSTRAINT CK_Payments_Method;
END
GO
ALTER TABLE Payments ADD CONSTRAINT CK_Payments_Method
    CHECK (payment_method IN ('VNPAY', 'MOMO', 'CASH', 'VIETQR'));
GO
PRINT 'Updated CK_Payments_Method: VNPAY, MOMO, CASH, VIETQR';
