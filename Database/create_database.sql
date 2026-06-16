-- ============================================================
-- Movie Ticket Booking System
-- SQL Server — SCRIPT DUY NHAT (schema + seed data day du)
-- ============================================================
-- Chay file nay MOT LAN trong SSMS / Azure Data Studio (Ctrl+A -> F5)
-- Khong can chay them migration_*.sql
--
-- Bao gom:
--   - 28 bang (PascalCase)
--   - Seed: Roles, Users, Config, Cinema, Chatbot
--   - Seed homepage: Genres (is_active, description), CinemaRooms, 8 Movies, MovieGenres
--
-- Luu y:
--   - UUID     -> UNIQUEIDENTIFIER + DEFAULT NEWID()
--   - ENUM     -> NVARCHAR + CHECK constraint
--   - Chay lai script se DROP va TAO LAI toan bo bang (mat du lieu cu)
-- ============================================================

USE master;
GO

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
IF OBJECT_ID('ChatbotMessages',       'U') IS NOT NULL DROP TABLE ChatbotMessages;
IF OBJECT_ID('ChatbotConversations',  'U') IS NOT NULL DROP TABLE ChatbotConversations;
IF OBJECT_ID('ShowtimeIncidents',     'U') IS NOT NULL DROP TABLE ShowtimeIncidents;
IF OBJECT_ID('LoyaltyPointsLog',      'U') IS NOT NULL DROP TABLE LoyaltyPointsLog;
IF OBJECT_ID('Tickets',               'U') IS NOT NULL DROP TABLE Tickets;
IF OBJECT_ID('BookingPromotions',     'U') IS NOT NULL DROP TABLE BookingPromotions;
IF OBJECT_ID('Promotions',            'U') IS NOT NULL DROP TABLE Promotions;
IF OBJECT_ID('Payments',              'U') IS NOT NULL DROP TABLE Payments;
IF OBJECT_ID('BookingSeats',          'U') IS NOT NULL DROP TABLE BookingSeats;
IF OBJECT_ID('Bookings',              'U') IS NOT NULL DROP TABLE Bookings;
IF OBJECT_ID('SeatHolds',             'U') IS NOT NULL DROP TABLE SeatHolds;
IF OBJECT_ID('PricingRules',          'U') IS NOT NULL DROP TABLE PricingRules;
IF OBJECT_ID('Showtimes',             'U') IS NOT NULL DROP TABLE Showtimes;
IF OBJECT_ID('MovieReviews',          'U') IS NOT NULL DROP TABLE MovieReviews;
IF OBJECT_ID('MovieGenres',           'U') IS NOT NULL DROP TABLE MovieGenres;
IF OBJECT_ID('Genres',                'U') IS NOT NULL DROP TABLE Genres;
IF OBJECT_ID('Movies',                'U') IS NOT NULL DROP TABLE Movies;
IF OBJECT_ID('Seats',                 'U') IS NOT NULL DROP TABLE Seats;
IF OBJECT_ID('SeatTypes',             'U') IS NOT NULL DROP TABLE SeatTypes;
IF OBJECT_ID('CinemaRooms',           'U') IS NOT NULL DROP TABLE CinemaRooms;
IF OBJECT_ID('CinemaInfo',            'U') IS NOT NULL DROP TABLE CinemaInfo;
IF OBJECT_ID('VatRules',              'U') IS NOT NULL DROP TABLE VatRules;
IF OBJECT_ID('SystemConfigLog',       'U') IS NOT NULL DROP TABLE SystemConfigLog;
IF OBJECT_ID('UserStatusLog',         'U') IS NOT NULL DROP TABLE UserStatusLog;
IF OBJECT_ID('SystemConfig',          'U') IS NOT NULL DROP TABLE SystemConfig;
IF OBJECT_ID('PasswordResetTokens',  'U') IS NOT NULL DROP TABLE PasswordResetTokens;
IF OBJECT_ID('Users',                 'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('Roles',                 'U') IS NOT NULL DROP TABLE Roles;
GO

-- ============================================================
-- NHOM AUTH
-- ============================================================

-- ------------------------------------------------------------
-- 1. Roles
-- ------------------------------------------------------------
CREATE TABLE Roles (
    id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    role_name   NVARCHAR(50)      NOT NULL,
    description NVARCHAR(255)     NULL,
    created_at  DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Roles      PRIMARY KEY (id),
    CONSTRAINT UK_Roles_Name UNIQUE      (role_name),
    CONSTRAINT CK_Roles_Name CHECK (role_name IN ('CUSTOMER','STAFF','MANAGER','ADMIN'))
);
GO

-- ------------------------------------------------------------
-- 2. Users
-- ------------------------------------------------------------
CREATE TABLE Users (
    id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    role_id        UNIQUEIDENTIFIER NOT NULL,
    email          NVARCHAR(255)     NULL,
    username       NVARCHAR(100)     NULL,
    phone_number   NVARCHAR(20)      NULL,
    password_hash  NVARCHAR(255)     NOT NULL,
    full_name      NVARCHAR(255)    NOT NULL,
    date_of_birth  DATE             NOT NULL,
    avatar_url     NVARCHAR(MAX)    NULL,
    status         NVARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
    loyalty_points INT              NOT NULL DEFAULT 0,
    last_login_at  DATETIME2        NULL,
    created_at     DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Users         PRIMARY KEY (id),
    CONSTRAINT FK_Users_Role    FOREIGN KEY (role_id)      REFERENCES Roles(id),
    CONSTRAINT UK_Users_Email     UNIQUE (email),
    CONSTRAINT UK_Users_Uname     UNIQUE (username),
    CONSTRAINT UK_Users_Phone     UNIQUE (phone_number),
    CONSTRAINT CK_Users_Status    CHECK  (status IN ('ACTIVE','INACTIVE','BANNED')),
    CONSTRAINT CK_Users_Loyalty   CHECK  (loyalty_points >= 0),
    CONSTRAINT CK_Users_Dob       CHECK  (date_of_birth <= CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Users_Ident     CHECK  (email IS NOT NULL OR username IS NOT NULL OR phone_number IS NOT NULL)
);
GO

-- ------------------------------------------------------------
-- 3. PasswordResetTokens
-- ------------------------------------------------------------
CREATE TABLE PasswordResetTokens (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id    UNIQUEIDENTIFIER NOT NULL,
    token      NVARCHAR(255)     NOT NULL,
    expired_at DATETIME2        NOT NULL,
    used_at    DATETIME2        NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_PasswordResetTokens       PRIMARY KEY (id),
    CONSTRAINT FK_PasswordResetTokens_User  FOREIGN KEY (user_id) REFERENCES Users(id),
    CONSTRAINT UK_PasswordResetTokens_Token UNIQUE (token)
);
GO

-- ============================================================
-- NHOM CONFIG
-- ============================================================

-- ------------------------------------------------------------
-- 4. SystemConfig
-- ------------------------------------------------------------
CREATE TABLE SystemConfig (
    config_key   NVARCHAR(100)     NOT NULL,
    config_value NVARCHAR(500)     NOT NULL,
    description  NVARCHAR(255)    NULL,
    updated_by   UNIQUEIDENTIFIER NULL,
    updated_at   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_SystemConfig         PRIMARY KEY (config_key),
    CONSTRAINT FK_SystemConfig_Updated FOREIGN KEY (updated_by) REFERENCES Users(id)
);
GO

-- ------------------------------------------------------------
-- 4b. SystemConfigLog — lịch sử chỉnh sửa loyalty
-- ------------------------------------------------------------
CREATE TABLE SystemConfigLog (
    id                            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    earn_rate                     NVARCHAR(20)     NOT NULL,
    redeem_rate                   NVARCHAR(20)     NOT NULL,
    min_redeem                    NVARCHAR(20)     NOT NULL,
    max_redeem_per_order          NVARCHAR(20)     NOT NULL,
    previous_earn_rate            NVARCHAR(20)     NULL,
    previous_redeem_rate          NVARCHAR(20)     NULL,
    previous_min_redeem           NVARCHAR(20)     NULL,
    previous_max_redeem_per_order NVARCHAR(20)     NULL,
    updated_by                    UNIQUEIDENTIFIER NULL,
    updated_at                    DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_SystemConfigLog      PRIMARY KEY (id),
    CONSTRAINT FK_SystemConfigLog_User FOREIGN KEY (updated_by) REFERENCES Users(id)
);
GO

-- ------------------------------------------------------------
-- 4c. UserStatusLog — lịch sử khóa / mở khóa tài khoản
-- ------------------------------------------------------------
CREATE TABLE UserStatusLog (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id         UNIQUEIDENTIFIER NOT NULL,
    action          NVARCHAR(20)     NOT NULL,
    previous_status NVARCHAR(20)     NOT NULL,
    new_status      NVARCHAR(20)     NOT NULL,
    reason          NVARCHAR(500)    NULL,
    email_sent      BIT              NOT NULL DEFAULT 0,
    email_error     NVARCHAR(255)    NULL,
    performed_by    UNIQUEIDENTIFIER NULL,
    performed_at    DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_UserStatusLog           PRIMARY KEY (id),
    CONSTRAINT FK_UserStatusLog_User        FOREIGN KEY (user_id)      REFERENCES Users(id),
    CONSTRAINT FK_UserStatusLog_PerformedBy FOREIGN KEY (performed_by) REFERENCES Users(id),
    CONSTRAINT CK_UserStatusLog_Action      CHECK (action IN ('LOCK','UNLOCK','DEACTIVATE')),
    CONSTRAINT CK_UserStatusLog_PrevStatus  CHECK (previous_status IN ('ACTIVE','INACTIVE','BANNED')),
    CONSTRAINT CK_UserStatusLog_NewStatus   CHECK (new_status IN ('ACTIVE','INACTIVE','BANNED'))
);
GO

-- ------------------------------------------------------------
-- 5. VatRules
-- ------------------------------------------------------------
CREATE TABLE VatRules (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    rule_name  NVARCHAR(100)    NOT NULL,
    vat_rate   DECIMAL(5,2)     NOT NULL,
    start_date DATETIME2        NOT NULL,
    end_date   DATETIME2        NULL,
    status     NVARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_VatRules    PRIMARY KEY (id),
    CONSTRAINT CK_VatRules_Status CHECK  (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT CK_VatRules_Rate   CHECK  (vat_rate >= 0 AND vat_rate <= 100),
    CONSTRAINT CK_VatRules_Dates  CHECK  (end_date IS NULL OR end_date > start_date)
);
GO

-- ============================================================
-- NHOM CINEMA
-- ============================================================

-- ------------------------------------------------------------
-- 6. CinemaInfo  (1 row duy nhat)
-- ------------------------------------------------------------
CREATE TABLE CinemaInfo (
    id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    name          NVARCHAR(255)    NOT NULL,
    address       NVARCHAR(500)    NOT NULL,
    hotline       NVARCHAR(20)      NULL,
    email         NVARCHAR(255)     NULL,
    opening_hours NVARCHAR(100)    NULL,
    description   NVARCHAR(MAX)    NULL,
    created_at    DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_CinemaInfo PRIMARY KEY (id)
);
GO

-- ------------------------------------------------------------
-- 7. CinemaRooms
-- ------------------------------------------------------------
CREATE TABLE CinemaRooms (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    room_name  NVARCHAR(100)    NOT NULL,
    capacity   INT              NOT NULL DEFAULT 0,
    status     NVARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_CinemaRooms        PRIMARY KEY (id),
    CONSTRAINT UK_CinemaRooms_Name   UNIQUE (room_name),
    CONSTRAINT CK_CinemaRooms_Status CHECK  (status IN ('ACTIVE','MAINTENANCE','INACTIVE')),
    CONSTRAINT CK_CinemaRooms_Cap    CHECK  (capacity >= 0)
);
GO

-- ------------------------------------------------------------
-- 8. SeatTypes
-- ------------------------------------------------------------
CREATE TABLE SeatTypes (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    type_name        NVARCHAR(50)      NOT NULL,
    price_multiplier DECIMAL(5,2)     NOT NULL DEFAULT 1.00,
    description      NVARCHAR(MAX)    NULL,

    CONSTRAINT PK_SeatTypes       PRIMARY KEY (id),
    CONSTRAINT UK_SeatTypes_Name  UNIQUE (type_name),
    CONSTRAINT CK_SeatTypes_Multi CHECK  (price_multiplier > 0)
);
GO

-- ------------------------------------------------------------
-- 9. Seats
-- ------------------------------------------------------------
CREATE TABLE Seats (
    id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    room_id      UNIQUEIDENTIFIER NOT NULL,
    seat_type_id UNIQUEIDENTIFIER NOT NULL,
    seat_row     NVARCHAR(10)      NOT NULL,
    seat_column  INT              NOT NULL,
    seat_code    NVARCHAR(20)      NOT NULL,
    status       NVARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT PK_Seats         PRIMARY KEY (id),
    CONSTRAINT FK_Seats_Room    FOREIGN KEY (room_id)      REFERENCES CinemaRooms(id),
    CONSTRAINT FK_Seats_Type    FOREIGN KEY (seat_type_id) REFERENCES SeatTypes(id),
    CONSTRAINT UK_Seats_Code    UNIQUE (room_id, seat_code),
    CONSTRAINT CK_Seats_Status  CHECK  (status IN ('ACTIVE','BROKEN','BLOCKED')),
    CONSTRAINT CK_Seats_Col     CHECK  (seat_column > 0)
);
GO

-- ============================================================
-- NHOM MOVIE
-- ============================================================

-- ------------------------------------------------------------
-- 10. Movies
-- ------------------------------------------------------------
CREATE TABLE Movies (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    title            NVARCHAR(255)    NOT NULL,
    slug             NVARCHAR(255)     NOT NULL,
    description      NVARCHAR(MAX)    NULL,
    duration_minutes INT              NOT NULL,
    release_date     DATE             NULL,
    trailer_url      NVARCHAR(MAX)    NULL,
    poster_url       NVARCHAR(MAX)    NULL,
    backdrop_url     NVARCHAR(MAX)    NULL,
    director         NVARCHAR(255)    NULL,
    cast_members     NVARCHAR(MAX)    NULL,
    language         NVARCHAR(50)     NULL,
    subtitle         NVARCHAR(50)     NULL,
    age_rating       NVARCHAR(10)      NULL,
    status           NVARCHAR(20)      NOT NULL DEFAULT 'COMING_SOON',
    average_rating   DECIMAL(3,2)     NULL     DEFAULT 0.00,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Movies          PRIMARY KEY (id),
    CONSTRAINT UK_Movies_Slug     UNIQUE (slug),
    CONSTRAINT CK_Movies_Duration CHECK  (duration_minutes > 0),
    CONSTRAINT CK_Movies_Status   CHECK  (status IN ('COMING_SOON','NOW_SHOWING','EARLY_SHOWING','ENDED')),
    CONSTRAINT CK_Movies_Age      CHECK  (age_rating IN ('P','K','T13','T16','T18','C') OR age_rating IS NULL),
    CONSTRAINT CK_Movies_Rating   CHECK  (average_rating BETWEEN 0.00 AND 5.00 OR average_rating IS NULL)
);
GO

-- ------------------------------------------------------------
-- 11. Genres
-- ------------------------------------------------------------
CREATE TABLE Genres (
    id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    genre_name  NVARCHAR(100)    NOT NULL,
    description NVARCHAR(500)    NULL,
    is_active   BIT              NOT NULL DEFAULT 1,
    created_at  DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Genres      PRIMARY KEY (id),
    CONSTRAINT UK_Genres_Name UNIQUE (genre_name)
);
GO

-- ------------------------------------------------------------
-- 12. MovieGenres  (junction M-N)
-- ------------------------------------------------------------
CREATE TABLE MovieGenres (
    movie_id UNIQUEIDENTIFIER NOT NULL,
    genre_id UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_MovieGenres    PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT FK_MovieGenres_Movie FOREIGN KEY (movie_id) REFERENCES Movies(id),
    CONSTRAINT FK_MovieGenres_Genre FOREIGN KEY (genre_id) REFERENCES Genres(id)
);
GO

-- ------------------------------------------------------------
-- 13. MovieReviews
-- ------------------------------------------------------------
CREATE TABLE MovieReviews (
    id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    movie_id       UNIQUEIDENTIFIER NOT NULL,
    user_id        UNIQUEIDENTIFIER NOT NULL,
    rating         INT              NOT NULL,
    review_content NVARCHAR(MAX)    NULL,
    created_at     DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_MovieReviews     PRIMARY KEY (id),
    CONSTRAINT FK_MovieReviews_Movie FOREIGN KEY (movie_id) REFERENCES Movies(id),
    CONSTRAINT FK_MovieReviews_User  FOREIGN KEY (user_id)  REFERENCES Users(id),
    CONSTRAINT UK_MovieReviews_UserMovie UNIQUE (movie_id, user_id),
    CONSTRAINT CK_MovieReviews_Rating    CHECK  (rating BETWEEN 1 AND 5)
);
GO

-- ============================================================
-- NHOM SHOWTIME
-- ============================================================

-- ------------------------------------------------------------
-- 14. Showtimes
-- ------------------------------------------------------------
CREATE TABLE Showtimes (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    movie_id   UNIQUEIDENTIFIER NOT NULL,
    room_id    UNIQUEIDENTIFIER NOT NULL,
    start_time DATETIME2        NOT NULL,
    end_time   DATETIME2        NOT NULL,
    base_price DECIMAL(12,2)    NOT NULL,
    status     NVARCHAR(20)      NOT NULL DEFAULT 'SCHEDULED',
    created_by UNIQUEIDENTIFIER NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Showtimes         PRIMARY KEY (id),
    CONSTRAINT FK_Showtimes_Movie   FOREIGN KEY (movie_id)   REFERENCES Movies(id),
    CONSTRAINT FK_Showtimes_Room    FOREIGN KEY (room_id)    REFERENCES CinemaRooms(id),
    CONSTRAINT FK_Showtimes_Created FOREIGN KEY (created_by) REFERENCES Users(id),
    CONSTRAINT CK_Showtimes_Status  CHECK (status IN ('SCHEDULED','OPEN','SOLD_OUT','CANCELLED','FINISHED')),
    CONSTRAINT CK_Showtimes_Price   CHECK (base_price > 0),
    CONSTRAINT CK_Showtimes_Times   CHECK (end_time > start_time)
);
GO

-- ------------------------------------------------------------
-- 15. PricingRules
-- ------------------------------------------------------------
CREATE TABLE PricingRules (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    rule_name        NVARCHAR(100)    NOT NULL,
    condition_type   NVARCHAR(20)      NOT NULL,
    day_of_week      NVARCHAR(20)      NULL,
    time_from        TIME             NULL,
    time_to          TIME             NULL,
    date_from        DATE             NULL,
    date_to          DATE             NULL,
    adjustment_type  NVARCHAR(20)      NOT NULL,
    adjustment_value DECIMAL(10,2)    NOT NULL,
    priority         INT              NOT NULL DEFAULT 0,
    status           NVARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_by       UNIQUEIDENTIFIER NOT NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_PricingRules         PRIMARY KEY (id),
    CONSTRAINT FK_PricingRules_Created FOREIGN KEY (created_by) REFERENCES Users(id),
    CONSTRAINT CK_PricingRules_Condition CHECK (condition_type   IN ('DAY_OF_WEEK','TIME_RANGE','DATE_RANGE','SPECIFIC_DATE')),
    CONSTRAINT CK_PricingRules_Adjust  CHECK (adjustment_type  IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_PricingRules_Status  CHECK (status           IN ('ACTIVE','INACTIVE'))
);
GO

-- ============================================================
-- NHOM BOOKING
-- ============================================================

-- ------------------------------------------------------------
-- 16. SeatHolds
-- ------------------------------------------------------------
CREATE TABLE SeatHolds (
    id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    showtime_id UNIQUEIDENTIFIER NOT NULL,
    seat_id     UNIQUEIDENTIFIER NOT NULL,
    user_id     UNIQUEIDENTIFIER NULL,
    expired_at  DATETIME2        NOT NULL,
    created_at  DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_SeatHolds           PRIMARY KEY (id),
    CONSTRAINT FK_SeatHolds_Showtime  FOREIGN KEY (showtime_id) REFERENCES Showtimes(id),
    CONSTRAINT FK_SeatHolds_Seat      FOREIGN KEY (seat_id)     REFERENCES Seats(id),
    CONSTRAINT FK_SeatHolds_User      FOREIGN KEY (user_id)     REFERENCES Users(id),
    CONSTRAINT UK_SeatHolds_ShowtimeSeat UNIQUE (showtime_id, seat_id)
);
GO

-- ------------------------------------------------------------
-- 17. Bookings
-- ------------------------------------------------------------
CREATE TABLE Bookings (
    id                   UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_code         NVARCHAR(50)      NOT NULL,
    user_id              UNIQUEIDENTIFIER NULL,
    showtime_id          UNIQUEIDENTIFIER NOT NULL,
    booking_source       NVARCHAR(10)      NOT NULL,
    created_by_staff_id  UNIQUEIDENTIFIER NULL,
    customer_name        NVARCHAR(255)    NULL,
    customer_phone       NVARCHAR(20)      NULL,
    vat_rate_snapshot    DECIMAL(5,2)     NOT NULL,
    total_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    discount_amount      DECIMAL(12,2)    NOT NULL DEFAULT 0,
    final_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    booking_status       NVARCHAR(20)      NOT NULL DEFAULT 'PENDING',
    payment_status       NVARCHAR(10)      NOT NULL DEFAULT 'UNPAID',
    booked_at            DATETIME2        NOT NULL DEFAULT GETDATE(),
    expired_at           DATETIME2        NULL,

    CONSTRAINT PK_Bookings              PRIMARY KEY (id),
    CONSTRAINT UK_Bookings_Code         UNIQUE (booking_code),
    CONSTRAINT FK_Bookings_User         FOREIGN KEY (user_id)             REFERENCES Users(id),
    CONSTRAINT FK_Bookings_Showtime     FOREIGN KEY (showtime_id)         REFERENCES Showtimes(id),
    CONSTRAINT FK_Bookings_Staff        FOREIGN KEY (created_by_staff_id) REFERENCES Users(id),
    CONSTRAINT CK_Bookings_Source       CHECK (booking_source IN ('ONLINE','OFFLINE')),
    CONSTRAINT CK_Bookings_Status       CHECK (booking_status IN ('PENDING','CONFIRMED','CANCELLED','EXPIRED','REFUNDED')),
    CONSTRAINT CK_Bookings_PayStatus    CHECK (payment_status IN ('UNPAID','PAID','FAILED')),
    CONSTRAINT CK_Bookings_Amounts      CHECK (total_amount >= 0 AND discount_amount >= 0 AND final_amount >= 0),
    CONSTRAINT CK_Bookings_Vat          CHECK (vat_rate_snapshot >= 0 AND vat_rate_snapshot <= 100),
    CONSTRAINT CK_Bookings_OfflineInfo  CHECK (
        booking_source = 'ONLINE'
        OR (booking_source = 'OFFLINE' AND customer_name IS NOT NULL AND customer_phone IS NOT NULL)
    )
);
GO

-- ------------------------------------------------------------
-- 18. BookingSeats
-- ------------------------------------------------------------
CREATE TABLE BookingSeats (
    id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_id   UNIQUEIDENTIFIER NOT NULL,
    seat_id      UNIQUEIDENTIFIER NOT NULL,
    ticket_price DECIMAL(12,2)    NOT NULL,

    CONSTRAINT PK_BookingSeats        PRIMARY KEY (id),
    CONSTRAINT FK_BookingSeats_Booking FOREIGN KEY (booking_id) REFERENCES Bookings(id),
    CONSTRAINT FK_BookingSeats_Seat    FOREIGN KEY (seat_id)    REFERENCES Seats(id),
    CONSTRAINT UK_BookingSeats_BookingSeat UNIQUE (booking_id, seat_id),
    CONSTRAINT CK_BookingSeats_Price   CHECK  (ticket_price > 0)
);
GO

-- ============================================================
-- NHOM PAYMENT
-- ============================================================

-- ------------------------------------------------------------
-- 19. Payments
-- ------------------------------------------------------------
CREATE TABLE Payments (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_id       UNIQUEIDENTIFIER NOT NULL,
    payment_method   NVARCHAR(20)      NOT NULL,
    payment_source   NVARCHAR(10)      NOT NULL,
    transaction_code NVARCHAR(255)     NULL,
    amount           DECIMAL(12,2)    NOT NULL,
    cash_received    DECIMAL(12,2)    NULL,
    change_amount    DECIMAL(12,2)    NULL,
    payment_status   NVARCHAR(10)      NOT NULL DEFAULT 'PENDING',
    paid_at          DATETIME2        NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Payments         PRIMARY KEY (id),
    CONSTRAINT FK_Payments_Booking FOREIGN KEY (booking_id) REFERENCES Bookings(id),
    CONSTRAINT CK_Payments_Method  CHECK (payment_method IN ('VNPAY','MOMO','CASH')),
    CONSTRAINT CK_Payments_Source  CHECK (payment_source IN ('ONLINE','OFFLINE')),
    CONSTRAINT CK_Payments_Status  CHECK (payment_status IN ('PENDING','SUCCESS','FAILED')),
    CONSTRAINT CK_Payments_Amount  CHECK (amount > 0),
    CONSTRAINT CK_Payments_Cash    CHECK (cash_received IS NULL OR cash_received >= 0),
    CONSTRAINT CK_Payments_Change  CHECK (change_amount IS NULL OR change_amount >= 0)
);
GO

-- ============================================================
-- NHOM PROMOTION
-- ============================================================

-- ------------------------------------------------------------
-- 20. Promotions
-- ------------------------------------------------------------
CREATE TABLE Promotions (
    id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    code                NVARCHAR(50)      NOT NULL,
    title               NVARCHAR(255)    NOT NULL,
    description         NVARCHAR(MAX)    NULL,
    discount_type       NVARCHAR(20)      NOT NULL,
    discount_value      DECIMAL(12,2)    NOT NULL,
    max_discount_amount DECIMAL(12,2)    NULL,
    min_order_amount    DECIMAL(12,2)    NULL,
    start_date          DATETIME2        NOT NULL,
    end_date            DATETIME2        NOT NULL,
    usage_limit         INT              NULL,
    used_count          INT              NOT NULL DEFAULT 0,
    status              NVARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    created_at          DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Promotions         PRIMARY KEY (id),
    CONSTRAINT UK_Promotions_Code    UNIQUE (code),
    CONSTRAINT CK_Promotions_Type    CHECK  (discount_type IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_Promotions_Status  CHECK  (status IN ('ACTIVE','INACTIVE','EXPIRED')),
    CONSTRAINT CK_Promotions_Value   CHECK  (discount_value > 0),
    CONSTRAINT CK_Promotions_Used    CHECK  (used_count >= 0),
    CONSTRAINT CK_Promotions_Dates   CHECK  (end_date > start_date),
    CONSTRAINT CK_Promotions_Usage   CHECK  (usage_limit IS NULL OR usage_limit > 0),
    CONSTRAINT CK_Promotions_Pct     CHECK  (discount_type <> 'PERCENTAGE' OR (discount_value > 0 AND discount_value <= 100))
);
GO

-- ------------------------------------------------------------
-- 21. BookingPromotions  (junction M-N)
-- ------------------------------------------------------------
CREATE TABLE BookingPromotions (
    booking_id       UNIQUEIDENTIFIER NOT NULL,
    promotion_id     UNIQUEIDENTIFIER NOT NULL,
    discount_applied DECIMAL(12,2)    NOT NULL,

    CONSTRAINT PK_BookingPromotions    PRIMARY KEY (booking_id, promotion_id),
    CONSTRAINT FK_BookingPromotions_Booking   FOREIGN KEY (booking_id)   REFERENCES Bookings(id),
    CONSTRAINT FK_BookingPromotions_Promotion FOREIGN KEY (promotion_id) REFERENCES Promotions(id),
    CONSTRAINT CK_BookingPromotions_Discount  CHECK (discount_applied >= 0)
);
GO

-- ============================================================
-- NHOM TICKET
-- ============================================================

-- ------------------------------------------------------------
-- 22. Tickets
-- ------------------------------------------------------------
CREATE TABLE Tickets (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    booking_seat_id UNIQUEIDENTIFIER NOT NULL,
    ticket_code     NVARCHAR(100)     NOT NULL,
    qr_code         NVARCHAR(MAX)    NULL,
    is_printed      BIT              NOT NULL DEFAULT 0,
    issued_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Tickets              PRIMARY KEY (id),
    CONSTRAINT FK_Tickets_BookingSeat  FOREIGN KEY (booking_seat_id) REFERENCES BookingSeats(id),
    CONSTRAINT UK_Tickets_BookingSeat  UNIQUE (booking_seat_id),
    CONSTRAINT UK_Tickets_Code         UNIQUE (ticket_code)
);
GO

-- ============================================================
-- NHOM LOYALTY
-- ============================================================

-- ------------------------------------------------------------
-- 23. LoyaltyPointsLog
-- ------------------------------------------------------------
CREATE TABLE LoyaltyPointsLog (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id          UNIQUEIDENTIFIER NOT NULL,
    booking_id       UNIQUEIDENTIFIER NULL,
    points_delta     INT              NOT NULL,
    transaction_type NVARCHAR(20)      NOT NULL,
    note             NVARCHAR(255)    NULL,
    created_at       DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_LoyaltyPointsLog       PRIMARY KEY (id),
    CONSTRAINT FK_LoyaltyPointsLog_User    FOREIGN KEY (user_id)    REFERENCES Users(id),
    CONSTRAINT FK_LoyaltyPointsLog_Booking FOREIGN KEY (booking_id) REFERENCES Bookings(id),
    CONSTRAINT CK_LoyaltyPointsLog_Type    CHECK (transaction_type IN ('EARN','REDEEM','REFUND_POINTS','ADJUST')),
    CONSTRAINT CK_LoyaltyPointsLog_Earn    CHECK (transaction_type NOT IN ('EARN','REFUND_POINTS') OR points_delta > 0),
    CONSTRAINT CK_LoyaltyPointsLog_Redeem  CHECK (transaction_type <> 'REDEEM' OR points_delta < 0)
);
GO

-- ============================================================
-- NHOM INCIDENT
-- ============================================================

-- ------------------------------------------------------------
-- 24. ShowtimeIncidents
-- ------------------------------------------------------------
CREATE TABLE ShowtimeIncidents (
    id                           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    showtime_id                  UNIQUEIDENTIFIER NOT NULL,
    description                  NVARCHAR(MAX)    NOT NULL,
    refund_points_rate           DECIMAL(3,2)     NOT NULL DEFAULT 1.00,
    compensation_discount_type   NVARCHAR(20)      NOT NULL,
    compensation_discount_value  DECIMAL(12,2)    NOT NULL,
    compensation_valid_days      INT              NOT NULL DEFAULT 30,
    processed_at                 DATETIME2        NULL,
    created_by                   UNIQUEIDENTIFIER NOT NULL,
    created_at                   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_ShowtimeIncidents        PRIMARY KEY (id),
    CONSTRAINT FK_ShowtimeIncidents_Showtime FOREIGN KEY (showtime_id) REFERENCES Showtimes(id),
    CONSTRAINT FK_ShowtimeIncidents_Created  FOREIGN KEY (created_by)  REFERENCES Users(id),
    CONSTRAINT UK_ShowtimeIncidents_Showtime UNIQUE (showtime_id),
    CONSTRAINT CK_ShowtimeIncidents_DiscType CHECK  (compensation_discount_type IN ('PERCENTAGE','FIXED_AMOUNT')),
    CONSTRAINT CK_ShowtimeIncidents_Refund   CHECK  (refund_points_rate BETWEEN 0.00 AND 1.00),
    CONSTRAINT CK_ShowtimeIncidents_ValDays  CHECK  (compensation_valid_days > 0),
    CONSTRAINT CK_ShowtimeIncidents_Value    CHECK  (compensation_discount_value > 0)
);
GO

-- ============================================================
-- NHOM CHATBOT
-- ============================================================

-- ------------------------------------------------------------
-- 25. ChatbotConversations
-- ------------------------------------------------------------
CREATE TABLE ChatbotConversations (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    user_id    UNIQUEIDENTIFIER NOT NULL,
    session_id NVARCHAR(255)     NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_ChatbotConversations PRIMARY KEY (id),
    CONSTRAINT FK_ChatbotConversations_User FOREIGN KEY (user_id) REFERENCES Users(id)
);
GO

-- ------------------------------------------------------------
-- 26. ChatbotMessages
-- ------------------------------------------------------------
CREATE TABLE ChatbotMessages (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    conversation_id UNIQUEIDENTIFIER NOT NULL,
    sender_type     NVARCHAR(5)       NOT NULL,
    message_content NVARCHAR(MAX)    NOT NULL,
    created_at      DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_ChatbotMessages           PRIMARY KEY (id),
    CONSTRAINT FK_ChatbotMessages_Conv    FOREIGN KEY (conversation_id) REFERENCES ChatbotConversations(id),
    CONSTRAINT CK_ChatbotMessages_Sender    CHECK (sender_type IN ('USER','BOT'))
);
GO

-- ============================================================
-- INDEXES PERFORMANCE
-- ============================================================

CREATE INDEX IX_Movies_Status       ON Movies(status);
CREATE INDEX IX_Movies_Release      ON Movies(release_date);

CREATE INDEX IX_Showtimes_MovieRoom ON Showtimes(movie_id, room_id);
CREATE INDEX IX_Showtimes_StartTime ON Showtimes(start_time);
CREATE INDEX IX_Showtimes_Status    ON Showtimes(status);

CREATE INDEX IX_Seats_Room          ON Seats(room_id);
CREATE INDEX IX_Seats_Status        ON Seats(room_id, status);

CREATE INDEX IX_SeatHolds_Expired   ON SeatHolds(expired_at);
CREATE INDEX IX_SeatHolds_ShowSeat  ON SeatHolds(showtime_id, seat_id);

CREATE INDEX IX_Bookings_User       ON Bookings(user_id);
CREATE INDEX IX_Bookings_Showtime   ON Bookings(showtime_id);
CREATE INDEX IX_Bookings_Status     ON Bookings(booking_status, payment_status);
CREATE INDEX IX_Bookings_BookedAt   ON Bookings(booked_at);
CREATE INDEX IX_Bookings_Source     ON Bookings(booking_source);
CREATE INDEX IX_Bookings_Expired    ON Bookings(expired_at) WHERE expired_at IS NOT NULL;

CREATE INDEX IX_BookingSeats_Booking ON BookingSeats(booking_id);
CREATE INDEX IX_BookingSeats_Seat    ON BookingSeats(seat_id);

CREATE INDEX IX_Payments_Booking    ON Payments(booking_id);
CREATE INDEX IX_Payments_PaidAt     ON Payments(paid_at);
CREATE INDEX IX_Payments_Status     ON Payments(payment_status);

CREATE INDEX IX_Promotions_Status   ON Promotions(status);
CREATE INDEX IX_Promotions_Dates    ON Promotions(start_date, end_date);

CREATE INDEX IX_MovieReviews_Movie  ON MovieReviews(movie_id);

CREATE INDEX IX_SystemConfigLog_UpdatedAt ON SystemConfigLog(updated_at DESC);

CREATE INDEX IX_UserStatusLog_User ON UserStatusLog(user_id, performed_at DESC);

CREATE INDEX IX_LoyaltyPointsLog_User ON LoyaltyPointsLog(user_id, created_at);
CREATE INDEX IX_LoyaltyPointsLog_Booking ON LoyaltyPointsLog(booking_id);

CREATE INDEX IX_ChatbotConversations_User ON ChatbotConversations(user_id);
CREATE INDEX IX_ChatbotMessages_Conv      ON ChatbotMessages(conversation_id, created_at);
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

INSERT INTO SeatTypes (id, type_name, price_multiplier, description) VALUES
    (NEWID(), 'REGULAR',  1.00, N'Ghế thường'),
    (NEWID(), 'VIP',      1.50, N'Ghế VIP - rộng hơn, vị trí trung tâm'),
    (NEWID(), 'COUPLE',   2.00, N'Ghế đôi dành cho 2 người'),
    (NEWID(), 'SWEETBOX', 2.50, N'Ghế sweetbox - riêng tư, có bàn nhỏ');
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
INSERT INTO Genres (id, genre_name) VALUES
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB101', N'Hành động'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB102', N'Viễn tưởng'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB103', N'Kinh dị'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB104', N'Tình cảm'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB105', N'Hoạt hình'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB106', N'Hài'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB107', N'Chính kịch'),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBB108', N'Kịch tính');
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
    ('55555555-5555-5555-5555-555555555501', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', @StatsRoom1, '2026-06-05 18:00:00', '2026-06-05 20:30:00', 100000, 'OPEN',     @StatsManagerId),
    ('55555555-5555-5555-5555-555555555502', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA101', @StatsRoom1, '2026-06-08 20:00:00', '2026-06-08 22:30:00', 100000, 'OPEN',     @StatsManagerId),
    ('55555555-5555-5555-5555-555555555503', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA102', @StatsRoom2, '2026-06-07 19:00:00', '2026-06-07 21:43:00', 120000, 'OPEN',     @StatsManagerId),
    ('55555555-5555-5555-5555-555555555504', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA103', @StatsRoom3, '2026-05-28 14:00:00', '2026-05-28 15:48:00',  80000,  'FINISHED', @StatsManagerId),
    ('55555555-5555-5555-5555-555555555505', 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAA104', @StatsRoom1, '2026-06-03 21:00:00', '2026-06-03 22:58:00', 100000, 'OPEN',     @StatsManagerId),
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

PRINT N'=== Hoan tat: 28 bang + day du seed data ===';
PRINT N'=== Tai khoan seed: mat khau mac dinh Password@123 (BCrypt) ===';
PRINT N'=== Phim mau: 4 dang chieu + 4 sap chieu ===';
PRINT N'=== Thong ke test: 6 don PAID + 1 PENDING (SEED-STATS-*) ===';
GO
