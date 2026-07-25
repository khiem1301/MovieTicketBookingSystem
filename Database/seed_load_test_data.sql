-- ============================================================
-- MovieTicketDB — BULK LOAD TEST DATA (additive, idempotent)
-- ============================================================
-- Mục đích: thêm lượng lớn dữ liệu để test web / báo cáo / phân trang.
-- Điều kiện: đã chạy Database/create_database.sql (schema + seed sẵn).
--
-- An toàn:
--   - KHÔNG DROP / TRUNCATE / ghi đè seed gốc (Roles, admin, SEED-STATS-*, …)
--   - Mọi ID mới = NEWID(); mã unique prefix LOADTEST- / loadtest-
--   - FK luôn lookup từ dữ liệu ĐÃ CÓ
--   - Chạy lại cùng @BatchTag: bỏ qua bản ghi đã có (NOT EXISTS)
--
-- Cách dùng (SSMS): chỉnh CONFIG → Ctrl+A → F5
-- Xóa data load-test: bỏ comment section CLEANUP ở cuối.
-- ============================================================

USE MovieTicketDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ============================================================
-- CONFIG (đổi số lượng / tag tại đây — 1 chỗ duy nhất)
-- ============================================================
IF OBJECT_ID('tempdb..#LoadTestConfig') IS NOT NULL DROP TABLE #LoadTestConfig;
CREATE TABLE #LoadTestConfig (
    batch_tag          NVARCHAR(20)  NOT NULL,
    customer_count     INT           NOT NULL,
    extra_movie_count  INT           NOT NULL,
    showtime_days      INT           NOT NULL,
    showtimes_per_day  INT           NOT NULL,
    booking_count      INT           NOT NULL,
    review_count       INT           NOT NULL,
    seat_rows          INT           NOT NULL,
    seat_cols          INT           NOT NULL,
    promo_count        INT           NOT NULL,
    password_hash      NVARCHAR(255) NOT NULL
);

INSERT INTO #LoadTestConfig VALUES (
    N'LT20260725',  -- BatchTag: đổi nếu muốn tạo batch mới khi chạy lại
    80,             -- customers
    12,             -- extra movies (max 12 mẫu trong script)
    14,             -- showtime days ahead
    6,              -- showtimes per day
    200,            -- bookings
    120,            -- reviews
    8,              -- seat rows A..H
    12,             -- seat cols 1..12
    8,              -- promotions
    -- Password@123 (giống create_database.sql)
    N'$2a$10$cQtXPt5hVH2nDDhuXFDxQ.aKttyB7S7/6jR.xyULrEfcnUFA8UCM6'
);

-- ============================================================
-- LOOKUP + GUARD
-- ============================================================
DECLARE @BatchTag            NVARCHAR(20)  = (SELECT batch_tag FROM #LoadTestConfig);
DECLARE @CustomerCount       INT           = (SELECT customer_count FROM #LoadTestConfig);
DECLARE @ExtraMovieCount     INT           = (SELECT extra_movie_count FROM #LoadTestConfig);
DECLARE @ShowtimeDaysAhead   INT           = (SELECT showtime_days FROM #LoadTestConfig);
DECLARE @ShowtimesPerDay     INT           = (SELECT showtimes_per_day FROM #LoadTestConfig);
DECLARE @BookingCount        INT           = (SELECT booking_count FROM #LoadTestConfig);
DECLARE @ReviewCount         INT           = (SELECT review_count FROM #LoadTestConfig);
DECLARE @SeatsPerRoomRows    INT           = (SELECT seat_rows FROM #LoadTestConfig);
DECLARE @SeatsPerRoomCols    INT           = (SELECT seat_cols FROM #LoadTestConfig);
DECLARE @PromoCount          INT           = (SELECT promo_count FROM #LoadTestConfig);
DECLARE @PasswordHash        NVARCHAR(255) = (SELECT password_hash FROM #LoadTestConfig);

DECLARE @RoleCustomer UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM Roles WHERE role_name = N'CUSTOMER');
DECLARE @ManagerId    UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM Users WHERE email = N'manager@movieticket.vn');
DECLARE @StaffId      UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM Users WHERE email = N'staff@movieticket.vn');
DECLARE @SeatRegular  UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM SeatTypes WHERE type_name = N'REGULAR');
DECLARE @SeatVip      UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM SeatTypes WHERE type_name = N'VIP');
DECLARE @SeatCouple   UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM SeatTypes WHERE type_name = N'COUPLE');
DECLARE @VatRate      DECIMAL(5,2) = COALESCE(
    (SELECT TOP 1 vat_rate FROM VatRules WHERE status = N'ACTIVE' ORDER BY start_date DESC),
    10.00
);

IF @RoleCustomer IS NULL OR @SeatRegular IS NULL OR @ManagerId IS NULL
BEGIN
    RAISERROR(N'[LOADTEST] Thiếu seed gốc (Roles/SeatTypes/manager). Chạy create_database.sql trước.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM CinemaRooms WHERE status = N'ACTIVE')
BEGIN
    RAISERROR(N'[LOADTEST] Không có CinemaRooms ACTIVE.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM Movies)
BEGIN
    RAISERROR(N'[LOADTEST] Không có Movies.', 16, 1);
    RETURN;
END;

PRINT N'[LOADTEST] Bắt đầu batch: ' + @BatchTag;

BEGIN TRY
BEGIN TRANSACTION;

-- ============================================================
-- 1) CUSTOMERS (Users) — unique email / username / phone
-- ============================================================
DECLARE @i INT = 1;
DECLARE @email NVARCHAR(255);
DECLARE @uname NVARCHAR(100);
DECLARE @phone NVARCHAR(20);
DECLARE @fullName NVARCHAR(255);
DECLARE @dob DATE;
DECLARE @points INT;
DECLARE @insertedUsers INT = 0;

WHILE @i <= @CustomerCount
BEGIN
    SET @email = N'loadtest.' + LOWER(@BatchTag) + N'.'
               + RIGHT(N'0000' + CAST(@i AS NVARCHAR(10)), 4) + N'@loadtest.local';
    SET @uname = N'loadtest_' + LOWER(@BatchTag) + N'_'
               + RIGHT(N'0000' + CAST(@i AS NVARCHAR(10)), 4);
    -- 091 + 3 số từ checksum batch + 4 số index → tránh trùng 090x seed
    SET @phone = N'091'
               + RIGHT(N'000' + CAST(ABS(CHECKSUM(@BatchTag)) % 1000 AS NVARCHAR(10)), 3)
               + RIGHT(N'0000' + CAST(@i AS NVARCHAR(10)), 4);
    SET @fullName = N'LoadTest User ' + CAST(@i AS NVARCHAR(10));
    SET @dob = DATEADD(YEAR, -(18 + (@i % 40)), CAST(GETDATE() AS DATE));
    SET @points = (@i * 17) % 5000;

    IF NOT EXISTS (
        SELECT 1 FROM Users
        WHERE email = @email OR username = @uname OR phone_number = @phone
    )
    BEGIN
        INSERT INTO Users (
            id, role_id, email, username, phone_number,
            password_hash, full_name, date_of_birth, avatar_url,
            status, loyalty_points, last_login_at
        ) VALUES (
            NEWID(), @RoleCustomer, @email, @uname, @phone,
            @PasswordHash, @fullName, @dob, NULL,
            N'ACTIVE', @points, DATEADD(DAY, -(@i % 30), GETDATE())
        );
        SET @insertedUsers += 1;
    END

    SET @i += 1;
END;

PRINT N'[LOADTEST] Users inserted: ' + CAST(@insertedUsers AS NVARCHAR(20));

-- ============================================================
-- 2) SEATS — bổ sung ghế thiếu theo (room_id, seat_code); không đụng ghế sẵn
-- ============================================================
DECLARE @roomId UNIQUEIDENTIFIER;
DECLARE @r INT, @c INT;
DECLARE @rowLetter NVARCHAR(10);
DECLARE @seatCode NVARCHAR(20);
DECLARE @seatType UNIQUEIDENTIFIER;
DECLARE @insertedSeats INT = 0;

DECLARE room_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id FROM CinemaRooms WHERE status = N'ACTIVE';

OPEN room_cursor;
FETCH NEXT FROM room_cursor INTO @roomId;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @r = 0;
    WHILE @r < @SeatsPerRoomRows
    BEGIN
        SET @rowLetter = NCHAR(ASCII(N'A') + @r);
        SET @c = 1;
        WHILE @c <= @SeatsPerRoomCols
        BEGIN
            SET @seatCode = @rowLetter + CAST(@c AS NVARCHAR(10));
            SET @seatType = CASE
                WHEN @r IN (4, 5) THEN COALESCE(@SeatVip, @SeatRegular)
                WHEN @r = 7 AND (@c % 2 = 1) AND @SeatCouple IS NOT NULL THEN @SeatCouple
                ELSE @SeatRegular
            END;

            IF NOT EXISTS (
                SELECT 1 FROM Seats WHERE room_id = @roomId AND seat_code = @seatCode
            )
            BEGIN
                INSERT INTO Seats (id, room_id, seat_type_id, seat_row, seat_column, seat_code, status)
                VALUES (NEWID(), @roomId, @seatType, @rowLetter, @c, @seatCode, N'ACTIVE');
                SET @insertedSeats += 1;
            END

            SET @c += 1;
        END
        SET @r += 1;
    END

    -- Chỉ tăng capacity nếu thiếu ghế so với thực tế (không giảm)
    UPDATE cr
    SET capacity = s.cnt
    FROM CinemaRooms cr
    CROSS APPLY (
        SELECT COUNT(*) AS cnt FROM Seats WHERE room_id = cr.id AND status = N'ACTIVE'
    ) s
    WHERE cr.id = @roomId AND cr.capacity < s.cnt;

    FETCH NEXT FROM room_cursor INTO @roomId;
END

CLOSE room_cursor;
DEALLOCATE room_cursor;

PRINT N'[LOADTEST] Seats inserted: ' + CAST(@insertedSeats AS NVARCHAR(20));

-- ============================================================
-- 3) MOVIES + MovieGenres — slug loadtest-{batch}-NN
-- ============================================================
DECLARE @titles TABLE (
    n INT PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    duration INT NOT NULL,
    age NVARCHAR(10) NOT NULL,
    st NVARCHAR(20) NOT NULL
);

INSERT INTO @titles (n, title, duration, age, st) VALUES
 (1,  N'LoadTest: Neon Horizon',      128, N'T13', N'NOW_SHOWING'),
 (2,  N'LoadTest: Echoes of Rain',    110, N'T16', N'NOW_SHOWING'),
 (3,  N'LoadTest: Paper Crane',        98, N'P',   N'NOW_SHOWING'),
 (4,  N'LoadTest: Midnight Protocol', 142, N'T18', N'NOW_SHOWING'),
 (5,  N'LoadTest: Sapphire Drift',    115, N'T13', N'EARLY_SHOWING'),
 (6,  N'LoadTest: Quiet Harbor',      105, N'K',   N'NOW_SHOWING'),
 (7,  N'LoadTest: Iron Lantern',      133, N'T13', N'NOW_SHOWING'),
 (8,  N'LoadTest: Velvet Circuit',    121, N'T16', N'COMING_SOON'),
 (9,  N'LoadTest: Amber Station',      99, N'P',   N'COMING_SOON'),
 (10, N'LoadTest: Glass Monsoon',     117, N'T13', N'COMING_SOON'),
 (11, N'LoadTest: Cobalt Memoir',     126, N'T18', N'ENDED'),
 (12, N'LoadTest: Coral Transit',     108, N'T13', N'NOW_SHOWING');

DECLARE @n INT = 1;
DECLARE @slug NVARCHAR(255);
DECLARE @movieId UNIQUEIDENTIFIER;
DECLARE @genreId UNIQUEIDENTIFIER;
DECLARE @genreCnt INT = (SELECT COUNT(*) FROM Genres WHERE is_active = 1);
DECLARE @title NVARCHAR(255), @dur INT, @age NVARCHAR(10), @st NVARCHAR(20);
DECLARE @insertedMovies INT = 0;
DECLARE @maxMovies INT = CASE WHEN @ExtraMovieCount > 12 THEN 12 ELSE @ExtraMovieCount END;

WHILE @n <= @maxMovies
BEGIN
    SELECT @title = title, @dur = duration, @age = age, @st = st
    FROM @titles WHERE n = @n;

    SET @slug = N'loadtest-' + LOWER(@BatchTag) + N'-' + RIGHT(N'00' + CAST(@n AS NVARCHAR(10)), 2);

    IF NOT EXISTS (SELECT 1 FROM Movies WHERE slug = @slug)
    BEGIN
        SET @movieId = NEWID();
        INSERT INTO Movies (
            id, title, slug, description, duration_minutes, release_date,
            trailer_url, poster_url, backdrop_url, director, cast_members,
            language, subtitle, age_rating, status, average_rating
        ) VALUES (
            @movieId, @title, @slug,
            N'[LOADTEST] Phim giả lập. Batch ' + @BatchTag + N'.',
            @dur, DATEADD(DAY, -(@n * 3), CAST(GETDATE() AS DATE)),
            N'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            N'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
            N'https://image.tmdb.org/t/p/w1280/wr7l2t38C5sNYQwJMbVBiETVJzZ.jpg',
            N'LoadTest Director ' + CAST(@n AS NVARCHAR(10)),
            N'Actor A, Actor B, Actor C',
            N'Tiếng Anh', N'Phụ đề Việt', @age, @st,
            CASE WHEN @st = N'COMING_SOON' THEN 0.00
                 ELSE CAST(3.0 + (@n % 20) / 10.0 AS DECIMAL(3,2)) END
        );
        SET @insertedMovies += 1;

        IF @genreCnt > 0
        BEGIN
            SET @genreId = (
                SELECT id FROM (
                    SELECT id, ROW_NUMBER() OVER (ORDER BY genre_name) AS rn
                    FROM Genres WHERE is_active = 1
                ) g WHERE g.rn = ((@n - 1) % @genreCnt) + 1
            );
            IF @genreId IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM MovieGenres WHERE movie_id = @movieId AND genre_id = @genreId)
                INSERT INTO MovieGenres (movie_id, genre_id) VALUES (@movieId, @genreId);

            SET @genreId = (
                SELECT id FROM (
                    SELECT id, ROW_NUMBER() OVER (ORDER BY genre_name DESC) AS rn
                    FROM Genres WHERE is_active = 1
                ) g WHERE g.rn = ((@n) % @genreCnt) + 1
            );
            IF @genreId IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM MovieGenres WHERE movie_id = @movieId AND genre_id = @genreId)
                INSERT INTO MovieGenres (movie_id, genre_id) VALUES (@movieId, @genreId);
        END
    END

    SET @n += 1;
END;

PRINT N'[LOADTEST] Movies inserted: ' + CAST(@insertedMovies AS NVARCHAR(20));

-- ============================================================
-- 4) SHOWTIMES — N ngày tới × M suất/ngày (tránh trùng room+start_time)
-- ============================================================
DECLARE @rooms TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, room_id UNIQUEIDENTIFIER NOT NULL);
INSERT INTO @rooms (room_id)
SELECT id FROM CinemaRooms WHERE status = N'ACTIVE' ORDER BY room_name;

DECLARE @movies TABLE (
    mn INT IDENTITY(1,1) PRIMARY KEY,
    movie_id UNIQUEIDENTIFIER NOT NULL,
    duration INT NOT NULL
);
INSERT INTO @movies (movie_id, duration)
SELECT id, duration_minutes
FROM Movies
WHERE status IN (N'NOW_SHOWING', N'EARLY_SHOWING')
ORDER BY title;

DECLARE @roomCnt INT = (SELECT COUNT(*) FROM @rooms);
DECLARE @movieCnt INT = (SELECT COUNT(*) FROM @movies);
DECLARE @day INT = 0;
DECLARE @slot INT;
DECLARE @start DATETIME2;
DECLARE @end DATETIME2;
DECLARE @basePrice DECIMAL(12,2);
DECLARE @duration INT;
DECLARE @hour INT;
DECLARE @insertedSt INT = 0;

IF @roomCnt > 0 AND @movieCnt > 0
BEGIN
    WHILE @day < @ShowtimeDaysAhead
    BEGIN
        SET @slot = 0;
        WHILE @slot < @ShowtimesPerDay
        BEGIN
            SET @hour = 10 + ((@slot * 2) % 12);
            SET @start = DATEADD(
                MINUTE,
                (ABS(CHECKSUM(@BatchTag)) % 7),
                DATEADD(HOUR, @hour,
                    DATEADD(DAY, @day + 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))
            );

            SELECT @roomId = room_id FROM @rooms WHERE rn = (@slot % @roomCnt) + 1;
            SELECT @movieId = movie_id, @duration = duration
            FROM @movies WHERE mn = ((@day + @slot) % @movieCnt) + 1;

            SET @end = DATEADD(MINUTE, @duration + 15, @start);
            SET @basePrice = 80000 + ((@slot % 5) * 10000);

            IF NOT EXISTS (
                SELECT 1 FROM Showtimes WHERE room_id = @roomId AND start_time = @start
            )
            BEGIN
                INSERT INTO Showtimes (
                    id, movie_id, room_id, start_time, end_time,
                    base_price, status, created_by
                ) VALUES (
                    NEWID(), @movieId, @roomId, @start, @end,
                    @basePrice, N'SCHEDULED', @ManagerId
                );
                SET @insertedSt += 1;
            END

            SET @slot += 1;
        END
        SET @day += 1;
    END
END;

PRINT N'[LOADTEST] Showtimes inserted: ' + CAST(@insertedSt AS NVARCHAR(20));

-- ============================================================
-- 5) PROMOTIONS — code LOADTEST-{BATCH}-NN
-- ============================================================
DECLARE @p INT = 1;
DECLARE @code NVARCHAR(50);
DECLARE @insertedPromo INT = 0;

WHILE @p <= @PromoCount
BEGIN
    SET @code = N'LOADTEST-' + UPPER(@BatchTag) + N'-' + RIGHT(N'00' + CAST(@p AS NVARCHAR(10)), 2);

    IF NOT EXISTS (SELECT 1 FROM Promotions WHERE code = @code)
    BEGIN
        INSERT INTO Promotions (
            id, code, title, description, discount_type, discount_value,
            max_discount_amount, min_order_amount, start_date, end_date,
            usage_limit, used_count, status, image_url
        ) VALUES (
            NEWID(), @code,
            N'[LOADTEST] Voucher ' + CAST(@p AS NVARCHAR(10)),
            N'Voucher giả lập batch ' + @BatchTag,
            CASE WHEN @p % 2 = 0 THEN N'PERCENTAGE' ELSE N'FIXED_AMOUNT' END,
            CASE WHEN @p % 2 = 0 THEN 5 + (@p % 10) ELSE 10000.0 * (@p % 5 + 1) END,
            CASE WHEN @p % 2 = 0 THEN 50000 ELSE NULL END,
            100000,
            DATEADD(DAY, -7, GETDATE()),
            DATEADD(DAY, 60, GETDATE()),
            200, 0, N'ACTIVE', NULL
        );
        SET @insertedPromo += 1;
    END
    SET @p += 1;
END;

PRINT N'[LOADTEST] Promotions inserted: ' + CAST(@insertedPromo AS NVARCHAR(20));

-- ============================================================
-- 6) BOOKINGS + seats + payments + tickets + loyalty
-- ============================================================
DECLARE @customers TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, user_id UNIQUEIDENTIFIER NOT NULL);
INSERT INTO @customers (user_id)
SELECT u.id
FROM Users u
JOIN Roles r ON r.id = u.role_id
WHERE r.role_name = N'CUSTOMER' AND u.status = N'ACTIVE'
ORDER BY u.created_at;

DECLARE @showtimes TABLE (
    rn INT IDENTITY(1,1) PRIMARY KEY,
    showtime_id UNIQUEIDENTIFIER NOT NULL,
    room_id UNIQUEIDENTIFIER NOT NULL,
    base_price DECIMAL(12,2) NOT NULL
);
INSERT INTO @showtimes (showtime_id, room_id, base_price)
SELECT TOP 500 s.id, s.room_id, s.base_price
FROM Showtimes s
WHERE s.status IN (N'SCHEDULED', N'OPEN', N'FINISHED')
ORDER BY s.start_time DESC;

DECLARE @custCnt INT = (SELECT COUNT(*) FROM @customers);
DECLARE @stCnt INT = (SELECT COUNT(*) FROM @showtimes);

DECLARE @b INT = 1;
DECLARE @bookingCode NVARCHAR(50);
DECLARE @bookingId UNIQUEIDENTIFIER;
DECLARE @userId UNIQUEIDENTIFIER;
DECLARE @showtimeId UNIQUEIDENTIFIER;
DECLARE @source NVARCHAR(10);
DECLARE @status NVARCHAR(20);
DECLARE @payStatus NVARCHAR(10);
DECLARE @total DECIMAL(12,2);
DECLARE @final DECIMAL(12,2);
DECLARE @discount DECIMAL(12,2);
DECLARE @seatsToBook INT;
DECLARE @bookedAt DATETIME2;
DECLARE @insertedBk INT = 0;
DECLARE @payMethod NVARCHAR(20);
DECLARE @pickedSeats TABLE (
    bs_id UNIQUEIDENTIFIER NOT NULL,
    seat_id UNIQUEIDENTIFIER NOT NULL,
    ticket_price DECIMAL(12,2) NOT NULL
);

IF @custCnt > 0 AND @stCnt > 0
BEGIN
    WHILE @b <= @BookingCount
    BEGIN
        SET @bookingCode = N'LOADTEST-' + UPPER(@BatchTag) + N'-'
                         + RIGHT(N'0000' + CAST(@b AS NVARCHAR(10)), 4);

        IF EXISTS (SELECT 1 FROM Bookings WHERE booking_code = @bookingCode)
        BEGIN
            SET @b += 1;
            CONTINUE;
        END

        SELECT @userId = user_id FROM @customers WHERE rn = ((@b - 1) % @custCnt) + 1;
        SELECT @showtimeId = showtime_id, @roomId = room_id, @basePrice = base_price
        FROM @showtimes WHERE rn = ((@b - 1) % @stCnt) + 1;

        SET @source = CASE WHEN @b % 3 = 0 THEN N'OFFLINE' ELSE N'ONLINE' END;
        SET @status = CASE
            WHEN @b % 20 = 0 THEN N'EXPIRED'
            WHEN @b % 10 = 0 THEN N'CANCELLED'
            WHEN @b % 7  = 0 THEN N'PENDING'
            ELSE N'CONFIRMED'
        END;
        SET @payStatus = CASE
            WHEN @status = N'CONFIRMED' THEN N'PAID'
            WHEN @status = N'PENDING' THEN N'UNPAID'
            ELSE N'FAILED'
        END;

        SET @seatsToBook = 1 + (@b % 3);
        SET @bookedAt = DATEADD(MINUTE, -(@b * 11), GETDATE());
        SET @bookingId = NEWID();
        SET @discount = CASE WHEN @b % 11 = 0 THEN 20000 ELSE 0 END;

        DELETE FROM @pickedSeats;

        INSERT INTO @pickedSeats (bs_id, seat_id, ticket_price)
        SELECT TOP (@seatsToBook)
               NEWID(),
               s.id,
               ROUND(@basePrice * st.price_multiplier, 0)
        FROM Seats s
        JOIN SeatTypes st ON st.id = s.seat_type_id
        WHERE s.room_id = @roomId
          AND s.status = N'ACTIVE'
          AND NOT EXISTS (
              SELECT 1
              FROM BookingSeats bs
              JOIN Bookings bk ON bk.id = bs.booking_id
              WHERE bs.seat_id = s.id
                AND bk.showtime_id = @showtimeId
                AND bk.booking_status IN (N'PENDING', N'CONFIRMED')
          )
        ORDER BY s.seat_row, s.seat_column;

        IF NOT EXISTS (SELECT 1 FROM @pickedSeats)
        BEGIN
            SET @b += 1;
            CONTINUE;
        END

        SELECT @total = SUM(ticket_price) FROM @pickedSeats;
        SET @final = CASE WHEN @total > @discount THEN @total - @discount ELSE @total END;
        SET @final = ROUND(@final * (1 + @VatRate / 100.0), 0);

        INSERT INTO Bookings (
            id, booking_code, user_id, showtime_id, booking_source,
            created_by_staff_id, customer_name, customer_phone,
            vat_rate_snapshot, total_amount, discount_amount, final_amount,
            booking_status, payment_status, booked_at, expired_at
        ) VALUES (
            @bookingId,
            @bookingCode,
            CASE WHEN @source = N'ONLINE' THEN @userId ELSE NULL END,
            @showtimeId,
            @source,
            CASE WHEN @source = N'OFFLINE' THEN @StaffId ELSE NULL END,
            CASE WHEN @source = N'OFFLINE' THEN N'Walk-in LT ' + CAST(@b AS NVARCHAR(10)) ELSE NULL END,
            CASE WHEN @source = N'OFFLINE'
                 THEN N'092' + RIGHT(N'0000000' + CAST(@b AS NVARCHAR(10)), 7)
                 ELSE NULL END,
            @VatRate, @total, @discount, @final,
            @status, @payStatus, @bookedAt,
            CASE WHEN @status = N'PENDING' THEN DATEADD(MINUTE, 15, @bookedAt) ELSE NULL END
        );

        INSERT INTO BookingSeats (id, booking_id, seat_id, ticket_price)
        SELECT bs_id, @bookingId, seat_id, ticket_price
        FROM @pickedSeats;

        IF @status = N'CONFIRMED' AND @payStatus = N'PAID'
        BEGIN
            INSERT INTO Tickets (id, booking_seat_id, ticket_code, qr_code, is_printed, issued_at)
            SELECT
                NEWID(),
                ps.bs_id,
                N'TKT-LT-' + UPPER(@BatchTag) + N'-'
                    + REPLACE(CAST(ps.bs_id AS NVARCHAR(36)), N'-', N''),
                N'QR-LT-' + CAST(ps.bs_id AS NVARCHAR(36)),
                CASE WHEN @source = N'OFFLINE' THEN 1 ELSE 0 END,
                @bookedAt
            FROM @pickedSeats ps;
        END

        IF @payStatus = N'PAID'
        BEGIN
            SET @payMethod = CASE @b % 4
                WHEN 0 THEN N'VNPAY'
                WHEN 1 THEN N'MOMO'
                WHEN 2 THEN N'VIETQR'
                ELSE N'CASH'
            END;

            INSERT INTO Payments (
                id, booking_id, payment_method, payment_source,
                transaction_code, amount, cash_received, change_amount,
                payment_status, paid_at, created_at
            ) VALUES (
                NEWID(), @bookingId, @payMethod, @source,
                N'TXN-LT-' + UPPER(@BatchTag) + N'-' + RIGHT(N'0000' + CAST(@b AS NVARCHAR(10)), 4),
                @final,
                CASE WHEN @payMethod = N'CASH' THEN @final + 50000 ELSE NULL END,
                CASE WHEN @payMethod = N'CASH' THEN 50000 ELSE NULL END,
                N'SUCCESS', DATEADD(MINUTE, 2, @bookedAt), @bookedAt
            );

            IF @source = N'ONLINE' AND @userId IS NOT NULL AND @final >= 1000
            BEGIN
                INSERT INTO LoyaltyPointsLog (
                    id, user_id, booking_id, points_delta, transaction_type, note, created_at
                ) VALUES (
                    NEWID(), @userId, @bookingId,
                    CAST(@final / 1000 AS INT),
                    N'EARN',
                    N'[LOADTEST] Earn từ ' + @bookingCode,
                    DATEADD(MINUTE, 3, @bookedAt)
                );
            END
        END
        ELSE IF @status = N'PENDING'
        BEGIN
            INSERT INTO Payments (
                id, booking_id, payment_method, payment_source,
                transaction_code, amount, payment_status, paid_at, created_at
            ) VALUES (
                NEWID(), @bookingId, N'VNPAY', N'ONLINE',
                NULL, @final, N'PENDING', NULL, @bookedAt
            );
        END

        IF @discount > 0
           AND EXISTS (SELECT 1 FROM Promotions WHERE code LIKE N'LOADTEST-%' AND status = N'ACTIVE')
        BEGIN
            INSERT INTO BookingPromotions (booking_id, promotion_id, discount_applied)
            SELECT TOP 1 @bookingId, p.id, @discount
            FROM Promotions p
            WHERE p.code LIKE N'LOADTEST-%' AND p.status = N'ACTIVE'
              AND NOT EXISTS (
                  SELECT 1 FROM BookingPromotions bp
                  WHERE bp.booking_id = @bookingId AND bp.promotion_id = p.id
              );
        END

        SET @insertedBk += 1;
        SET @b += 1;
    END
END;

PRINT N'[LOADTEST] Bookings inserted: ' + CAST(@insertedBk AS NVARCHAR(20));

-- ============================================================
-- 7) MOVIE REVIEWS — tôn trọng UK (movie_id, user_id)
-- ============================================================
DECLARE @revUsers TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, user_id UNIQUEIDENTIFIER NOT NULL);
INSERT INTO @revUsers (user_id)
SELECT id FROM Users
WHERE email LIKE N'loadtest.%@loadtest.local'
   OR email LIKE N'customer.%@email.com';

DECLARE @revMovies TABLE (rn INT IDENTITY(1,1) PRIMARY KEY, movie_id UNIQUEIDENTIFIER NOT NULL);
INSERT INTO @revMovies (movie_id)
SELECT id FROM Movies WHERE status IN (N'NOW_SHOWING', N'EARLY_SHOWING', N'ENDED');

DECLARE @uCnt INT = (SELECT COUNT(*) FROM @revUsers);
DECLARE @mCnt INT = (SELECT COUNT(*) FROM @revMovies);
DECLARE @ri INT = 1;
DECLARE @uid UNIQUEIDENTIFIER;
DECLARE @mid UNIQUEIDENTIFIER;
DECLARE @rating INT;
DECLARE @insertedRv INT = 0;

IF @uCnt > 0 AND @mCnt > 0
BEGIN
    WHILE @ri <= @ReviewCount
    BEGIN
        SELECT @uid = user_id FROM @revUsers WHERE rn = ((@ri - 1) % @uCnt) + 1;
        SELECT @mid = movie_id FROM @revMovies WHERE rn = ((@ri - 1) % @mCnt) + 1;
        SET @rating = 1 + (@ri % 5);

        IF NOT EXISTS (SELECT 1 FROM MovieReviews WHERE movie_id = @mid AND user_id = @uid)
        BEGIN
            INSERT INTO MovieReviews (id, movie_id, user_id, rating, review_content, created_at)
            VALUES (
                NEWID(), @mid, @uid, @rating,
                N'[LOADTEST] Đánh giá tự động batch ' + @BatchTag
                    + N' #' + CAST(@ri AS NVARCHAR(10)),
                DATEADD(HOUR, -@ri, GETDATE())
            );
            SET @insertedRv += 1;
        END

        SET @ri += 1;
    END
END;

UPDATE m
SET average_rating = agg.avg_r
FROM Movies m
INNER JOIN (
    SELECT movie_id, CAST(AVG(CAST(rating AS DECIMAL(5,2))) AS DECIMAL(3,2)) AS avg_r
    FROM MovieReviews
    GROUP BY movie_id
) agg ON agg.movie_id = m.id;

PRINT N'[LOADTEST] Reviews inserted: ' + CAST(@insertedRv AS NVARCHAR(20));

COMMIT TRANSACTION;

PRINT N'';
PRINT N'=== LOADTEST SUMMARY ===';

SELECT N'Users loadtest' AS metric, COUNT(*) AS cnt
FROM Users WHERE email LIKE N'loadtest.%@loadtest.local'
UNION ALL SELECT N'Movies loadtest', COUNT(*) FROM Movies WHERE slug LIKE N'loadtest-%'
UNION ALL SELECT N'Seats (all)', COUNT(*) FROM Seats
UNION ALL SELECT N'Showtimes (future)', COUNT(*)
FROM Showtimes WHERE start_time >= CAST(CAST(GETDATE() AS DATE) AS DATETIME2)
UNION ALL SELECT N'Bookings LOADTEST-*', COUNT(*) FROM Bookings WHERE booking_code LIKE N'LOADTEST-%'
UNION ALL SELECT N'Tickets TKT-LT-*', COUNT(*) FROM Tickets WHERE ticket_code LIKE N'TKT-LT-%'
UNION ALL SELECT N'Payments TXN-LT-*', COUNT(*) FROM Payments WHERE transaction_code LIKE N'TXN-LT-%'
UNION ALL SELECT N'Promotions LOADTEST-*', COUNT(*) FROM Promotions WHERE code LIKE N'LOADTEST-%'
UNION ALL SELECT N'Reviews [LOADTEST]', COUNT(*) FROM MovieReviews WHERE review_content LIKE N'[[]LOADTEST]%';

PRINT N'';
PRINT N'[LOADTEST] Xong. Mật khẩu loadtest: Password@123';
PRINT N'[LOADTEST] Ví dụ: loadtest.' + LOWER(@BatchTag) + N'.0001@loadtest.local';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'[LOADTEST] Lỗi — đã ROLLBACK. Chi tiết: %s', 16, 1, @Err);
END CATCH;
GO

-- ============================================================
-- CLEANUP (tuỳ chọn) — xóa data LOADTEST, giữ nguyên seed gốc
-- Bỏ /* */ rồi chạy riêng khối này khi cần.
-- ============================================================
/*
USE MovieTicketDB;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DELETE t
FROM Tickets t
JOIN BookingSeats bs ON bs.id = t.booking_seat_id
JOIN Bookings b ON b.id = bs.booking_id
WHERE b.booking_code LIKE N'LOADTEST-%';

DELETE bp FROM BookingPromotions bp
JOIN Bookings b ON b.id = bp.booking_id
WHERE b.booking_code LIKE N'LOADTEST-%';

DELETE p FROM Payments p
JOIN Bookings b ON b.id = p.booking_id
WHERE b.booking_code LIKE N'LOADTEST-%';

DELETE l FROM LoyaltyPointsLog l
JOIN Bookings b ON b.id = l.booking_id
WHERE b.booking_code LIKE N'LOADTEST-%';

DELETE bs FROM BookingSeats bs
JOIN Bookings b ON b.id = bs.booking_id
WHERE b.booking_code LIKE N'LOADTEST-%';

DELETE FROM Bookings WHERE booking_code LIKE N'LOADTEST-%';
DELETE FROM Promotions WHERE code LIKE N'LOADTEST-%';
DELETE FROM MovieReviews WHERE review_content LIKE N'[[]LOADTEST]%';

DELETE s FROM Showtimes s
JOIN Movies m ON m.id = s.movie_id
WHERE m.slug LIKE N'loadtest-%';

DELETE mg FROM MovieGenres mg
JOIN Movies m ON m.id = mg.movie_id
WHERE m.slug LIKE N'loadtest-%';

DELETE FROM Movies WHERE slug LIKE N'loadtest-%';
DELETE FROM Users WHERE email LIKE N'loadtest.%@loadtest.local';

-- Ghế bổ sung: giữ lại (seed showtimes vẫn dùng được). Không xóa Seats ở đây.

COMMIT TRANSACTION;
PRINT N'[LOADTEST] Cleanup xong.';
GO
*/
