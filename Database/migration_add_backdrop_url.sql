-- ============================================================
-- MIGRATION: Thêm cột backdrop_url vào bảng Movies
-- Chạy file này trong SSMS (Ctrl+A → F5) nếu DB đã tồn tại
-- ============================================================

USE MovieTicketDB;
GO

-- Bước 1: Thêm cột backdrop_url (chỉ chạy nếu cột chưa có)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Movies' AND COLUMN_NAME = 'backdrop_url'
)
BEGIN
    ALTER TABLE Movies ADD backdrop_url NVARCHAR(MAX) NULL;
    PRINT N'[OK] Đã thêm cột backdrop_url vào bảng Movies';
END
ELSE
BEGIN
    PRINT N'[SKIP] Cột backdrop_url đã tồn tại';
END
GO

-- Bước 2: Cập nhật backdrop_url cho 8 phim seed data
-- backdrop_url dùng cùng file ảnh với poster_url nhưng size w1280 (ảnh ngang hero)
-- poster_url  là w500 (ảnh dọc trong phone frame)
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/or06FN3Dka5tukK1e9sl16pB3iy.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101';  -- Avengers: Doomsday

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/62HCnUTziyWcpDaBO2i1DX17ljH.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102';  -- Mission: Impossible

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/mGT7gDFqtGpYDERbmMAjUHw3TlC.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103';  -- Lilo & Stitch

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/74xTEgt7R36Fpooo50r9T25onhq.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104';  -- The Housemaid

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105';  -- Superman

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/sv1xJUazXeYqALzczSZ3O6nkH75.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106';  -- How to Train Your Dragon

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107';  -- Jurassic World: Rebirth

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108';  -- Tôi Thấy Hoa Vàng

PRINT N'[OK] Đã cập nhật backdrop_url cho 8 phim seed';
GO

-- Bước 3: Kiểm tra kết quả
SELECT id, title,
       LEFT(poster_url,  50) AS poster_url,
       LEFT(backdrop_url,50) AS backdrop_url
FROM Movies
ORDER BY status DESC, average_rating DESC;
GO
