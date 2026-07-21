-- FR-43: Thêm cột points_redeemed vào Bookings để track điểm đã dùng cho đơn
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Bookings') AND name = 'points_redeemed'
)
BEGIN
    ALTER TABLE Bookings ADD points_redeemed INT NOT NULL DEFAULT 0;
END
GO
