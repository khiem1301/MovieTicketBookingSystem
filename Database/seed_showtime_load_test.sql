    /*
    ====================================================================
    ÉPCINE — Seed load-test: nhiều phim + lịch chiếu dày
    --------------------------------------------------------------------
    Mục đích: kiểm thử màn /manager/showtimes (lọc 7 ngày, lịch phòng,
                hàng loạt, ghế đã bán, trạng thái, buffer 15 phút).

    Cách chạy (SSMS / Azure Data Studio):
        1. Chọn database MovieTicketDB
        2. Mở file này → Ctrl+A → F5

    An toàn:
        - Chỉ xóa/ghi đè data của chính seed này (slug seed-load-*).
        - Không đụng đơn vé / seed báo cáo SEED-STATS-*.
        - Có thể chạy lại nhiều lần (idempotent).

    Kỳ vọng sau khi chạy:
        - ~12 phim mới (NOW_SHOWING + COMING_SOON)
        - ~225 suất quanh cửa sổ [-7 .. +7] ngày (15 ngày × 3 phòng × 5 khung)
        · Ngày đã qua → FINISHED
        · Ngày đã qua → FINISHED · Đang chiếu → SHOWING · Sắp tới → SCHEDULED (+ mẫu CANCELLED)
    ====================================================================
    */
    USE MovieTicketDB;
    GO

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ManagerId UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222202';
    DECLARE @Room1     UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01';
    DECLARE @Room2     UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02';
    DECLARE @Room3     UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC03';
    DECLARE @BufferMin INT = 15;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE id = @ManagerId)
    BEGIN
        RAISERROR(N'Không tìm thấy manager seed (2222...202). Hãy chạy create_database.sql trước.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM CinemaRooms WHERE id IN (@Room1, @Room2, @Room3) AND status = 'ACTIVE')
    BEGIN
        RAISERROR(N'Thiếu phòng chiếu ACTIVE seed. Hãy chạy create_database.sql trước.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

------------------------------------------------------------
-- 1) Dọn seed cũ (chỉ phim seed-load-* và suất của chúng)
--    Tickets → booking_seat_id (không có booking_id)
------------------------------------------------------------
DELETE t
FROM Tickets t
JOIN BookingSeats bs ON bs.id = t.booking_seat_id
JOIN Bookings b ON b.id = bs.booking_id
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE p
FROM Payments p
JOIN Bookings b ON b.id = p.booking_id
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE bp
FROM BookingPromotions bp
JOIN Bookings b ON b.id = bp.booking_id
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE lp
FROM LoyaltyPointsLog lp
JOIN Bookings b ON b.id = lp.booking_id
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE bs
FROM BookingSeats bs
JOIN Bookings b ON b.id = bs.booking_id
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE b
FROM Bookings b
JOIN Showtimes s ON s.id = b.showtime_id
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE s
FROM Showtimes s
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE mg
FROM MovieGenres mg
JOIN Movies m ON m.id = mg.movie_id
WHERE m.slug LIKE N'seed-load-%';

DELETE FROM Movies WHERE slug LIKE N'seed-load-%';

    ------------------------------------------------------------
    -- 2) Thêm phim mới
    ------------------------------------------------------------
    INSERT INTO Movies (
        id, title, slug, description, duration_minutes, release_date,
        trailer_url, poster_url, backdrop_url, director, cast_members,
        language, subtitle, age_rating, status, average_rating
    ) VALUES
    -- NOW_SHOWING
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA201', N'Dune: Part Three', 'seed-load-dune-3',
    N'Phần kết sử thi Arrakis — Paul Atreides đối mặt với định mệnh của vũ trụ.',
    155, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=8g18jFHCLXk',
    'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94aAgEaGAH.jpg',
    'https://image.tmdb.org/t/p/w1280/zH5GzMzRi0SpWSoPh2GDBoZKXVn.jpg',
    N'Denis Villeneuve', N'Timothée Chalamet, Zendaya, Florence Pugh',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.70),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA202', N'Inside Out 3', 'seed-load-inside-out-3',
    N'Những cảm xúc của Riley bước sang chương mới khi tuổi teen đầy biến động.',
    110, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=LEjhY15eCx0',
    'https://image.tmdb.org/t/p/w500/2E1x1qcHqGZcYuYi4PzV8v8m5Jq.jpg',
    'https://image.tmdb.org/t/p/w1280/stKJG7Xh5L1GhxLpEQTg6X0pkFt.jpg',
    N'Kelsey Mann', N'Amy Poehler, Maya Hawke, Phyllis Smith',
    N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'NOW_SHOWING', 4.40),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA203', N'Top Gun: Maverick Legacy', 'seed-load-topgun-legacy',
    N'Maverick huấn luyện thế hệ phi công mới trước một nhiệm vụ không thể thất bại.',
    131, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=giXco2jaZ_4',
    'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
    'https://image.tmdb.org/t/p/w1280/odJ4wxkZ4Pt7hZceYAk3yW6XLrk.jpg',
    N'Joseph Kosinski', N'Tom Cruise, Miles Teller, Jennifer Connelly',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'NOW_SHOWING', 4.60),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA204', N'Conjuring: Last Rites', 'seed-load-conjuring-last',
    N'Ed và Lorraine Warren đối mặt vụ án cuối cùng — và đáng sợ nhất sự nghiệp.',
    122, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=k10ETZNeIQc',
    'https://image.tmdb.org/t/p/w500/wVYREutTvI2tmxr6ujrHT704wGF.jpg',
    'https://image.tmdb.org/t/p/w1280/9n2tJBplPbgR2ca05hS5KVQ9b2Z.jpg',
    N'Michael Chaves', N'Patrick Wilson, Vera Farmiga',
    N'Tiếng Anh', N'Phụ đề Việt', 'T16', 'NOW_SHOWING', 4.00),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA205', N'Mai (Special Cut)', 'seed-load-mai-special',
    N'Bản chiếu đặc biệt của câu chuyện tình cảm Việt Nam gây sốt phòng vé.',
    131, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=bxj9vipcgA0',
    'https://image.tmdb.org/t/p/w500/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg',
    'https://image.tmdb.org/t/p/w1280/eI3veHGT6PJ3g3F5hBEt9BKoNcL.jpg',
    N'Trấn Thành', N'Phương Anh Đào, Tuấn Trần',
    N'Tiếng Việt', NULL, 'T16', 'NOW_SHOWING', 4.30),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA206', N'Oppenheimer Reloaded', 'seed-load-oppenheimer',
    N'Tái chiếu IMAX — hành trình tạo ra quả bom nguyên tử và cái giá phải trả.',
    180, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=uYgLFpN8H_I',
    'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    'https://image.tmdb.org/t/p/w1280/fm6KqXpk3FIQhHm1kw5KiJ9t4sJ.jpg',
    N'Christopher Nolan', N'Cillian Murphy, Emily Blunt, Robert Downey Jr.',
    N'Tiếng Anh', N'Phụ đề Việt', 'T16', 'NOW_SHOWING', 4.90),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA207', N'Elemental 2', 'seed-load-elemental-2',
    N'Thành phố các nguyên tố đón thêm thế hệ mới với tình bạn khó tin.',
    109, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=hXzcyx9V0XQ',
    'https://image.tmdb.org/t/p/w500/4Y1WNkd88JXmGfhtWR7dmDAo1T2.jpg',
    'https://image.tmdb.org/t/p/w1280/4fLZUr1e65hKPPVw0R3PmKFKxj1.jpg',
    N'Peter Sohn', N'Leah Lewis, Mamoudou Athie',
    N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'NOW_SHOWING', 4.10),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA208', N'John Wick: Chapter 5', 'seed-load-john-wick-5',
    N'John Wick trở lại khi thế giới sát thủ mở ra một chương luật lệ mới.',
    140, CAST(GETDATE() AS DATE),
    'https://www.youtube.com/watch?v=qEVUtrk8kYc',
    'https://image.tmdb.org/t/p/w500/vZloFAK7NmvMGVE7OKiuMHrIClO.jpg',
    'https://image.tmdb.org/t/p/w1280/7ZP8HtgOIDaBs12kr7kl9YHl0HK.jpg',
    N'Chad Stahelski', N'Keanu Reeves, Donnie Yen, Bill Skarsgård',
    N'Tiếng Anh', N'Phụ đề Việt', 'T18', 'NOW_SHOWING', 4.50),

    -- COMING_SOON
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA209', N'Avatar 4: The Tulkun Path', 'seed-load-avatar-4',
    N'Jake và Neytiri dẫn dắt gia đình đối mặt mối đe dọa từ đại dương Pandora.',
    170, DATEADD(DAY, 40, CAST(GETDATE() AS DATE)),
    'https://www.youtube.com/watch?v=d9MyW72ELq0',
    'https://image.tmdb.org/t/p/w500/t6X2WylyEe73mvpKcSaOU1RDoZW.jpg',
    'https://image.tmdb.org/t/p/w1280/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg',
    N'James Cameron', N'Sam Worthington, Zoe Saldaña, Sigourney Weaver',
    N'Tiếng Anh', N'Phụ đề Việt', 'T13', 'COMING_SOON', 0.00),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA210', N'Frozen III', 'seed-load-frozen-3',
    N'Elsa và Anna khám phá vùng đất băng giá chưa từng biết tới.',
    112, DATEADD(DAY, 50, CAST(GETDATE() AS DATE)),
    'https://www.youtube.com/watch?v=TbQm5doF_Uc',
    'https://image.tmdb.org/t/p/w500/kgwjIb2JDHRhNkuedDbSKidjTw2.jpg',
    'https://image.tmdb.org/t/p/w1280/xJWPZIYOEFIjZpBL7SVBGwojYgA.jpg',
    N'Jennifer Lee', N'Idina Menzel, Kristen Bell, Josh Gad',
    N'Tiếng Anh', N'Lồng tiếng Việt', 'P', 'COMING_SOON', 0.00),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA211', N'Mắt Biếc: Chương Mới', 'seed-load-mat-biec-2',
    N'Tiếp nối mối tình Ngạn – Hà Lan giữa những lựa chọn tuổi trưởng thành.',
    128, DATEADD(DAY, 35, CAST(GETDATE() AS DATE)),
    'https://www.youtube.com/watch?v=KS2oYxj-Y5E',
    'https://image.tmdb.org/t/p/w500/4lpDsI4jYgJv7x9bvvUBXLHQSRi.jpg',
    'https://image.tmdb.org/t/p/w1280/eI3veHGT6PJ3g3F5hBEt9BKoNcL.jpg',
    N'Victor Vũ', N'Trần Nghĩa, Trúc Anh',
    N'Tiếng Việt', NULL, 'T13', 'COMING_SOON', 0.00),

    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA212', N'The Batman Part II', 'seed-load-batman-2',
    N'Bruce Wayne lần theo âm mưu mới phủ bóng lên Gotham.',
    165, DATEADD(DAY, 60, CAST(GETDATE() AS DATE)),
    'https://www.youtube.com/watch?v=mqqft2x_Aa4',
    'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    'https://image.tmdb.org/t/p/w1280/b0PlSFdDwbyK0cf5RxwDpaOJQvQ.jpg',
    N'Matt Reeves', N'Robert Pattinson, Zoë Kravitz, Jeffrey Wright',
    N'Tiếng Anh', N'Phụ đề Việt', 'T16', 'COMING_SOON', 0.00);

    INSERT INTO MovieGenres (movie_id, genre_id) VALUES
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA201', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA201', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA202', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA202', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA203', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA203', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA204', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA204', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA205', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA205', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA206', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA206', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA207', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA207', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA208', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA208', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA209', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA209', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA210', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA210', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA211', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA211', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA212', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101'),
        ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA212', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108');

    ------------------------------------------------------------
    -- 3) Sinh lịch quanh 7 ngày gần đây: [-7 .. +7] × 3 phòng × 5 khung
    --    Quá khứ → FINISHED | Đang chiếu → SHOWING | Tương lai → SCHEDULED (+ vài CANCELLED mẫu)
    ------------------------------------------------------------
    DECLARE @Movies TABLE (
        rn INT IDENTITY(1,1) PRIMARY KEY,
        movie_id UNIQUEIDENTIFIER,
        duration_minutes INT,
        base_price DECIMAL(12,2)
    );

    INSERT INTO @Movies (movie_id, duration_minutes, base_price)
    SELECT m.id, m.duration_minutes,
        CASE
            WHEN m.duration_minutes >= 160 THEN 120000
            WHEN m.duration_minutes >= 140 THEN 100000
            ELSE 85000
        END
    FROM Movies m
    WHERE m.status = 'NOW_SHOWING'
    AND m.slug LIKE N'seed-load-%'
    ORDER BY m.title;

    DECLARE @MovieCount INT = (SELECT COUNT(*) FROM @Movies);
    IF @MovieCount = 0
    BEGIN
        ROLLBACK;
        RAISERROR(N'Không có phim seed-load NOW_SHOWING để xếp lịch.', 16, 1);
        RETURN;
    END;

    DECLARE @Rooms TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, room_id UNIQUEIDENTIFIER);
    INSERT INTO @Rooms (room_id) VALUES (@Room1), (@Room2), (@Room3);

    -- 5 khung/ngày, đủ buffer 15' kể cả phim ~180'
    DECLARE @Slots TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, start_hm TIME);
    INSERT INTO @Slots (start_hm) VALUES
        ('08:00'), ('11:30'), ('15:00'), ('18:30'), ('22:00');

    DECLARE @DayFrom INT = -7;
    DECLARE @DayTo   INT =  7;
    DECLARE @DayOffset INT = @DayFrom;
    DECLARE @Inserted INT = 0;
    DECLARE @Skipped INT = 0;
    DECLARE @Pick INT = 1;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    WHILE @DayOffset <= @DayTo
    BEGIN
        DECLARE @ShowDate DATE = DATEADD(DAY, @DayOffset, @Today);
        DECLARE @RoomRn INT = 1;

        WHILE @RoomRn <= 3
        BEGIN
            DECLARE @RoomId UNIQUEIDENTIFIER = (SELECT room_id FROM @Rooms WHERE rn = @RoomRn);
            DECLARE @SlotRn INT = 1;
            DECLARE @SlotCount INT = (SELECT COUNT(*) FROM @Slots);

            WHILE @SlotRn <= @SlotCount
            BEGIN
                DECLARE @StartHm TIME = (SELECT start_hm FROM @Slots WHERE rn = @SlotRn);
                DECLARE @MovieId UNIQUEIDENTIFIER;
                DECLARE @Dur INT;
                DECLARE @Price DECIMAL(12,2);

                SELECT @MovieId = movie_id, @Dur = duration_minutes, @Price = base_price
                FROM @Movies
                WHERE rn = ((@Pick - 1) % @MovieCount) + 1;

                DECLARE @StartDt DATETIME2 = DATETIME2FROMPARTS(
                    YEAR(@ShowDate), MONTH(@ShowDate), DAY(@ShowDate),
                    DATEPART(HOUR, @StartHm), DATEPART(MINUTE, @StartHm), 0, 0, 0);
                DECLARE @EndDt DATETIME2 = DATEADD(MINUTE, @Dur, @StartDt);

                IF EXISTS (
                    SELECT 1
                    FROM Showtimes s
                    WHERE s.room_id = @RoomId
                    AND s.status <> 'CANCELLED'
                    AND s.start_time < DATEADD(MINUTE, @BufferMin, @EndDt)
                    AND DATEADD(MINUTE, @BufferMin, s.end_time) > @StartDt
                )
                BEGIN
                    SET @Skipped += 1;
                END
                ELSE
                BEGIN
                    DECLARE @Status NVARCHAR(20);

                    IF @EndDt < SYSDATETIME()
                        SET @Status = 'FINISHED';
                    ELSE IF @StartDt <= SYSDATETIME() AND @EndDt >= SYSDATETIME()
                        SET @Status = 'SHOWING';
                    ELSE IF @DayOffset = 1 AND @SlotRn = 2
                        SET @Status = 'CANCELLED';
                    ELSE
                        SET @Status = 'SCHEDULED';

                    IF @RoomId = @Room2 SET @Price = @Price + 20000;

                    INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
                    VALUES (NEWID(), @MovieId, @RoomId, @StartDt, @EndDt, @Price, @Status, @ManagerId);

                    SET @Inserted += 1;
                END

                SET @Pick += 1;
                SET @SlotRn += 1;
            END

            SET @RoomRn += 1;
        END

        SET @DayOffset += 1;
    END;

    ------------------------------------------------------------
    -- 4) Vài suất COMING_SOON (+7 ngày) để test xếp lịch sớm
    --    Dùng khung giờ trống giữa các slot chính (11:00 / 15:30)
    ------------------------------------------------------------
    DECLARE @SoonDay DATE = DATEADD(DAY, 20, CAST(GETDATE() AS DATE));

    -- Avatar 4 → Phòng 2 lúc 11:00
    IF NOT EXISTS (
        SELECT 1 FROM Showtimes s
        WHERE s.room_id = @Room2 AND s.status <> 'CANCELLED'
        AND s.start_time < DATEADD(MINUTE, @BufferMin, DATEADD(MINUTE, 170,
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)))
        AND DATEADD(MINUTE, @BufferMin, s.end_time) >
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)
    )
    INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
    VALUES (
        NEWID(),
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA209',
        @Room2,
        DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0),
        DATEADD(MINUTE, 170, DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)),
        115000, 'SCHEDULED', @ManagerId
    );

    -- Frozen III → Phòng 3 lúc 11:00
    IF NOT EXISTS (
        SELECT 1 FROM Showtimes s
        WHERE s.room_id = @Room3 AND s.status <> 'CANCELLED'
        AND s.start_time < DATEADD(MINUTE, @BufferMin, DATEADD(MINUTE, 112,
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)))
        AND DATEADD(MINUTE, @BufferMin, s.end_time) >
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)
    )
    INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
    VALUES (
        NEWID(),
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA210',
        @Room3,
        DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0),
        DATEADD(MINUTE, 112, DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 11, 0, 0, 0, 0)),
        90000, 'SCHEDULED', @ManagerId
    );

    -- Mắt Biếc 2 → Phòng 1 lúc 15:30 (giữa 13:00 và 17:00 — có thể skip nếu phim dài buổi trưa)
    IF NOT EXISTS (
        SELECT 1 FROM Showtimes s
        WHERE s.room_id = @Room1 AND s.status <> 'CANCELLED'
        AND s.start_time < DATEADD(MINUTE, @BufferMin, DATEADD(MINUTE, 128,
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 15, 30, 0, 0, 0)))
        AND DATEADD(MINUTE, @BufferMin, s.end_time) >
                DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 15, 30, 0, 0, 0)
    )
    INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
    VALUES (
        NEWID(),
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA211',
        @Room1,
        DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 15, 30, 0, 0, 0),
        DATEADD(MINUTE, 128, DATETIME2FROMPARTS(YEAR(@SoonDay), MONTH(@SoonDay), DAY(@SoonDay), 15, 30, 0, 0, 0)),
        90000, 'SCHEDULED', @ManagerId
    );

    -- Batman 2 → Phòng 3 lúc 15:30 ngày +8
    DECLARE @SoonDay2 DATE = DATEADD(DAY, 21, CAST(GETDATE() AS DATE));
    IF NOT EXISTS (
        SELECT 1 FROM Showtimes s
        WHERE s.room_id = @Room3 AND s.status <> 'CANCELLED'
        AND s.start_time < DATEADD(MINUTE, @BufferMin, DATEADD(MINUTE, 165,
                DATETIME2FROMPARTS(YEAR(@SoonDay2), MONTH(@SoonDay2), DAY(@SoonDay2), 15, 30, 0, 0, 0)))
        AND DATEADD(MINUTE, @BufferMin, s.end_time) >
                DATETIME2FROMPARTS(YEAR(@SoonDay2), MONTH(@SoonDay2), DAY(@SoonDay2), 15, 30, 0, 0, 0)
    )
    INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
    VALUES (
        NEWID(),
        'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA212',
        @Room3,
        DATETIME2FROMPARTS(YEAR(@SoonDay2), MONTH(@SoonDay2), DAY(@SoonDay2), 15, 30, 0, 0, 0),
        DATEADD(MINUTE, 165, DATETIME2FROMPARTS(YEAR(@SoonDay2), MONTH(@SoonDay2), DAY(@SoonDay2), 15, 30, 0, 0, 0)),
        110000, 'SCHEDULED', @ManagerId
    );

    COMMIT TRANSACTION;

    PRINT N'========== SEED LOAD-TEST HOÀN TẤT ==========';
    PRINT N'Suất vừa insert: ' + CAST(@Inserted AS NVARCHAR(20));
    PRINT N'Suất bị skip:    ' + CAST(@Skipped AS NVARCHAR(20));

    SELECT N'Phim seed-load' AS metric, COUNT(*) AS value
    FROM Movies WHERE slug LIKE N'seed-load-%'
    UNION ALL
    SELECT N'Suất seed-load (tất cả)', COUNT(*)
    FROM Showtimes s
    JOIN Movies m ON m.id = s.movie_id
    WHERE m.slug LIKE N'seed-load-%'
    UNION ALL
    SELECT N'Suất seed trong [-7,+7] ngày', COUNT(*)
    FROM Showtimes s
    JOIN Movies m ON m.id = s.movie_id
    WHERE m.slug LIKE N'seed-load-%'
    AND CAST(s.start_time AS DATE) BETWEEN DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
                                        AND DATEADD(DAY,  7, CAST(GETDATE() AS DATE))
    UNION ALL
    SELECT N'Suất FINISHED (quá khứ gần)', COUNT(*)
    FROM Showtimes s
    JOIN Movies m ON m.id = s.movie_id
    WHERE m.slug LIKE N'seed-load-%' AND s.status = 'FINISHED'
    UNION ALL
    SELECT N'Suất SCHEDULED / SHOWING trong 7 ngày tới', COUNT(*)
    FROM Showtimes
    WHERE status IN ('SCHEDULED', 'SHOWING')
      AND start_time >= CAST(GETDATE() AS DATE)
      AND start_time < DATEADD(DAY, 7, CAST(GETDATE() AS DATE));

    SELECT
        CAST(s.start_time AS DATE) AS show_date,
        COUNT(*) AS showtime_count,
        SUM(CASE WHEN s.status = 'FINISHED' THEN 1 ELSE 0 END) AS finished_cnt,
        SUM(CASE WHEN s.status = 'SHOWING' THEN 1 ELSE 0 END) AS showing_cnt,
        SUM(CASE WHEN s.status = 'SCHEDULED' THEN 1 ELSE 0 END) AS scheduled_cnt,
        SUM(CASE WHEN s.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_cnt
    FROM Showtimes s
    JOIN Movies m ON m.id = s.movie_id
    WHERE m.slug LIKE N'seed-load-%'
      AND CAST(s.start_time AS DATE) BETWEEN DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
                                        AND DATEADD(DAY,  7, CAST(GETDATE() AS DATE))
    GROUP BY CAST(s.start_time AS DATE)
    ORDER BY show_date;

    SELECT TOP 20
        m.title, cr.room_name, s.start_time, s.end_time, s.base_price, s.status
    FROM Showtimes s
    JOIN Movies m ON m.id = s.movie_id
    JOIN CinemaRooms cr ON cr.id = s.room_id
    WHERE m.slug LIKE N'seed-load-%'
    ORDER BY s.start_time DESC;

    PRINT N'Vao /manager/showtimes: chip Tat ca + chon ngay, hoac Lich phong de xem tung ngay.';
    GO
