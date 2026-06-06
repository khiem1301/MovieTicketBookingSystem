-- ============================================================
-- MIGRATION: Home Page — Toàn bộ thay đổi DB kể từ khi làm home page
-- Bao gồm: backdrop_url column + Genres + CinemaRooms + Movies + MovieGenres
--
-- Cách chạy: Mở SSMS → Ctrl+A → F5
-- An toàn: dùng IF NOT EXISTS, có thể chạy nhiều lần không bị lỗi
-- ============================================================

USE MovieTicketDB;
GO

PRINT N'============================================================';
PRINT N'  Migration: Home Page Seed Data';
PRINT N'============================================================';

-- ============================================================
-- BƯỚC 1: Thêm cột backdrop_url vào Movies (nếu chưa có)
-- backdrop_url = ảnh ngang 16:9, dùng làm nền hero slider
-- poster_url   = ảnh dọc 2:3,  dùng trong phone frame
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Movies' AND COLUMN_NAME = 'backdrop_url'
)
BEGIN
    ALTER TABLE Movies ADD backdrop_url NVARCHAR(MAX) NULL;
    PRINT N'[OK] Thêm cột backdrop_url vào Movies';
END
ELSE
    PRINT N'[SKIP] backdrop_url đã tồn tại';
GO

-- ============================================================
-- BƯỚC 2: Thêm 8 thể loại phim (Genres)
-- Dùng cặp MERGE để idempotent — không insert trùng
-- ============================================================
PRINT N'[...] Seed Genres';
GO

MERGE INTO Genres AS target
USING (VALUES
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101', N'Hành động'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102', N'Viễn tưởng'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103', N'Kinh dị'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104', N'Tình cảm'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105', N'Hoạt hình'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106', N'Hài'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107', N'Chính kịch'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108', N'Kịch tính')
) AS src (id, genre_name)
ON target.id = src.id
WHEN NOT MATCHED THEN
    INSERT (id, genre_name) VALUES (src.id, src.genre_name);

PRINT N'[OK] Genres done';
GO

-- ============================================================
-- BƯỚC 3: Thêm 3 phòng chiếu (CinemaRooms)
-- ============================================================
PRINT N'[...] Seed CinemaRooms';
GO

MERGE INTO CinemaRooms AS target
USING (VALUES
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01', N'Phòng 1',    120, 'ACTIVE'),
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02', N'Phòng IMAX',  80, 'ACTIVE'),
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC03', N'Phòng 3',     60, 'ACTIVE')
) AS src (id, room_name, capacity, status)
ON target.id = src.id
WHEN NOT MATCHED THEN
    INSERT (id, room_name, capacity, status)
    VALUES (src.id, src.room_name, src.capacity, src.status);

PRINT N'[OK] CinemaRooms done';
GO

-- ============================================================
-- BƯỚC 4: Thêm 8 phim mẫu (Movies) kèm backdrop_url
-- NOW_SHOWING: Avengers, Mission Impossible, Lilo & Stitch, The Housemaid
-- COMING_SOON: Superman, How to Train Your Dragon, Jurassic World, Hoa Vàng
-- ============================================================
PRINT N'[...] Seed Movies';
GO

MERGE INTO Movies AS target
USING (VALUES
    -- ── ĐANG CHIẾU ──────────────────────────────────────────
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101',
        N'Avengers: Doomsday', 'avengers-doomsday',
        N'Các siêu anh hùng Marvel tập hợp lần cuối để ngăn chặn Doctor Doom – kẻ phản diện quyền năng nhất vũ trụ đang âm mưu nắm quyền kiểm soát toàn bộ thực tại.',
        150, CAST('2026-05-01' AS DATE),
        'https://www.youtube.com/watch?v=sOEg_YZQsTI',
        'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
        'https://image.tmdb.org/t/p/w1280/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
        N'Joe Russo, Anthony Russo',
        N'Robert Downey Jr., Chris Evans, Scarlett Johansson',
        N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.80
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102',
        N'Mission: Impossible – The Final Reckoning', 'mission-impossible-final-reckoning',
        N'Ethan Hunt và đội IMF đối mặt với sứ mệnh nguy hiểm nhất khi một AI siêu việt nắm giữ bí mật có thể hủy diệt toàn bộ nền văn minh nhân loại.',
        163, CAST('2026-05-21' AS DATE),
        'https://www.youtube.com/watch?v=avz06PDqDbM',
        'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        'https://image.tmdb.org/t/p/w1280/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        N'Christopher McQuarrie',
        N'Tom Cruise, Hayley Atwell, Simon Pegg',
        N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.50
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103',
        N'Lilo & Stitch', 'lilo-stitch-2025',
        N'Cô bé Lilo cô đơn ở Hawaii kết bạn với sinh vật ngoài hành tinh tên Stitch. Hành trình tìm kiếm ý nghĩa thật sự của gia đình sẽ thay đổi cả hai mãi mãi.',
        108, CAST('2026-05-23' AS DATE),
        'https://www.youtube.com/watch?v=dJWjlMGBJ0c',
        'https://image.tmdb.org/t/p/w500/mGT7gDFqtGpYDERbmMAjUHw3TlC.jpg',
        'https://image.tmdb.org/t/p/w1280/mGT7gDFqtGpYDERbmMAjUHw3TlC.jpg',
        N'Dean Fleischer Camp',
        N'Maia Kealoha, Sydney Agudong, Zach Galifianakis',
        N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'NOW_SHOWING', 4.20
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104',
        N'The Housemaid', 'the-housemaid',
        N'Một người giúp việc bí ẩn gia nhập gia đình giàu có và dần tiết lộ những bí mật đen tối đằng sau cuộc sống xa hoa tưởng chừng hoàn hảo.',
        118, CAST('2026-04-23' AS DATE),
        'https://www.youtube.com/watch?v=HM9VMExYmGg',
        'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
        'https://image.tmdb.org/t/p/w1280/74xTEgt7R36Fpooo50r9T25onhq.jpg',
        N'Park Chan-wook',
        N'Sydney Sweeney, Amanda Seyfried, Brandon Sklenar',
        N'Tiếng Anh', N'Phụ đề Việt', 'T18', 'NOW_SHOWING', 4.10
    ),
    -- ── SẮP CHIẾU ───────────────────────────────────────────
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105',
        N'Superman', 'superman-2025',
        N'Phiên bản Superman hoàn toàn mới trong DCU. Clark Kent học cách trở thành biểu tượng hy vọng cho nhân loại trong thế giới đầy thách thức và đe dọa.',
        132, CAST('2026-07-11' AS DATE),
        'https://www.youtube.com/watch?v=mVkTFiXm0Oc',
        'https://image.tmdb.org/t/p/w500/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
        'https://image.tmdb.org/t/p/w1280/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
        N'James Gunn',
        N'David Corenswet, Rachel Brosnahan, Nicholas Hoult',
        N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'COMING_SOON', 0.00
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106',
        N'How to Train Your Dragon', 'how-to-train-your-dragon-live-action',
        N'Bản live-action của bộ phim hoạt hình huyền thoại. Hiccup và Toothless chiến đấu để bảo vệ hòa bình giữa người và rồng trước những mối đe dọa mới.',
        105, CAST('2026-06-27' AS DATE),
        'https://www.youtube.com/watch?v=mQVoABqW2Sg',
        'https://image.tmdb.org/t/p/w500/sv1xJUazXeYqALzczSZ3O6nkH75.jpg',
        'https://image.tmdb.org/t/p/w1280/sv1xJUazXeYqALzczSZ3O6nkH75.jpg',
        N'Dean DeBlois',
        N'Mason Thames, Nico Parker, Gerard Butler',
        N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'COMING_SOON', 0.00
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107',
        N'Jurassic World: Rebirth', 'jurassic-world-rebirth',
        N'Năm năm sau thảm họa, khủng long đã tràn khắp địa cầu. Một nhóm thám hiểm liều lĩnh tiến vào vùng đất bí ẩn để tìm kiếm bí quyết sinh tồn cuối cùng.',
        119, CAST('2026-07-02' AS DATE),
        'https://www.youtube.com/watch?v=jlHBVhBFDso',
        'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'https://image.tmdb.org/t/p/w1280/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        N'Gareth Edwards',
        N'Scarlett Johansson, Jonathan Bailey, Mahershala Ali',
        N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'COMING_SOON', 0.00
    ),
    (
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108',
        N'Tôi Thấy Hoa Vàng Trên Cỏ Xanh 2', 'toi-thay-hoa-vang-tren-co-xanh-2',
        N'Tiếp nối câu chuyện tuổi thơ xúc động ở làng quê miền Trung. Thiều và Tường lớn lên với những kỷ niệm trong sáng và tình yêu đầu đời không thể phai nhòa.',
        125, CAST('2026-08-15' AS DATE),
        'https://www.youtube.com/watch?v=A4xwi5e0MCw',
        'https://image.tmdb.org/t/p/w500/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg',
        'https://image.tmdb.org/t/p/w1280/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg',
        N'Victor Vũ',
        N'Thịnh Vinh, Đào Duy Phước, Lê Thị Duyên',
        N'Tiếng Việt', NULL, 'P', 'COMING_SOON', 0.00
    )
) AS src (
    id, title, slug, description, duration_minutes, release_date,
    trailer_url, poster_url, backdrop_url, director, cast_members,
    language, subtitle, age_rating, status, average_rating
)
ON target.id = src.id
WHEN NOT MATCHED THEN
    INSERT (
        id, title, slug, description, duration_minutes, release_date,
        trailer_url, poster_url, backdrop_url, director, cast_members,
        language, subtitle, age_rating, status, average_rating
    )
    VALUES (
        src.id, src.title, src.slug, src.description, src.duration_minutes, src.release_date,
        src.trailer_url, src.poster_url, src.backdrop_url, src.director, src.cast_members,
        src.language, src.subtitle, src.age_rating, src.status, src.average_rating
    )
WHEN MATCHED AND target.backdrop_url IS NULL THEN
    -- Phim đã tồn tại nhưng chưa có backdrop → cập nhật backdrop_url
    UPDATE SET target.backdrop_url = src.backdrop_url;

PRINT N'[OK] Movies done';
GO

-- ============================================================
-- BƯỚC 5: Thêm quan hệ Movie ↔ Genre (MovieGenres)
-- ============================================================
PRINT N'[...] Seed MovieGenres';
GO

MERGE INTO MovieGenres AS target
USING (VALUES
    -- Avengers: Doomsday → Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- Mission: Impossible → Hành động, Kịch tính
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
    -- Lilo & Stitch → Hoạt hình, Hài
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106'),
    -- The Housemaid → Kinh dị, Kịch tính
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
    -- Superman → Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- How to Train Your Dragon → Hoạt hình, Hành động
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    -- Jurassic World: Rebirth → Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- Hoa Vàng → Tình cảm, Chính kịch
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107')
) AS src (movie_id, genre_id)
ON target.movie_id = src.movie_id AND target.genre_id = src.genre_id
WHEN NOT MATCHED THEN
    INSERT (movie_id, genre_id) VALUES (src.movie_id, src.genre_id);

PRINT N'[OK] MovieGenres done';
GO

-- ============================================================
-- BƯỚC 6: Sửa backdrop_url (URL cũ trên TMDB hay bị 404)
-- Chạy mỗi lần migration để đảm bảo ảnh nền hero hiển thị được
-- ============================================================
PRINT N'[...] Fix backdrop_url';
GO

UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/or06FN3Dka5tukK1e9sl16pB3iy.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/62HCnUTziyWcpDaBO2i1DX17ljH.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/mGT7gDFqtGpYDERbmMAjUHw3TlC.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/74xTEgt7R36Fpooo50r9T25onhq.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/sv1xJUazXeYqALzczSZ3O6nkH75.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107';
UPDATE Movies SET backdrop_url = 'https://image.tmdb.org/t/p/w1280/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg'
WHERE id = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108';

PRINT N'[OK] backdrop_url fixed';
GO

-- ============================================================
-- KIỂM TRA KẾT QUẢ
-- ============================================================
PRINT N'';
PRINT N'=== KẾT QUẢ MIGRATION ===';

SELECT
    m.title,
    m.status,
    m.average_rating AS rating,
    CASE WHEN m.backdrop_url IS NOT NULL THEN N'✓' ELSE N'✗' END AS has_backdrop,
    STRING_AGG(g.genre_name, ', ') AS genres
FROM Movies m
LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
LEFT JOIN Genres g       ON mg.genre_id = g.id
WHERE m.id IN (
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107',
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108'
)
GROUP BY m.title, m.status, m.average_rating
ORDER BY m.average_rating DESC;
GO

PRINT N'=== MIGRATION HOÀN THÀNH ===';
GO
