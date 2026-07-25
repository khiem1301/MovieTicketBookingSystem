-- ============================================================
-- Movie Ticket Booking System — SEED DATA
-- ============================================================
-- Chạy SAU Database/create_database.sql (schema trống).
-- SSMS: mở file → Ctrl+A → F5.
--
-- Nội dung:
--   Roles, Users (Password@123), SystemConfig, VatRules, CinemaInfo
--   SeatTypes, Chatbot demo
--   Genres, CinemaRooms, 8 Movies + MovieGenres
--   PricingRules (FR-50), Promotions (FR-22)
--   Seats / Showtimes / Bookings SEED-STATS-* (báo cáo admin)
--
-- Tuỳ chọn load-test:
--   seed_showtime_load_test.sql
--   seed_load_test_data.sql
-- ============================================================

USE MovieTicketDB;
GO

-- ============================================================
-- SEED DATA — DU LIEU MAC DINH
-- ============================================================

-- 4 vai tro co ban
INSERT INTO Roles (id, role_name, description) VALUES
    ('11111111-1111-1111-1111-111111111101', 'ADMIN',    N'Quản trị toàn hệ thống'),
    ('11111111-1111-1111-1111-111111111102', 'MANAGER',  N'Quản lý rạp: phim, suất chiếu, báo cáo'),
    ('11111111-1111-1111-1111-111111111103', 'STAFF',    N'Nhân viên bán vé tại quầy'),
    ('11111111-1111-1111-1111-111111111104', 'CUSTOMER', N'Khách hàng đặt vé online');
GO

-- BCrypt hash cua mat khau: Password@123 (prefix $2a$ — tuong thich jbcrypt)
DECLARE @DefaultPasswordHash NVARCHAR(255) = '$2a$10$cQtXPt5hVH2nDDhuXFDxQ.aKttyB7S7/6jR.xyULrEfcnUFA8UCM6';

INSERT INTO Users (
    id, role_id, email, username, phone_number,
    password_hash, full_name, date_of_birth, avatar_url,
    status, loyalty_points, last_login_at
) VALUES
    -- Admin / Manager / Staff (noi bo)
    ('22222222-2222-2222-2222-222222222201', '11111111-1111-1111-1111-111111111101',
     'admin@movieticket.vn', 'admin', '0901000001',
     @DefaultPasswordHash, N'Nguyễn Văn Admin', '1990-03-15', NULL,
     'ACTIVE', 0, NULL),

    ('22222222-2222-2222-2222-222222222202', '11111111-1111-1111-1111-111111111102',
     'manager@movieticket.vn', 'manager', '0901000002',
     @DefaultPasswordHash, N'Trần Thị Manager', '1988-07-20', NULL,
     'ACTIVE', 0, NULL),

    ('22222222-2222-2222-2222-222222222203', '11111111-1111-1111-1111-111111111103',
     'staff@movieticket.vn', 'staff', '0901000003',
     @DefaultPasswordHash, N'Lê Văn Staff', '1995-11-08', NULL,
     'ACTIVE', 0, NULL),

    -- Customer: nguoi lon (du tuoi xem T18)
    ('22222222-2222-2222-2222-222222222204', '11111111-1111-1111-1111-111111111104',
     'customer.adult@email.com', 'customer_adult', '0902000001',
     @DefaultPasswordHash, N'Phạm Minh Anh', '2000-05-20',
     N'https://example.com/avatars/customer_adult.jpg',
     'ACTIVE', 1250, '2026-06-01 10:30:00'),

    -- Customer: 14 tuoi (du T13, chua du T16/T18)
    ('22222222-2222-2222-2222-222222222205', '11111111-1111-1111-1111-111111111104',
     'customer.teen@email.com', 'customer_teen', '0902000002',
     @DefaultPasswordHash, N'Hoàng Thị Lan', '2012-01-10', NULL,
     'ACTIVE', 320, NULL),

    -- Customer: tre em (chi xem P/K)
    ('22222222-2222-2222-2222-222222222206', '11111111-1111-1111-1111-111111111104',
     NULL, NULL, '0902000003',
     @DefaultPasswordHash, N'Ngô Bảo Khang', '2018-09-05', NULL,
     'ACTIVE', 50, NULL);
GO

INSERT INTO SystemConfig (config_key, config_value, description) VALUES
    ('loyalty_earn_rate',           '1',    N'Số điểm nhận được trên mỗi 1.000đ chi tiêu (final_amount)'),
    ('loyalty_redeem_rate',         '100',  N'Số điểm cần để đổi 10.000đ giảm giá'),
    ('loyalty_min_redeem',          '100',  N'Điểm tối thiểu được phép đổi trong 1 đơn'),
    ('loyalty_max_redeem_per_order','5000', N'Điểm tối đa được đổi trong 1 đơn');
GO

INSERT INTO VatRules (id, rule_name, vat_rate, start_date, end_date, status) VALUES
    (NEWID(), N'VAT Vé Phim mặc định 10%', 10.00, '2024-01-01', NULL, 'ACTIVE');
GO

INSERT INTO CinemaInfo (id, name, address, hotline, email, opening_hours, description) VALUES
    (NEWID(),
     N'FPT Cinema Morgan',
     N'123 Đường Nguyễn Văn Cừ, Quận 5, TP.HCM',
     '1900-6868',
     'contact@movieticket.vn',
     N'08:00 – 23:00 (tất cả các ngày)',
     N'Rạp chiếu phim hiện đại với 4 phòng chiếu, hỗ trợ đặt vé online và tại quầy.');
GO

INSERT INTO SeatTypes (id, type_name, price_multiplier, description, seat_span) VALUES
    (NEWID(), 'REGULAR',  1.00, N'Ghế thường', 1),
    (NEWID(), 'VIP',      1.50, N'Ghế VIP - rộng hơn, vị trí trung tâm', 1),
    (NEWID(), 'COUPLE',   2.00, N'Ghế đôi dành cho 2 người', 2),
    (NEWID(), 'SWEETBOX', 2.50, N'Ghế sweetbox - riêng tư, có bàn nhỏ', 2);
GO

-- Chatbot: chi user da dang nhap (user_id NOT NULL)
INSERT INTO ChatbotConversations (id, user_id, session_id, created_at) VALUES
    ('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222204',
     'sess-customer-adult-001', '2026-06-01 11:00:00'),
    ('33333333-3333-3333-3333-333333333302', '22222222-2222-2222-2222-222222222205',
     'sess-customer-teen-001', '2026-06-02 09:15:00');
GO

INSERT INTO ChatbotMessages (id, conversation_id, sender_type, message_content, created_at) VALUES
    ('44444444-4444-4444-4444-444444444401', '33333333-3333-3333-3333-333333333301',
     'USER', N'Phim nào đang chiếu hôm nay?', '2026-06-01 11:00:05'),
    ('44444444-4444-4444-4444-444444444402', '33333333-3333-3333-3333-333333333301',
     'BOT', N'Bạn có thể xem danh sách phim đang chiếu tại trang chủ hoặc lọc theo ngày.', '2026-06-01 11:00:08'),
    ('44444444-4444-4444-4444-444444444403', '33333333-3333-3333-3333-333333333302',
     'USER', N'Phim T13 có suất chiếu tối nay không?', '2026-06-02 09:15:10'),
    ('44444444-4444-4444-4444-444444444404', '33333333-3333-3333-3333-333333333302',
     'BOT', N'Vui lòng chọn phim cụ thể để xem lịch chiếu chi tiết.', '2026-06-02 09:15:12');
GO

-- ============================================================
-- SEED DATA: The loai, Phong chieu, Phim mau
-- ============================================================

-- The loai phim
INSERT INTO Genres (id, genre_name, description, is_active) VALUES
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101', N'Hành động',  N'Phim hành động, võ thuật, rượt đuổi', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102', N'Viễn tưởng', N'Khoa học viễn tưởng, không gian, công nghệ', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103', N'Kinh dị',    N'Phim kinh dị, ma quái, giật gân', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104', N'Tình cảm',   N'Lãng mạn, tình cảm gia đình', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105', N'Hoạt hình',  N'Phim hoạt hình cho mọi lứa tuổi', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106', N'Hài',        N'Hài hước, giải trí nhẹ nhàng', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107', N'Chính kịch', N'Chính kịch, tâm lý xã hội', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108', N'Kịch tính',  N'Thriller, căng thẳng, bí ẩn', 1);
GO

-- Phong chieu
INSERT INTO CinemaRooms (id, room_name, capacity, status) VALUES
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01', N'Phòng 1',    120, 'ACTIVE'),
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02', N'Phòng IMAX',  80, 'ACTIVE'),
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC03', N'Phòng 3',     60, 'ACTIVE');
GO

-- Phim mau: 4 dang chieu + 4 sap chieu (backdrop_url = anh ngang hero, poster_url = anh doc)
INSERT INTO Movies (
    id, title, slug, description, duration_minutes, release_date,
    trailer_url, poster_url, backdrop_url, director, cast_members,
    language, subtitle, age_rating, status, average_rating
) VALUES
-- ─── ĐANG CHIẾU ────────────────────────────────────────────────────────────
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101',
    N'Avengers: Doomsday',
    'avengers-doomsday',
    N'Các siêu anh hùng Marvel tập hợp lần cuối để ngăn chặn Doctor Doom – kẻ phản diện quyền năng nhất vũ trụ đang âm mưu nắm quyền kiểm soát toàn bộ thực tại.',
    150, '2026-05-01',
    'https://www.youtube.com/watch?v=sOEg_YZQsTI',
    'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
    'https://image.tmdb.org/t/p/w1280/wr7l2t38C5sNYQwJMbVBiETVJzZ.jpg',
    N'Joe Russo, Anthony Russo',
    N'Robert Downey Jr., Chris Evans, Scarlett Johansson, Chris Hemsworth',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.80
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102',
    N'Mission: Impossible – The Final Reckoning',
    'mission-impossible-final-reckoning',
    N'Ethan Hunt và đội IMF đối mặt với sứ mệnh nguy hiểm nhất khi một AI siêu việt nắm giữ bí mật có thể hủy diệt toàn bộ nền văn minh nhân loại.',
    163, '2026-05-21',
    'https://www.youtube.com/watch?v=avz06PDqDbM',
    'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
    'https://image.tmdb.org/t/p/w1280/NNxYkU70HPurnNCSiCjYAmacwm.jpg',
    N'Christopher McQuarrie',
    N'Tom Cruise, Hayley Atwell, Simon Pegg, Ving Rhames',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.50
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103',
    N'Lilo & Stitch',
    'lilo-stitch-2025',
    N'Cô bé Lilo cô đơn ở Hawaii kết bạn với sinh vật ngoài hành tinh tên Stitch. Hành trình tìm kiếm ý nghĩa thật sự của gia đình sẽ thay đổi cả hai mãi mãi.',
    108, '2026-05-23',
    'https://www.youtube.com/watch?v=dJWjlMGBJ0c',
    'https://image.tmdb.org/t/p/w500/mGT7gDFqtGpYDERbmMAjUHw3TlC.jpg',
    'https://image.tmdb.org/t/p/w1280/9Va5VJOBwRBvCOZfNrmK5Dl8q9C.jpg',
    N'Dean Fleischer Camp',
    N'Maia Kealoha, Sydney Agudong, Zach Galifianakis',
    N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'NOW_SHOWING', 4.20
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104',
    N'The Housemaid',
    'the-housemaid',
    N'Một người giúp việc bí ẩn gia nhập gia đình giàu có và dần tiết lộ những bí mật đen tối đằng sau cuộc sống xa hoa tưởng chừng hoàn hảo.',
    118, '2026-04-23',
    'https://www.youtube.com/watch?v=HM9VMExYmGg',
    'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    'https://image.tmdb.org/t/p/w1280/6h20XkVx5XS7bOxSnRkGqWQqZtR.jpg',
    N'Park Chan-wook',
    N'Sydney Sweeney, Amanda Seyfried, Brandon Sklenar',
    N'Tiếng Anh', N'Phụ đề Việt', 'T18', 'NOW_SHOWING', 4.10
),
-- ─── SẮP CHIẾU ─────────────────────────────────────────────────────────────
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105',
    N'Superman',
    'superman-2025',
    N'Phiên bản Superman hoàn toàn mới trong DCU. Clark Kent học cách trở thành biểu tượng hy vọng cho nhân loại trong thế giới đầy thách thức và đe dọa.',
    132, '2026-07-11',
    'https://www.youtube.com/watch?v=mVkTFiXm0Oc',
    'https://image.tmdb.org/t/p/w500/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
    'https://image.tmdb.org/t/p/w1280/jZIYaISP3GBW9tcuu1R7CCXRB0p.jpg',
    N'James Gunn',
    N'David Corenswet, Rachel Brosnahan, Nicholas Hoult',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'COMING_SOON', 0.00
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106',
    N'How to Train Your Dragon',
    'how-to-train-your-dragon-live-action',
    N'Bản live-action của bộ phim hoạt hình huyền thoại. Hiccup và Toothless chiến đấu để bảo vệ hòa bình giữa người và rồng trước những mối đe dọa mới.',
    105, '2026-06-27',
    'https://www.youtube.com/watch?v=mQVoABqW2Sg',
    'https://image.tmdb.org/t/p/w500/sv1xJUazXeYqALzczSZ3O6nkH75.jpg',
    'https://image.tmdb.org/t/p/w1280/4v1yx8AzQGJ38kBRFiqpCHtlVaM.jpg',
    N'Dean DeBlois',
    N'Mason Thames, Nico Parker, Gerard Butler',
    N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'COMING_SOON', 0.00
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107',
    N'Jurassic World: Rebirth',
    'jurassic-world-rebirth',
    N'Năm năm sau thảm họa, khủng long đã tràn khắp địa cầu. Một nhóm thám hiểm liều lĩnh tiến vào vùng đất bí ẩn để tìm kiếm bí quyết sinh tồn cuối cùng.',
    119, '2026-07-02',
    'https://www.youtube.com/watch?v=jlHBVhBFDso',
    'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
    'https://image.tmdb.org/t/p/w1280/dR1Ju50iudrOh3YgfwkAU3LFOx5.jpg',
    N'Gareth Edwards',
    N'Scarlett Johansson, Jonathan Bailey, Mahershala Ali',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'COMING_SOON', 0.00
),
(
    'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108',
    N'Tôi Thấy Hoa Vàng Trên Cỏ Xanh 2',
    'toi-thay-hoa-vang-tren-co-xanh-2',
    N'Tiếp nối câu chuyện tuổi thơ xúc động ở làng quê miền Trung. Thiều và Tường lớn lên với những kỷ niệm trong sáng và tình yêu đầu đời không thể phai nhòa.',
    125, '2026-08-15',
    'https://www.youtube.com/watch?v=A4xwi5e0MCw',
    'https://image.tmdb.org/t/p/w500/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg',
    'https://image.tmdb.org/t/p/w1280/eI3veHGT6PJ3g3F5hBEt9BKoNcL.jpg',
    N'Victor Vũ',
    N'Thịnh Vinh, Đào Duy Phước, Lê Thị Duyên',
    N'Tiếng Việt', NULL, 'P', 'COMING_SOON', 0.00
);
GO

-- Phim - The loai (junction M-N)
INSERT INTO MovieGenres (movie_id, genre_id) VALUES
    -- Avengers: Doomsday -> Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- Mission Impossible -> Hành động, Kịch tính
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
    -- Lilo & Stitch -> Hoạt hình, Hài
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106'),
    -- The Housemaid -> Kinh dị, Kịch tính
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
    -- Superman -> Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- How to Train Your Dragon -> Hoạt hình, Hành động
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    -- Jurassic World -> Hành động, Viễn tưởng
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
    -- Hoa Vàng -> Tình cảm, Chính kịch
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104'),
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107');
GO

-- ============================================================
-- SEED FR-50: PricingRules (dynamic pricing demo)
-- ============================================================
INSERT INTO PricingRules (
    id, rule_name, condition_type, day_of_week, time_from, time_to,
    date_from, date_to, adjustment_type, adjustment_value, priority, status, created_by
) VALUES
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01',
     N'Phụ thu cuối tuần', 'DAY_OF_WEEK', '6,7', NULL, NULL,
     NULL, NULL, 'FIXED_AMOUNT', 10000, 10, 'ACTIVE',
     '22222222-2222-2222-2222-222222222202'),
    ('CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02',
     N'Phụ thu khung tối', 'TIME_RANGE', NULL, '21:00:00', '23:00:00',
     NULL, NULL, 'PERCENTAGE', 10, 5, 'ACTIVE',
     '22222222-2222-2222-2222-222222222202');
GO

-- ============================================================
-- SEED FR-22: Promotions (voucher demo — quản lý qua /admin/promotions)
-- ============================================================
INSERT INTO Promotions (
    id, code, title, description, discount_type, discount_value,
    max_discount_amount, min_order_amount, start_date, end_date, usage_limit, used_count, status
) VALUES
    ('DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD01',
     'WEEKEND10', N'Giảm 10% cuối tuần',
     N'Giảm 10% tổng vé, tối đa 50.000đ. Đơn tối thiểu 100.000đ.',
     'PERCENTAGE', 10, 50000, 100000,
     DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, 30, GETDATE()), 100, 0, 'ACTIVE'),
    ('DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD02',
     'FLAT20K', N'Giảm cố định 20.000đ',
     N'Giảm 20.000đ cho đơn từ 150.000đ trở lên.',
     'FIXED_AMOUNT', 20000, NULL, 150000,
     DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, 30, GETDATE()), 50, 0, 'ACTIVE');
GO

-- ============================================================
-- SEED DATA: Suat chieu, ghe, don dat ve mau — test Admin bao cao
-- Ky vong thang 6/2026: 4 don PAID, 9 ve, doanh thu 1.166.000 VND
-- Top phim: Avengers (5 ve) > Mission (2 ve) > Housemaid (2 ve)
-- SEED-STATS-007 (PENDING) khong tinh vao thong ke
-- ============================================================

DECLARE @StatsRegularType UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM SeatTypes WHERE type_name = N'REGULAR');
DECLARE @StatsVipType     UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM SeatTypes WHERE type_name = N'VIP');
DECLARE @StatsManagerId   UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222202';
DECLARE @StatsStaffId     UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222203';
DECLARE @StatsCustomerId  UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222204';
DECLARE @StatsRoom1       UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01';
DECLARE @StatsRoom2       UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02';
DECLARE @StatsRoom3       UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC03';

INSERT INTO Seats (id, room_id, seat_type_id, seat_row, seat_column, seat_code, status) VALUES
    ('66666666-6666-6666-6666-666666666601', @StatsRoom1, @StatsRegularType, N'A', 1, N'A1', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666602', @StatsRoom1, @StatsRegularType, N'A', 2, N'A2', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666603', @StatsRoom1, @StatsRegularType, N'A', 3, N'A3', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666604', @StatsRoom1, @StatsRegularType, N'B', 1, N'B1', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666605', @StatsRoom1, @StatsRegularType, N'B', 2, N'B2', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666606', @StatsRoom2, @StatsVipType,     N'A', 1, N'A1', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666607', @StatsRoom2, @StatsVipType,     N'A', 2, N'A2', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666608', @StatsRoom2, @StatsRegularType, N'A', 3, N'A3', 'ACTIVE'),
    ('66666666-6666-6666-6666-666666666609', @StatsRoom3, @StatsRegularType, N'A', 1, N'A1', 'ACTIVE');

INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by) VALUES
    ('55555555-5555-5555-5555-555555555501', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', @StatsRoom1, '2026-06-05 18:00:00', '2026-06-05 20:30:00', 100000, 'FINISHED',  @StatsManagerId),
    ('55555555-5555-5555-5555-555555555502', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', @StatsRoom1, '2026-06-08 20:00:00', '2026-06-08 22:30:00', 100000, 'FINISHED',  @StatsManagerId),
    ('55555555-5555-5555-5555-555555555503', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', @StatsRoom2, '2026-06-07 19:00:00', '2026-06-07 21:43:00', 120000, 'FINISHED',  @StatsManagerId),
    ('55555555-5555-5555-5555-555555555504', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', @StatsRoom3, '2026-05-28 14:00:00', '2026-05-28 15:48:00',  80000,  'FINISHED', @StatsManagerId),
    ('55555555-5555-5555-5555-555555555505', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', @StatsRoom1, '2026-06-03 21:00:00', '2026-06-03 22:58:00', 100000, 'FINISHED',  @StatsManagerId),
    ('55555555-5555-5555-5555-555555555506', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', @StatsRoom2, '2026-05-15 18:00:00', '2026-05-15 20:43:00', 100000, 'FINISHED', @StatsManagerId);

INSERT INTO Bookings (
    id, booking_code, user_id, showtime_id, booking_source,
    created_by_staff_id, customer_name, customer_phone,
    vat_rate_snapshot, total_amount, discount_amount, final_amount,
    booking_status, payment_status, booked_at
) VALUES
    ('77777777-7777-7777-7777-777777777701', 'SEED-STATS-001', NULL, '55555555-5555-5555-5555-555555555501', 'OFFLINE',
     @StatsStaffId, N'Nguyen Van A', '0903000001', 10.00, 300000, 0, 330000, 'CONFIRMED', 'PAID', '2026-06-05 18:05:00'),
    ('77777777-7777-7777-7777-777777777702', 'SEED-STATS-002', @StatsCustomerId, '55555555-5555-5555-5555-555555555502', 'ONLINE',
     NULL, NULL, NULL, 10.00, 200000, 0, 220000, 'CONFIRMED', 'PAID', '2026-06-08 20:10:00'),
    ('77777777-7777-7777-7777-777777777703', 'SEED-STATS-003', NULL, '55555555-5555-5555-5555-555555555503', 'OFFLINE',
     @StatsStaffId, N'Tran Thi B', '0903000002', 10.00, 360000, 0, 396000, 'CONFIRMED', 'PAID', '2026-06-07 19:15:00'),
    ('77777777-7777-7777-7777-777777777704', 'SEED-STATS-004', @StatsCustomerId, '55555555-5555-5555-5555-555555555504', 'ONLINE',
     NULL, NULL, NULL, 10.00, 80000, 0, 88000, 'CONFIRMED', 'PAID', '2026-05-28 14:05:00'),
    ('77777777-7777-7777-7777-777777777705', 'SEED-STATS-005', NULL, '55555555-5555-5555-5555-555555555505', 'OFFLINE',
     @StatsStaffId, N'Le Van C', '0903000003', 10.00, 200000, 0, 220000, 'CONFIRMED', 'PAID', '2026-06-03 21:05:00'),
    ('77777777-7777-7777-7777-777777777706', 'SEED-STATS-006', @StatsCustomerId, '55555555-5555-5555-5555-555555555506', 'ONLINE',
     NULL, NULL, NULL, 10.00, 180000, 0, 198000, 'CONFIRMED', 'PAID', '2026-05-15 18:10:00'),
    ('77777777-7777-7777-7777-777777777707', 'SEED-STATS-007', @StatsCustomerId, '55555555-5555-5555-5555-555555555501', 'ONLINE',
     NULL, NULL, NULL, 10.00, 100000, 0, 110000, 'PENDING', 'UNPAID', '2026-06-09 10:00:00');

INSERT INTO BookingSeats (id, booking_id, seat_id, ticket_price) VALUES
    ('88888888-8888-8888-8888-888888888801', '77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666601', 100000),
    ('88888888-8888-8888-8888-888888888802', '77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666602', 100000),
    ('88888888-8888-8888-8888-888888888803', '77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666603', 100000),
    ('88888888-8888-8888-8888-888888888804', '77777777-7777-7777-7777-777777777702', '66666666-6666-6666-6666-666666666604', 100000),
    ('88888888-8888-8888-8888-888888888805', '77777777-7777-7777-7777-777777777702', '66666666-6666-6666-6666-666666666605', 100000),
    ('88888888-8888-8888-8888-888888888806', '77777777-7777-7777-7777-777777777703', '66666666-6666-6666-6666-666666666606', 180000),
    ('88888888-8888-8888-8888-888888888807', '77777777-7777-7777-7777-777777777703', '66666666-6666-6666-6666-666666666607', 180000),
    ('88888888-8888-8888-8888-888888888808', '77777777-7777-7777-7777-777777777704', '66666666-6666-6666-6666-666666666609', 80000),
    ('88888888-8888-8888-8888-888888888809', '77777777-7777-7777-7777-777777777705', '66666666-6666-6666-6666-666666666601', 100000),
    ('88888888-8888-8888-8888-888888888810', '77777777-7777-7777-7777-777777777705', '66666666-6666-6666-6666-666666666602', 100000),
    ('88888888-8888-8888-8888-888888888811', '77777777-7777-7777-7777-777777777706', '66666666-6666-6666-6666-666666666608', 180000),
    ('88888888-8888-8888-8888-888888888812', '77777777-7777-7777-7777-777777777707', '66666666-6666-6666-6666-666666666603', 100000);
GO

-- ============================================================
-- KIEM TRA KET QUA
-- ============================================================
PRINT N'';
PRINT N'=== KET QUA SEED ===';

SELECT
    m.title,
    m.status,
    m.average_rating AS rating,
    CASE WHEN m.backdrop_url IS NOT NULL THEN N'Y' ELSE N'N' END AS has_backdrop,
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
GROUP BY m.id, m.title, m.status, m.average_rating, m.backdrop_url
ORDER BY m.average_rating DESC;
GO

PRINT N'';
PRINT N'=== SEED STATS (don SEED-STATS-*) ===';

SELECT
    b.booking_code,
    m.title AS movie,
    b.booking_status,
    b.payment_status,
    b.final_amount,
    (SELECT COUNT(*) FROM BookingSeats bs WHERE bs.booking_id = b.id) AS seats
FROM Bookings b
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE b.booking_code LIKE 'SEED-STATS-%'
ORDER BY b.booked_at;
GO

PRINT N'=== Hoan tat seed_data.sql (30 bang schema da tao boi create_database.sql) ===';
PRINT N'=== Tai khoan seed: mat khau mac dinh Password@123 (BCrypt) ===';
PRINT N'=== Phim mau: 4 dang chieu + 4 sap chieu ===';
PRINT N'=== Thong ke test: 6 don PAID + 1 PENDING (SEED-STATS-*) ===';
PRINT N'=== Schema: create_database.sql | Seed: seed_data.sql | migrations/ chi DB cu ===';
GO
