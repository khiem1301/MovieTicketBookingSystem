-- Migration: thêm bảng UserStatusLog (lý do khóa tài khoản + audit)
-- Chạy trên DB đã có nếu không muốn reset create_database.sql

USE MovieTicketDB;
GO

IF OBJECT_ID('UserStatusLog', 'U') IS NOT NULL
BEGIN
    PRINT N'UserStatusLog đã tồn tại — bỏ qua.';
    RETURN;
END
GO

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

CREATE INDEX IX_UserStatusLog_User ON UserStatusLog(user_id, performed_at DESC);
GO

PRINT N'Đã tạo bảng UserStatusLog.';
GO
