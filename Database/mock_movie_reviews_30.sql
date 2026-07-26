-- ============================================================
-- Mock data: 30 danh gia phim (MovieReviews) cua Customer
-- Chay sau create_database.sql.
-- Schema chi cho 1 danh gia / (phim, khach hang) -- UK_MovieReviews_UserMovie.
-- Seed goc chi co 3 tai khoan Customer (204/205/206) x 8 phim = toi da 24 cap,
-- khong du cho 30 dong nen script nay tao them 10 Customer mock (207-216)
-- roi rai 30 danh gia qua 13 khach hang x 8 phim.
-- ============================================================
USE MovieTicketDB;
GO

DECLARE @CustomerRoleId   UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111104';
DECLARE @DefaultPwdHash   NVARCHAR(255)    = '$2a$10$cQtXPt5hVH2nDDhuXFDxQ.aKttyB7S7/6jR.xyULrEfcnUFA8UCM6'; -- Password@123

-- ── 10 Customer mock them (207-216) ─────────────────────────────────────
INSERT INTO Users (id, role_id, email, username, phone_number, password_hash, full_name, date_of_birth, avatar_url, status, loyalty_points, last_login_at) VALUES
('22222222-2222-2222-2222-222222222207', @CustomerRoleId, 'customer1@email.com',  'cust01', '0902000010', @DefaultPwdHash, N'Nguyễn Thị Hồng', '1998-02-14', NULL, 'ACTIVE', 80,  '2026-07-10 09:00:00'),
('22222222-2222-2222-2222-222222222208', @CustomerRoleId, 'customer2@email.com',  'cust02', '0902000011', @DefaultPwdHash, N'Trần Văn Long',   '1995-06-22', NULL, 'ACTIVE', 150, '2026-07-12 14:20:00'),
('22222222-2222-2222-2222-222222222209', @CustomerRoleId, 'customer3@email.com',  'cust03', '0902000012', @DefaultPwdHash, N'Lê Thị Mai',      '2001-11-03', NULL, 'ACTIVE', 40,  '2026-07-14 19:45:00'),
('22222222-2222-2222-2222-222222222210', @CustomerRoleId, 'customer4@email.com',  'cust04', '0902000013', @DefaultPwdHash, N'Phạm Văn Đức',    '1993-09-17', NULL, 'ACTIVE', 220, '2026-07-16 20:10:00'),
('22222222-2222-2222-2222-222222222211', @CustomerRoleId, 'customer5@email.com',  'cust05', '0902000014', @DefaultPwdHash, N'Vũ Thị Thu',      '1999-04-05', NULL, 'ACTIVE', 60,  '2026-07-18 11:30:00'),
('22222222-2222-2222-2222-222222222212', @CustomerRoleId, 'customer6@email.com',  'cust06', '0902000015', @DefaultPwdHash, N'Đặng Văn Hùng',   '1990-12-25', NULL, 'ACTIVE', 300, '2026-07-19 21:00:00'),
('22222222-2222-2222-2222-222222222213', @CustomerRoleId, 'customer7@email.com',  'cust07', '0902000016', @DefaultPwdHash, N'Bùi Thị Ngọc',    '2003-07-30', NULL, 'ACTIVE', 25,  '2026-07-20 15:15:00'),
('22222222-2222-2222-2222-222222222214', @CustomerRoleId, 'customer8@email.com',  'cust08', '0902000017', @DefaultPwdHash, N'Đỗ Văn Kiên',     '1997-01-19', NULL, 'ACTIVE', 110, '2026-07-21 10:05:00'),
('22222222-2222-2222-2222-222222222215', @CustomerRoleId, 'customer9@email.com',  'cust09', '0902000018', @DefaultPwdHash, N'Hồ Thị Linh',     '1996-08-08', NULL, 'ACTIVE', 90,  '2026-07-22 18:40:00'),
('22222222-2222-2222-2222-222222222216', @CustomerRoleId, 'customer10@email.com', 'cust10', '0902000019', @DefaultPwdHash, N'Ngô Văn Phúc',    '1994-03-27', NULL, 'ACTIVE', 175, '2026-07-23 13:25:00');
GO

-- ── 30 danh gia phim ─────────────────────────────────────────────────
INSERT INTO MovieReviews (id, movie_id, user_id, rating, review_content, created_at) VALUES
('88888888-8888-8888-8888-888888888801', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', '22222222-2222-2222-2222-222222222204', 5, N'Kỹ xảo hoành tráng, cốt truyện lôi cuốn từ đầu đến cuối. Rất đáng xem ở rạp!', '2026-06-10 20:15:00'),
('88888888-8888-8888-8888-888888888802', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', '22222222-2222-2222-2222-222222222207', 4, N'Phim hay nhưng hơi dài, đoạn giữa có phần lê thê.', '2026-06-11 08:30:00'),
('88888888-8888-8888-8888-888888888803', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', '22222222-2222-2222-2222-222222222208', 5, N'Một trong những phim siêu anh hùng hay nhất năm nay.', '2026-06-12 21:00:00'),
('88888888-8888-8888-8888-888888888804', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', '22222222-2222-2222-2222-222222222209', 3, N'Bình thường, kỳ vọng nhiều hơn so với trailer.', '2026-06-13 17:45:00'),

('88888888-8888-8888-8888-888888888805', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', '22222222-2222-2222-2222-222222222205', 4, N'Diễn xuất tốt, các pha hành động mãn nhãn.', '2026-06-14 19:20:00'),
('88888888-8888-8888-8888-888888888806', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', '22222222-2222-2222-2222-222222222210', 5, N'Tom Cruise vẫn đỉnh như mọi khi, cảnh hành động thật đến nghẹt thở.', '2026-06-15 22:10:00'),
('88888888-8888-8888-8888-888888888807', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', '22222222-2222-2222-2222-222222222211', 5, N'Xứng đáng là phần kết hoàn hảo cho series.', '2026-06-16 20:00:00'),
('88888888-8888-8888-8888-888888888808', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', '22222222-2222-2222-2222-222222222212', 2, N'Kịch bản hơi rối, khó theo dõi nếu chưa xem phần trước.', '2026-06-17 09:15:00'),

('88888888-8888-8888-8888-888888888809', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', '22222222-2222-2222-2222-222222222206', 5, N'Phim hoạt hình dễ thương, cả nhà cùng xem được.', '2026-06-18 16:30:00'),
('88888888-8888-8888-8888-888888888810', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', '22222222-2222-2222-2222-222222222213', 4, N'Hình ảnh đẹp mắt, nhạc phim rất cuốn.', '2026-06-19 14:00:00'),
('88888888-8888-8888-8888-888888888811', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', '22222222-2222-2222-2222-222222222214', 4, N'Con mình xem rất thích, cười suốt cả phim.', '2026-06-20 18:45:00'),

('88888888-8888-8888-8888-888888888812', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', '22222222-2222-2222-2222-222222222215', 5, N'Phim kinh dị đúng chất, hù dọa đúng lúc, không bị nhàm.', '2026-06-21 22:30:00'),
('88888888-8888-8888-8888-888888888813', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', '22222222-2222-2222-2222-222222222216', 3, N'Jumpscare hơi lạm dụng nhưng tổng thể ổn.', '2026-06-22 21:15:00'),
('88888888-8888-8888-8888-888888888814', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', '22222222-2222-2222-2222-222222222204', 4, N'Không khí phim rất căng thẳng, xem xong ám ảnh vài ngày.', '2026-06-23 20:00:00'),

('88888888-8888-8888-8888-888888888815', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', '22222222-2222-2222-2222-222222222207', 4, N'Phim hài nhẹ nhàng, giải trí cuối tuần rất hợp.', '2026-06-24 15:20:00'),
('88888888-8888-8888-8888-888888888816', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', '22222222-2222-2222-2222-222222222208', 5, N'Cười từ đầu đến cuối, diễn viên chính diễn quá duyên.', '2026-06-25 19:40:00'),
('88888888-8888-8888-8888-888888888817', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA105', '22222222-2222-2222-2222-222222222209', 3, N'Vui nhưng một số đoạn hơi gượng.', '2026-06-26 17:10:00'),

('88888888-8888-8888-8888-888888888818', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', '22222222-2222-2222-2222-222222222210', 5, N'Kịch bản chặt chẽ, plot twist bất ngờ ở cuối phim.', '2026-06-27 21:50:00'),
('88888888-8888-8888-8888-888888888819', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', '22222222-2222-2222-2222-222222222211', 4, N'Diễn xuất của dàn cast rất tự nhiên và cảm xúc.', '2026-06-28 20:30:00'),
('88888888-8888-8888-8888-888888888820', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', '22222222-2222-2222-2222-222222222212', 5, N'Một trong những phim tâm lý hay nhất mình từng xem.', '2026-06-29 22:00:00'),

('88888888-8888-8888-8888-888888888821', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', '22222222-2222-2222-2222-222222222213', 4, N'Đáng mong chờ, hình ảnh preview rất chất lượng.', '2026-07-01 10:00:00'),
('88888888-8888-8888-8888-888888888822', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', '22222222-2222-2222-2222-222222222214', 5, N'Trailer xem đã thấy hứa hẹn bom tấn cuối năm.', '2026-07-02 11:30:00'),
('88888888-8888-8888-8888-888888888823', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA107', '22222222-2222-2222-2222-222222222215', 3, N'Hy vọng nội dung không chỉ dựa vào kỹ xảo.', '2026-07-03 09:45:00'),

('88888888-8888-8888-8888-888888888824', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', '22222222-2222-2222-2222-222222222216', 4, N'Chủ đề mới lạ, mong sớm được xem full.', '2026-07-04 12:20:00'),
('88888888-8888-8888-8888-888888888825', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', '22222222-2222-2222-2222-222222222204', 4, N'Diễn viên chính rất hợp vai theo trailer.', '2026-07-05 13:10:00'),
('88888888-8888-8888-8888-888888888826', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA108', '22222222-2222-2222-2222-222222222205', 5, N'Nhạc phim trong trailer đã cuốn rồi, chờ ngày công chiếu.', '2026-07-06 14:50:00'),

('88888888-8888-8888-8888-888888888827', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', '22222222-2222-2222-2222-222222222210', 5, N'Xem lại lần 2 vẫn thấy hay, đáng đồng tiền bát gạo.', '2026-07-07 20:20:00'),
('88888888-8888-8888-8888-888888888828', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', '22222222-2222-2222-2222-222222222213', 4, N'Âm thanh rạp rất đã, nên xem suất IMAX.', '2026-07-08 21:40:00'),
('88888888-8888-8888-8888-888888888829', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', '22222222-2222-2222-2222-222222222216', 5, N'Xem cùng con lần thứ hai vẫn thấy vui.', '2026-07-09 16:00:00'),
('88888888-8888-8888-8888-888888888830', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA106', '22222222-2222-2222-2222-222222222215', 4, N'Kết phim để mở, hy vọng có phần 2.', '2026-07-10 22:15:00');
GO
