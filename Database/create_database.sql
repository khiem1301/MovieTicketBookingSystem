-- ============================================================
-- Movie Ticket Booking System
-- SQL Server Script
-- 26 Tables | Version Final
-- ============================================================
-- Luu y:
--   - UUID     -> UNIQUEIDENTIFIER + DEFAULT NEWID()
--   - ENUM     -> VARCHAR + CHECK constraint
--   - BOOLEAN  -> BIT
--   - TEXT     -> NVARCHAR(MAX)
--   - TIMESTAMP-> DATETIME2
--   - NOW()    -> GETDATE()
--   - Ten bang -> PascalCase (vd: Users, BookingSeats)
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
    role_name   VARCHAR(50)      NOT NULL,
    description VARCHAR(255)     NULL,
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
    email          VARCHAR(255)     NULL,
    username       VARCHAR(100)     NULL,
    phone_number   VARCHAR(20)      NULL,
    password_hash  VARCHAR(255)     NOT NULL,
    full_name      NVARCHAR(255)    NOT NULL,
    date_of_birth  DATE             NOT NULL,
    avatar_url     NVARCHAR(MAX)    NULL,
    status         VARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
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
    token      VARCHAR(255)     NOT NULL,
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
    config_key   VARCHAR(100)     NOT NULL,
    config_value VARCHAR(500)     NOT NULL,
    description  NVARCHAR(255)    NULL,
    updated_by   UNIQUEIDENTIFIER NULL,
    updated_at   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_SystemConfig         PRIMARY KEY (config_key),
    CONSTRAINT FK_SystemConfig_Updated FOREIGN KEY (updated_by) REFERENCES Users(id)
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
    status     VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',
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
    hotline       VARCHAR(20)      NULL,
    email         VARCHAR(255)     NULL,
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
    status     VARCHAR(20)      NOT NULL DEFAULT 'ACTIVE',
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
    type_name        VARCHAR(50)      NOT NULL,
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
    seat_row     VARCHAR(10)      NOT NULL,
    seat_column  INT              NOT NULL,
    seat_code    VARCHAR(20)      NOT NULL,
    status       VARCHAR(10)      NOT NULL DEFAULT 'ACTIVE',

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

    CONSTRAINT PK_Movies          PRIMARY KEY (id),
    CONSTRAINT UK_Movies_Slug     UNIQUE (slug),
    CONSTRAINT CK_Movies_Duration CHECK  (duration_minutes > 0),
    CONSTRAINT CK_Movies_Status   CHECK  (status IN ('COMING_SOON','NOW_SHOWING','ENDED')),
    CONSTRAINT CK_Movies_Age      CHECK  (age_rating IN ('P','K','T13','T16','T18','C') OR age_rating IS NULL),
    CONSTRAINT CK_Movies_Rating   CHECK  (average_rating BETWEEN 0.00 AND 5.00 OR average_rating IS NULL)
);
GO

-- ------------------------------------------------------------
-- 11. Genres
-- ------------------------------------------------------------
CREATE TABLE Genres (
    id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    genre_name NVARCHAR(100)    NOT NULL,
    created_at DATETIME2        NOT NULL DEFAULT GETDATE(),

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
    status     VARCHAR(20)      NOT NULL DEFAULT 'SCHEDULED',
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
    booking_code         VARCHAR(50)      NOT NULL,
    user_id              UNIQUEIDENTIFIER NULL,
    showtime_id          UNIQUEIDENTIFIER NOT NULL,
    booking_source       VARCHAR(10)      NOT NULL,
    created_by_staff_id  UNIQUEIDENTIFIER NULL,
    customer_name        NVARCHAR(255)    NULL,
    customer_phone       VARCHAR(20)      NULL,
    vat_rate_snapshot    DECIMAL(5,2)     NOT NULL,
    total_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    discount_amount      DECIMAL(12,2)    NOT NULL DEFAULT 0,
    final_amount         DECIMAL(12,2)    NOT NULL DEFAULT 0,
    booking_status       VARCHAR(20)      NOT NULL DEFAULT 'PENDING',
    payment_status       VARCHAR(10)      NOT NULL DEFAULT 'UNPAID',
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
    payment_method   VARCHAR(20)      NOT NULL,
    payment_source   VARCHAR(10)      NOT NULL,
    transaction_code VARCHAR(255)     NULL,
    amount           DECIMAL(12,2)    NOT NULL,
    cash_received    DECIMAL(12,2)    NULL,
    change_amount    DECIMAL(12,2)    NULL,
    payment_status   VARCHAR(10)      NOT NULL DEFAULT 'PENDING',
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
    ticket_code     VARCHAR(100)     NOT NULL,
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
    transaction_type VARCHAR(20)      NOT NULL,
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
    compensation_discount_type   VARCHAR(20)      NOT NULL,
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
    session_id VARCHAR(255)     NOT NULL,
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
    sender_type     VARCHAR(5)       NOT NULL,
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

-- BCrypt hash cua mat khau: Password@123
DECLARE @DefaultPasswordHash VARCHAR(255) = '$2b$10$cQtXPt5hVH2nDDhuXFDxQ.aKttyB7S7/6jR.xyULrEfcnUFA8UCM6';

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

PRINT N'=== Tao database thanh cong: 26 bang (PascalCase), indexes, seed data ===';
PRINT N'=== Tai khoan seed: mat khau mac dinh la Password@123 (BCrypt) ===';
GO
