-- SeatTypes.price_multiplier: tối thiểu 1.00
-- Idempotent — chạy trên DB đã có data.

USE MovieTicketDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.SeatTypes')
      AND name = N'CK_SeatTypes_Multi'
)
BEGIN
    ALTER TABLE SeatTypes DROP CONSTRAINT CK_SeatTypes_Multi;
END
GO

-- Chuẩn hóa dữ liệu cũ (nếu có) trước khi gắn constraint mới
UPDATE SeatTypes
SET price_multiplier = 1.00
WHERE price_multiplier < 1;
GO

ALTER TABLE SeatTypes
    ADD CONSTRAINT CK_SeatTypes_Multi CHECK (price_multiplier >= 1);
GO
