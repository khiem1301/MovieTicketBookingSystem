-- ============================================================
-- PendingRegistrations — đăng ký chờ xác thực email (FR-01)
-- Chạy trên DB đã có data (không muốn chạy lại create_database.sql).
-- Idempotent.
-- ============================================================

USE MovieTicketDB;
GO

IF OBJECT_ID(N'dbo.PendingRegistrations', N'U') IS NULL
BEGIN
    CREATE TABLE PendingRegistrations (
        id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        email          NVARCHAR(255)     NOT NULL,
        phone_number   NVARCHAR(20)      NOT NULL,
        password_hash  NVARCHAR(255)     NOT NULL,
        full_name      NVARCHAR(255)     NOT NULL,
        date_of_birth  DATE              NOT NULL,
        token          NVARCHAR(255)     NOT NULL,
        expired_at     DATETIME2         NOT NULL,
        used_at        DATETIME2         NULL,
        created_at     DATETIME2         NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_PendingRegistrations        PRIMARY KEY (id),
        CONSTRAINT UK_PendingRegistrations_Token  UNIQUE (token),
        CONSTRAINT UK_PendingRegistrations_Email  UNIQUE (email)
    );
END
GO

-- Dọn tài khoản INACTIVE do luồng đăng ký cũ (chưa từng login + còn token REGISTER_VERIFY)
IF OBJECT_ID(N'dbo.PasswordResetTokens', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'tempdb..#StuckSignup') IS NOT NULL DROP TABLE #StuckSignup;

    SELECT DISTINCT t.user_id
    INTO #StuckSignup
    FROM PasswordResetTokens t
    INNER JOIN Users u ON u.id = t.user_id
    INNER JOIN Roles r ON r.id = u.role_id AND r.role_name = N'CUSTOMER'
    WHERE t.purpose = N'REGISTER_VERIFY'
      AND u.status = N'INACTIVE'
      AND u.last_login_at IS NULL;

    DELETE t
    FROM PasswordResetTokens t
    INNER JOIN #StuckSignup s ON s.user_id = t.user_id;

    DELETE u
    FROM Users u
    INNER JOIN #StuckSignup s ON s.user_id = u.id;

    DROP TABLE #StuckSignup;
END
GO
