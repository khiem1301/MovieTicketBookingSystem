-- Migration: thêm bảng lịch sử chỉnh sửa cấu hình loyalty (SystemConfigLog)
-- Chạy trên DB MovieTicketDB đã tồn tại (không cần chạy lại create_database.sql)

USE MovieTicketDB;
GO

IF OBJECT_ID('SystemConfigLog', 'U') IS NULL
BEGIN
    CREATE TABLE SystemConfigLog (
        id                           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        earn_rate                    NVARCHAR(20)     NOT NULL,
        redeem_rate                  NVARCHAR(20)     NOT NULL,
        min_redeem                   NVARCHAR(20)     NOT NULL,
        max_redeem_per_order         NVARCHAR(20)     NOT NULL,
        previous_earn_rate           NVARCHAR(20)     NULL,
        previous_redeem_rate         NVARCHAR(20)     NULL,
        previous_min_redeem          NVARCHAR(20)     NULL,
        previous_max_redeem_per_order NVARCHAR(20)    NULL,
        updated_by                   UNIQUEIDENTIFIER NULL,
        updated_at                   DATETIME2        NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_SystemConfigLog      PRIMARY KEY (id),
        CONSTRAINT FK_SystemConfigLog_User FOREIGN KEY (updated_by) REFERENCES Users(id)
    );

    CREATE INDEX IX_SystemConfigLog_UpdatedAt ON SystemConfigLog(updated_at DESC);
END
GO
