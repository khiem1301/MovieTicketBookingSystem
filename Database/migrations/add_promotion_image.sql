-- Thêm ảnh minh họa cho voucher/promotion (chạy trên DB đã tạo trước đó)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Promotions') AND name = 'image_url'
)
BEGIN
    ALTER TABLE Promotions ADD image_url NVARCHAR(500) NULL;
END
GO
