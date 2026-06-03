-- ============================================================
-- Movie Ticket Booking System
-- SQL Server Script
-- 26 Tables | Version Final v3
-- ============================================================
-- Luu y:
--   - UUID     -> UNIQUEIDENTIFIER + DEFAULT NEWID()
--   - ENUM     -> VARCHAR + CHECK constraint
--   - BOOLEAN  -> BIT
--   - TEXT     -> NVARCHAR(MAX)
--   - TIMESTAMP-> DATETIME2
--   - NOW()    -> GETDATE()
-- ============================================================

USE master;
GO

-- Tao database moi (doi ten neu can)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'MovieTicketDB')
BEGIN
    CREATE DATABASE MovieTicketDB
    COLLATE Vietnamese_CI_AS;
END
GO

USE MovieTicketDB;
GO

-- ============================================================
-- XOA BANG THEO THU TU NGUOC (tranh loi FK khi chay lai)
-- ============================================================
IF OBJECT_ID('chatbot_messages',       'U') IS NOT NULL DROP TABLE chatbot_messages;
IF OBJECT_ID('chatbot_conversations',  'U') IS NOT NULL DROP TABLE chatbot_conversations;
IF OBJECT_ID('showtime_incidents',     'U') IS NOT NULL DROP TABLE showtime_incidents;
IF OBJECT_ID('loyalty_points_log',     'U') IS NOT NULL DROP TABLE loyalty_points_log;
IF OBJECT_ID('tickets',                'U') IS NOT NULL DROP TABLE tickets;
IF OBJECT_ID('booking_promotions',     'U') IS NOT NULL DROP TABLE booking_promotions;
IF OBJECT_ID('promotions',             'U') IS NOT NULL DROP TABLE promotions;
IF OBJECT_ID('payments',               'U') IS NOT NULL DROP TABLE payments;
IF OBJECT_ID('booking_seats',          'U') IS NOT NULL DROP TABLE booking_seats;
IF OBJECT_ID('bookings',               'U') IS NOT NULL DROP TABLE bookings;
IF OBJECT_ID('seat_holds',             'U') IS NOT NULL DROP TABLE seat_holds;
IF OBJECT_ID('pricing_rules',          'U') IS NOT NULL DROP TABLE pricing_rules;
IF OBJECT_ID('showtimes',              'U') IS NOT NULL DROP TABLE showtimes;
IF OBJECT_ID('movie_reviews',          'U') IS NOT NULL DROP TABLE movie_reviews;
IF OBJECT_ID('movie_genres',           'U') IS NOT NULL DROP TABLE movie_genres;
IF OBJECT_ID('genres',                 'U') IS NOT NULL DROP TABLE genres;
IF OBJECT_ID('movies',                 'U') IS NOT NULL DROP TABLE movies;
IF OBJECT_ID('seats',                  'U') IS NOT NULL DROP TABLE seats;
IF OBJECT_ID('seat_types',             'U') IS NOT NULL DROP TABLE seat_types;
IF OBJECT_ID('cinema_rooms',           'U') IS NOT NULL DROP TABLE cinema_rooms;
IF OBJECT_ID('cinema_info',            'U') IS NOT NULL DROP TABLE cinema_info;
IF OBJECT_ID('vat_rules',              'U') IS NOT NULL DROP TABLE vat_rules;
IF OBJECT_ID('system_config',          'U') IS NOT NULL DROP TABLE system_config;
IF OBJECT_ID('password_reset_tokens',  'U') IS NOT NULL DROP TABLE password_reset_tokens;
IF OBJECT_ID('users',                  'U') IS NOT NULL DROP TABLE users;
IF OBJECT_ID('roles',                  'U') IS NOT NULL DROP TABLE roles;
GO

-- ============================================================
-- NHOM AUTH
-- ============================================================

-- ------------------------------------------------------------
-- 1. roles
-- ------------------------------------------------------------
CREATE TABLE roles (
    id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    role_name   VARCHAR(50)      NOT NULL,
    description VARCHAR(255)     NULL,
    created_at  DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_roles      PRIMARY KEY (id),
    CONSTRAINT UK_roles_name UNIQUE      (role_name),
    CONSTRAINT CK_roles_name CHECK (role_name IN ('CUSTOMER','STAFF','MANAGER','ADMIN'))
);
GO

-- ------------------------------------------------------------
-- 2. users
-- ------------------------------------------------------------
CREATE TABLE users (
    id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    role_id        UNIQUEIDENTIFIER NOT NULL,
    email          VARCHAR(255)     NULL,
    username       VARCHAR(100)     NULL,
    phone_number   VARCHAR(20)      NULL,
    password_hash  VARCHAR(255)     NOT NULL,
    full_name      NVARCHAR(255)    NOT NULL,
    avatar_url     NVARCHAR(MAX)    NULL,
    status         VARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
    loyalty_points INT              NOT NULL DEFAULT 0,
    last_login_at  DATETIME2        NULL,
    created_at     DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_users         PRIMARY KEY (id),
    CONSTRAINT FK_users_role    FOREIGN KEY (role_id)      REFERENCES roles(id),
    CONSTRAINT UK_users_email   UNIQUE (email),
    CONSTRAINT UK_users_uname   UNIQUE (username),
    CONSTRAINT UK_users_phone   UNIQUE (phone_number),
    CONSTRAINT CK_users_status  CHECK  (status IN ('ACTIVE','INACTIVE','BANNED')),
    CONSTRAINT CK_users_loyalty CHECK  (loyalty_points >= 0),
    -- it nhat phai co 1 trong 3 dinh danh
    CONSTRAINT CK_users_ident   CHECK  (email IS NOT NULL OR username IS NOT NULL OR phone_number IS NOT NULL)
);
GO

-- ------------------------------------------------------------
-- 3. password_reset_tokens
-- ------------------------------------------------------------
CREATE TABLE password_reset_tokens (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id    UNIQUEIDENTIFIER NOT NULL,
    token      VARCHAR(255)     NOT NULL,
    expired_at DATETIME2        NOT NULL,
    used_at    DATETIME2        NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_prt       PRIMARY KEY (id),
    CONSTRAINT FK_prt_user  FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT UK_prt_token UNIQUE (token)
);
GO

-- ============================================================
-- NHOM CONFIG
-- ============================================================

-- ------------------------------------------------------------
-- 4. system_config
-- ------------------------------------------------------------
CREATE TABLE system_config (
    config_key   VARCHAR(100)     NOT NULL,
    config_value VARCHAR(500)     NOT NULL,
    description  NVARCHAR(255)    NULL,
    updated_by   UNIQUEIDENTIFIER NULL,
    updated_at   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_system_config    PRIMARY KEY (config_key),
    CONSTRAINT FK_sc_updated_by    FOREIGN KEY (updated_by) REFERENCES users(id)
);
GO

-- ------------------------------------------------------------
-- 5. vat_rules
-- ------------------------------------------------------------
CREATE TABLE vat_rules (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    rule_name  NVARCHAR(100)    NOT NULL,
    vat_rate   DECIMAL(5,2)     NOT NULL,
    start_date DATETIME2        NOT NULL,
    end_date   DATETIME2        NULL,
    status     VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_vat_rules    PRIMARY KEY (id),
    CONSTRAINT CK_vat_status   CHECK  (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT CK_vat_rate     CHECK  (vat_rate >= 0 AND vat_rate <= 100),
    CONSTRAINT CK_vat_dates    CHECK  (end_date IS NULL OR end_date > start_date)
);
GO

-- ============================================================
-- NHOM CINEMA
-- ============================================================

-- ------------------------------------------------------------
-- 6. cinema_info  (1 row duy nhat)
-- ------------------------------------------------------------
CREATE TABLE cinema_info (
    id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name          NVARCHAR(255)    NOT NULL,
    address       NVARCHAR(500)    NOT NULL,
    hotline       VARCHAR(20)      NULL,
    email         VARCHAR(255)     NULL,
    opening_hours NVARCHAR(100)    NULL,
    description   NVARCHAR(MAX)    NULL,
    created_at    DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_cinema_info PRIMARY KEY (id)
);
GO

-- ------------------------------------------------------------
-- 7. cinema_rooms
-- ------------------------------------------------------------
CREATE TABLE cinema_rooms (
    id        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    room_name NVARCHAR(100)    NOT NULL,
    capacity  INT              NOT NULL DEFAULT 0,
    status    VARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME2       NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_cinema_rooms        PRIMARY KEY (id),
    CONSTRAINT UK_cinema_rooms_name   UNIQUE (room_name),
    CONSTRAINT CK_cinema_rooms_status CHECK  (status IN ('ACTIVE','MAINTENANCE','INACTIVE')),
    CONSTRAINT CK_cinema_rooms_cap    CHECK  (capacity >= 0)
);
GO

-- ------------------------------------------------------------
-- 8. seat_types
-- ------------------------------------------------------------
CREATE TABLE seat_types (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    type_name        VARCHAR(50)      NOT NULL,
    price_multiplier DECIMAL(5,2)     NOT NULL DEFAULT 1.00,
    description      NVARCHAR(MAX)    NULL,

    CONSTRAINT PK_seat_types          PRIMARY KEY (id),
    CONSTRAINT UK_seat_types_name     UNIQUE (type_name),
    CONSTRAINT CK_seat_types_multi    CHECK  (price_multiplier > 0)
);
GO

-- ------------------------------------------------------------
-- 9. seats
-- ------------------------------------------------------------
CREATE TABLE seats (
    id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    room_id      UNIQUEIDENTIFIER NOT NULL,
    seat_type_id UNIQUEIDENTIFIER NOT NULL,
    seat_row     VARCHAR(10)      NOT NULL,
    seat_column  INT              NOT NULL,
    seat_code    VARCHAR(20)      NOT NULL,
    status       VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT PK_seats           PRIMARY KEY (id),
    CONSTRAINT FK_seats_room      FOREIGN KEY (room_id)      REFERENCES cinema_rooms(id),
    CONSTRAINT FK_seats_type      FOREIGN KEY (seat_type_id) REFERENCES seat_types(id),
    CONSTRAINT UK_seats_code      UNIQUE (room_id, seat_code),
    CONSTRAINT CK_seats_status    CHECK  (status IN ('ACTIVE','BROKEN','BLOCKED')),
    CONSTRAINT CK_seats_col       CHECK  (seat_column > 0)
);
GO

-- ============================================================
-- NHOM MOVIE
-- ============================================================

-- ------------------------------------------------------------
-- 10. movies
-- ------------------------------------------------------------
CREATE TABLE movies (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    title            NVARCHAR(255)    NOT NULL,
    slug             VARCHAR(255)     NOT NULL,
    description      NVARCHAR(MAX)    NULL,
    duration_minutes INT              NOT NULL,
    release_date     DATE             NULL,
    trailer_url      NVARCHAR(MAX)    NULL,
    poster_url       NVARCHAR(MAX)    NULL,
    director         NVARCHAR(255)    NULL,
    cast_members     NVARCHAR(MAX)    NULL,
    language         NVARCHAR(50)     NULL,
    subtitle         NVARCHAR(50)     NULL,
    age_rating       VARCHAR(10)      NULL,
    status           VARCHAR(20)      NOT NULL DEFAULT 'COMING_SOON',
    average_rating   DECIMAL(3,2)     NULL     DEFAULT 0.00,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_movies            PRIMARY KEY (id),
    CONSTRAINT UK_movies_slug       UNIQUE (slug),
    CONSTRAINT CK_movies_duration   CHECK  (duration_minutes > 0),
    CONSTRAINT CK_movies_status     CHECK  (status IN ('COMING_SOON','NOW_SHOWING','ENDED')),
    CONSTRAINT CK_movies_age        CHECK  (age_rating IN ('P','K','T13','T16','T18','C') OR age_rating IS NULL),
    CONSTRAINT CK_movies_rating     CHECK  (average_rating BETWEEN 0.00 AND 5.00 OR average_rating IS NULL)
);
GO

-- ------------------------------------------------------------
-- 11. genres
-- ------------------------------------------------------------
CREATE TABLE genres (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    genre_name NVARCHAR(100)    NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_genres      PRIMARY KEY (id),
    CONSTRAINT UK_genres_name UNIQUE (genre_name)
);
GO

-- ------------------------------------------------------------
-- 12. movie_genres  (junction M-N)
-- ------------------------------------------------------------
CREATE TABLE movie_genres (
    movie_id UNIQUEIDENTIFIER NOT NULL,
    genre_id UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_movie_genres    PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT FK_mg_movie        FOREIGN KEY (movie_id) REFERENCES movies(id),
    CONSTRAINT FK_mg_genre        FOREIGN KEY (genre_id) REFERENCES genres(id)
);
GO

-- ------------------------------------------------------------
-- 13. movie_reviews
-- ------------------------------------------------------------
CREATE TABLE movie_reviews (
    id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    movie_id       UNIQUEIDENTIFIER NOT NULL,
    user_id        UNIQUEIDENTIFIER NOT NULL,
    rating         INT              NOT NULL,
    review_content NVARCHAR(MAX)    NULL,
    created_at     DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_movie_reviews        PRIMARY KEY (id),
    CONSTRAINT FK_mr_movie             FOREIGN KEY (movie_id) REFERENCES movies(id),
    CONSTRAINT FK_mr_user              FOREIGN KEY (user_id)  REFERENCES users(id),
    CONSTRAINT UK_mr_user_movie        UNIQUE (movie_id, user_id),
    CONSTRAINT CK_mr_rating            CHECK  (rating BETWEEN 1 AND 5)
);
GO

-- ============================================================
-- NHOM SHOWTIME
-- ============================================================

-- ------------------------------------------------------------
-- 14. showtimes
-- ------------------------------------------------------------
CREATE TABLE showtimes (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    movie_id   UNIQUEIDENTIFIER NOT NULL,
    room_id    UNIQUEIDENTIFIER NOT NULL,
    start_time DATETIME2        NOT NULL,
    end_time   DATETIME2        NOT NULL,
    base_price DECIMAL(12,2)    NOT NULL,
    status     VARCHAR(20)      NOT NULL DEFAULT 'SCHEDULED',
    created_by UNIQUEIDENTIFIER NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_showtimes         PRIMARY KEY (id),
    CONSTRAINT FK_st_movie          FOREIGN KEY (movie_id)   REFERENCES movies(id),
    CONSTRAINT FK_st_room           FOREIGN KEY (room_id)    REFERENCES cinema_rooms(id),
    CONSTRAINT FK_st_created_by     FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT CK_st_status         CHECK (status IN ('SCHEDULED','OPEN','SOLD_OUT','CANCELLED','FINISHED')),
    CONSTRAINT CK_st_price          CHECK (base_price > 0),
    CONSTRAINT CK_st_times          CHECK (end_time > start_time)
);
GO

-- ------------------------------------------------------------
-- 15. pricing_rules
-- ------------------------------------------------------------
CREATE TABLE pricing_rules (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    rule_name        NVARCHAR(100)    NOT NULL,
    condition_type   VARCHAR(20)      NOT NULL,
    day_of_week      VARCHAR(20)      NULL,
    time_from        TIME             NULL,
    time_to          TIME             NULL,
    date_from        DATE             NULL,
    date_to          DATE             NULL,
    adjustment_type  VARCHAR(20)      NOT NULL,
    adjustment_value DECIMAL(10,2)    NOT NULL,
    priority         INT              NOT NULL DEFAULT 0,
    status           VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_by       UNIQUEIDENTIFIER NOT NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_pricing_rules         PRIMARY KEY (id),
    CONSTRAINT FK_pr_created_by         FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT CK_pr_condition_type     CHECK (condition_type   IN ('DAY_OF_WEEK','TIME_RANGE','DATE_RANGE','SPECIFIC_DATE')),
    CONSTRAINT CK_pr_adjustment_type    CHECK (adjustment_type  IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_pr_status             CHECK (status           IN ('ACTIVE','INACTIVE'))
);
GO

-- ============================================================
-- NHOM BOOKING
-- ============================================================

-- ------------------------------------------------------------
-- 16. seat_holds
-- ------------------------------------------------------------
CREATE TABLE seat_holds (
    id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    showtime_id UNIQUEIDENTIFIER NOT NULL,
    seat_id     UNIQUEIDENTIFIER NOT NULL,
    user_id     UNIQUEIDENTIFIER NULL,
    expired_at  DATETIME2        NOT NULL,
    created_at  DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_seat_holds         PRIMARY KEY (id),
    CONSTRAINT FK_sh_showtime        FOREIGN KEY (showtime_id) REFERENCES showtimes(id),
    CONSTRAINT FK_sh_seat            FOREIGN KEY (seat_id)     REFERENCES seats(id),
    CONSTRAINT FK_sh_user            FOREIGN KEY (user_id)     REFERENCES users(id),
    -- UNIQUE: cot loi chong book trung tai tang DB
    CONSTRAINT UK_sh_showtime_seat   UNIQUE (showtime_id, seat_id)
);
GO

-- ------------------------------------------------------------
-- 17. bookings
-- ------------------------------------------------------------
CREATE TABLE bookings (
    id                   UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_code         VARCHAR(50)      NOT NULL,
    user_id              UNIQUEIDENTIFIER NULL,       -- NULL = walk-in
    showtime_id          UNIQUEIDENTIFIER NOT NULL,
    booking_source       VARCHAR(10)      NOT NULL,
    created_by_staff_id  UNIQUEIDENTIFIER NULL,       -- NULL neu ONLINE
    customer_name        NVARCHAR(255)    NULL,
    customer_phone       VARCHAR(20)      NULL,
    vat_rate_snapshot    DECIMAL(5,2)     NOT NULL,
    total_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    discount_amount      DECIMAL(12,2)    NOT NULL DEFAULT 0,
    final_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    booking_status       VARCHAR(20)      NOT NULL DEFAULT 'PENDING',
    payment_status       VARCHAR(10)      NOT NULL DEFAULT 'UNPAID',
    booked_at            DATETIME2        NOT NULL DEFAULT GETDATE(),
    expired_at           DATETIME2        NULL,       -- NULL neu OFFLINE

    CONSTRAINT PK_bookings              PRIMARY KEY (id),
    CONSTRAINT UK_bookings_code         UNIQUE (booking_code),
    CONSTRAINT FK_bk_user               FOREIGN KEY (user_id)             REFERENCES users(id),
    CONSTRAINT FK_bk_showtime           FOREIGN KEY (showtime_id)         REFERENCES showtimes(id),
    CONSTRAINT FK_bk_staff              FOREIGN KEY (created_by_staff_id) REFERENCES users(id),
    CONSTRAINT CK_bk_source             CHECK (booking_source IN ('ONLINE','OFFLINE')),
    CONSTRAINT CK_bk_status             CHECK (booking_status IN ('PENDING','CONFIRMED','CANCELLED','EXPIRED','REFUNDED')),
    CONSTRAINT CK_bk_payment_status     CHECK (payment_status IN ('UNPAID','PAID','FAILED')),
    CONSTRAINT CK_bk_amounts            CHECK (total_amount >= 0 AND discount_amount >= 0 AND final_amount >= 0),
    CONSTRAINT CK_bk_vat                CHECK (vat_rate_snapshot >= 0 AND vat_rate_snapshot <= 100),
    -- OFFLINE bat buoc co customer_name va customer_phone
    CONSTRAINT CK_bk_offline_info       CHECK (
        booking_source = 'ONLINE'
        OR (booking_source = 'OFFLINE' AND customer_name IS NOT NULL AND customer_phone IS NOT NULL)
    )
);
GO

-- ------------------------------------------------------------
-- 18. booking_seats
-- ------------------------------------------------------------
CREATE TABLE booking_seats (
    id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_id   UNIQUEIDENTIFIER NOT NULL,
    seat_id      UNIQUEIDENTIFIER NOT NULL,
    ticket_price DECIMAL(12,2)    NOT NULL,

    CONSTRAINT PK_booking_seats        PRIMARY KEY (id),
    CONSTRAINT FK_bs_booking           FOREIGN KEY (booking_id) REFERENCES bookings(id),
    CONSTRAINT FK_bs_seat              FOREIGN KEY (seat_id)    REFERENCES seats(id),
    CONSTRAINT UK_bs_booking_seat      UNIQUE (booking_id, seat_id),
    CONSTRAINT CK_bs_price             CHECK  (ticket_price > 0)
);
GO

-- ============================================================
-- NHOM PAYMENT
-- ============================================================

-- ------------------------------------------------------------
-- 19. payments
-- ------------------------------------------------------------
CREATE TABLE payments (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_id       UNIQUEIDENTIFIER NOT NULL,
    payment_method   VARCHAR(20)      NOT NULL,
    payment_source   VARCHAR(10)      NOT NULL,
    transaction_code VARCHAR(255)     NULL,
    amount           DECIMAL(12,2)    NOT NULL,
    cash_received    DECIMAL(12,2)    NULL,       -- chi dung voi CASH
    change_amount    DECIMAL(12,2)    NULL,       -- chi dung voi CASH
    payment_status   VARCHAR(10)      NOT NULL DEFAULT 'PENDING',
    paid_at          DATETIME2        NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_payments              PRIMARY KEY (id),
    CONSTRAINT FK_pay_booking           FOREIGN KEY (booking_id) REFERENCES bookings(id),
    CONSTRAINT CK_pay_method            CHECK (payment_method IN ('VNPAY','MOMO','QR_BANKING','CASH','BANK_TRANSFER')),
    CONSTRAINT CK_pay_source            CHECK (payment_source IN ('ONLINE','OFFLINE')),
    CONSTRAINT CK_pay_status            CHECK (payment_status IN ('PENDING','SUCCESS','FAILED')),
    CONSTRAINT CK_pay_amount            CHECK (amount > 0),
    CONSTRAINT CK_pay_cash              CHECK (cash_received IS NULL OR cash_received >= 0),
    CONSTRAINT CK_pay_change            CHECK (change_amount IS NULL OR change_amount >= 0)
);
GO

-- ============================================================
-- NHOM PROMOTION
-- ============================================================

-- ------------------------------------------------------------
-- 20. promotions
-- ------------------------------------------------------------
CREATE TABLE promotions (
    id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    code                VARCHAR(50)      NOT NULL,
    title               NVARCHAR(255)    NOT NULL,
    description         NVARCHAR(MAX)    NULL,
    discount_type       VARCHAR(20)      NOT NULL,
    discount_value      DECIMAL(12,2)    NOT NULL,
    max_discount_amount DECIMAL(12,2)    NULL,
    min_order_amount    DECIMAL(12,2)    NULL,
    start_date          DATETIME2        NOT NULL,
    end_date            DATETIME2        NOT NULL,
    usage_limit         INT              NULL,
    used_count          INT              NOT NULL DEFAULT 0,
    status              VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_at          DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_promotions            PRIMARY KEY (id),
    CONSTRAINT UK_promotions_code       UNIQUE (code),
    CONSTRAINT CK_promo_type            CHECK  (discount_type IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_promo_status          CHECK  (status IN ('ACTIVE','INACTIVE','EXPIRED')),
    CONSTRAINT CK_promo_value           CHECK  (discount_value > 0),
    CONSTRAINT CK_promo_used            CHECK  (used_count >= 0),
    CONSTRAINT CK_promo_dates           CHECK  (end_date > start_date),
    CONSTRAINT CK_promo_usage           CHECK  (usage_limit IS NULL OR usage_limit > 0),
    CONSTRAINT CK_promo_pct             CHECK  (discount_type <> 'PERCENTAGE' OR (discount_value > 0 AND discount_value <= 100))
);
GO

-- ------------------------------------------------------------
-- 21. booking_promotions  (junction M-N)
-- ------------------------------------------------------------
CREATE TABLE booking_promotions (
    booking_id       UNIQUEIDENTIFIER NOT NULL,
    promotion_id     UNIQUEIDENTIFIER NOT NULL,
    discount_applied DECIMAL(12,2)    NOT NULL,

    CONSTRAINT PK_booking_promotions    PRIMARY KEY (booking_id, promotion_id),
    CONSTRAINT FK_bp_booking            FOREIGN KEY (booking_id)   REFERENCES bookings(id),
    CONSTRAINT FK_bp_promotion          FOREIGN KEY (promotion_id) REFERENCES promotions(id),
    CONSTRAINT CK_bp_discount           CHECK (discount_applied >= 0)
);
GO

-- ============================================================
-- NHOM TICKET
-- ============================================================

-- ------------------------------------------------------------
-- 22. tickets
-- ------------------------------------------------------------
CREATE TABLE tickets (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_seat_id UNIQUEIDENTIFIER NOT NULL,
    ticket_code     VARCHAR(100)     NOT NULL,
    qr_code         NVARCHAR(MAX)    NULL,
    is_printed      BIT              NOT NULL DEFAULT 0,
    issued_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_tickets               PRIMARY KEY (id),
    CONSTRAINT FK_tk_booking_seat       FOREIGN KEY (booking_seat_id) REFERENCES booking_seats(id),
    CONSTRAINT UK_tickets_booking_seat  UNIQUE (booking_seat_id),      -- enforce 1-1
    CONSTRAINT UK_tickets_code          UNIQUE (ticket_code)
);
GO

-- ============================================================
-- NHOM LOYALTY
-- ============================================================

-- ------------------------------------------------------------
-- 23. loyalty_points_log
-- ------------------------------------------------------------
CREATE TABLE loyalty_points_log (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id          UNIQUEIDENTIFIER NOT NULL,
    booking_id       UNIQUEIDENTIFIER NULL,       -- NULL neu la ADJUST thu cong
    points_delta     INT              NOT NULL,   -- duong = cong, am = tru
    transaction_type VARCHAR(20)      NOT NULL,
    note             NVARCHAR(255)    NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_loyalty_log       PRIMARY KEY (id),
    CONSTRAINT FK_ll_user           FOREIGN KEY (user_id)    REFERENCES users(id),
    CONSTRAINT FK_ll_booking        FOREIGN KEY (booking_id) REFERENCES bookings(id),
    CONSTRAINT CK_ll_type           CHECK (transaction_type IN ('EARN','REDEEM','REFUND_POINTS','ADJUST')),
    -- EARN/REFUND_POINTS: duong; REDEEM: am
    CONSTRAINT CK_ll_delta_earn     CHECK (transaction_type NOT IN ('EARN','REFUND_POINTS') OR points_delta > 0),
    CONSTRAINT CK_ll_delta_redeem   CHECK (transaction_type <> 'REDEEM' OR points_delta < 0)
);
GO

-- ============================================================
-- NHOM INCIDENT
-- ============================================================

-- ------------------------------------------------------------
-- 24. showtime_incidents
-- ------------------------------------------------------------
CREATE TABLE showtime_incidents (
    id                           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    showtime_id                  UNIQUEIDENTIFIER NOT NULL,
    description                  NVARCHAR(MAX)    NOT NULL,
    refund_points_rate           DECIMAL(3,2)     NOT NULL DEFAULT 1.00,
    compensation_discount_type   VARCHAR(20)      NOT NULL,
    compensation_discount_value  DECIMAL(12,2)    NOT NULL,
    compensation_valid_days      INT              NOT NULL DEFAULT 30,
    processed_at                 DATETIME2        NULL,
    created_by                   UNIQUEIDENTIFIER NOT NULL,
    created_at                   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_si                  PRIMARY KEY (id),
    CONSTRAINT FK_si_showtime         FOREIGN KEY (showtime_id) REFERENCES showtimes(id),
    CONSTRAINT FK_si_created_by       FOREIGN KEY (created_by)  REFERENCES users(id),
    CONSTRAINT UK_si_showtime         UNIQUE (showtime_id),     -- 1 suat chi co 1 incident
    CONSTRAINT CK_si_discount_type    CHECK  (compensation_discount_type IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_si_refund_rate      CHECK  (refund_points_rate BETWEEN 0.00 AND 1.00),
    CONSTRAINT CK_si_valid_days       CHECK  (compensation_valid_days > 0),
    CONSTRAINT CK_si_comp_value       CHECK  (compensation_discount_value > 0)
);
GO

-- ============================================================
-- NHOM CHATBOT
-- ============================================================

-- ------------------------------------------------------------
-- 25. chatbot_conversations
-- ------------------------------------------------------------
CREATE TABLE chatbot_conversations (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id    UNIQUEIDENTIFIER NULL,       -- NULL = Guest
    session_id VARCHAR(255)     NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_chatbot_conv      PRIMARY KEY (id),
    CONSTRAINT FK_cc_user           FOREIGN KEY (user_id) REFERENCES users(id)
);
GO

-- ------------------------------------------------------------
-- 26. chatbot_messages
-- ------------------------------------------------------------
CREATE TABLE chatbot_messages (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    conversation_id UNIQUEIDENTIFIER NOT NULL,
    sender_type     VARCHAR(5)       NOT NULL,
    message_content NVARCHAR(MAX)    NOT NULL,
    created_at      DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_chatbot_msg       PRIMARY KEY (id),
    CONSTRAINT FK_cm_conversation   FOREIGN KEY (conversation_id) REFERENCES chatbot_conversations(id),
    CONSTRAINT CK_cm_sender         CHECK (sender_type IN ('USER','BOT'))
);
GO

-- ============================================================
-- INDEXES PERFORMANCE
-- ============================================================

-- movies
CREATE INDEX IX_movies_status       ON movies(status);
CREATE INDEX IX_movies_release      ON movies(release_date);

-- showtimes
CREATE INDEX IX_st_movie_room       ON showtimes(movie_id, room_id);
CREATE INDEX IX_st_start_time       ON showtimes(start_time);
CREATE INDEX IX_st_status           ON showtimes(status);

-- seats
CREATE INDEX IX_seats_room          ON seats(room_id);
CREATE INDEX IX_seats_status        ON seats(room_id, status);

-- seat_holds: rat quan trong cho scheduled job cleanup
CREATE INDEX IX_sh_expired          ON seat_holds(expired_at);
CREATE INDEX IX_sh_showtime_seat    ON seat_holds(showtime_id, seat_id);

-- bookings
CREATE INDEX IX_bk_user             ON bookings(user_id);
CREATE INDEX IX_bk_showtime         ON bookings(showtime_id);
CREATE INDEX IX_bk_status           ON bookings(booking_status, payment_status);
CREATE INDEX IX_bk_booked_at        ON bookings(booked_at);
CREATE INDEX IX_bk_source           ON bookings(booking_source);
CREATE INDEX IX_bk_expired          ON bookings(expired_at) WHERE expired_at IS NOT NULL;

-- booking_seats
CREATE INDEX IX_bs_booking          ON booking_seats(booking_id);
CREATE INDEX IX_bs_seat             ON booking_seats(seat_id);

-- payments
CREATE INDEX IX_pay_booking         ON payments(booking_id);
CREATE INDEX IX_pay_paid_at         ON payments(paid_at);
CREATE INDEX IX_pay_status          ON payments(payment_status);

-- promotions
CREATE INDEX IX_promo_status        ON promotions(status);
CREATE INDEX IX_promo_dates         ON promotions(start_date, end_date);

-- movie_reviews
CREATE INDEX IX_mr_movie            ON movie_reviews(movie_id);

-- loyalty_points_log
CREATE INDEX IX_ll_user             ON loyalty_points_log(user_id, created_at);
CREATE INDEX IX_ll_booking          ON loyalty_points_log(booking_id);

-- chatbot_messages
CREATE INDEX IX_cm_conversation     ON chatbot_messages(conversation_id, created_at);
GO

-- ============================================================
-- SEED DATA — DU LIEU MAC DINH
-- ============================================================

-- 4 vai tro co ban
INSERT INTO roles (id, role_name, description) VALUES
    (NEWID(), 'ADMIN',    N'Quản trị toàn hệ thống'),
    (NEWID(), 'MANAGER',  N'Quản lý rạp: phim, suất chiếu, báo cáo'),
    (NEWID(), 'STAFF',    N'Nhân viên bán vé tại quầy'),
    (NEWID(), 'CUSTOMER', N'Khách hàng đặt vé online');
GO

-- system_config: tham so loyalty points
INSERT INTO system_config (config_key, config_value, description) VALUES
    ('loyalty_earn_rate',          '1',    N'Số điểm nhận được trên mỗi 1.000đ chi tiêu (final_amount)'),
    ('loyalty_redeem_rate',        '100',  N'Số điểm cần để đổi 10.000đ giảm giá'),
    ('loyalty_min_redeem',         '100',  N'Điểm tối thiểu được phép đổi trong 1 đơn'),
    ('loyalty_max_redeem_per_order','5000', N'Điểm tối đa được đổi trong 1 đơn');
GO

-- vat_rules: thue suat mac dinh 10% (khong co ngay ket thuc)
INSERT INTO vat_rules (id, rule_name, vat_rate, start_date, end_date, status) VALUES
    (NEWID(), N'VAT Vé Phim mặc định 10%', 10.00, '2024-01-01', NULL, 'ACTIVE');
GO

-- seat_types mac dinh
INSERT INTO seat_types (id, type_name, price_multiplier, description) VALUES
    (NEWID(), 'REGULAR', 1.00, N'Ghế thường'),
    (NEWID(), 'VIP',     1.50, N'Ghế VIP - rộng hơn, vị trí trung tâm'),
    (NEWID(), 'COUPLE',  2.00, N'Ghế đôi dành cho 2 người'),
    (NEWID(), 'SWEETBOX',2.50, N'Ghế sweetbox - riêng tư, có bàn nhỏ');
GO

PRINT N'=== Tao database thanh cong: 26 bang, indexes, seed data ===';
GO
