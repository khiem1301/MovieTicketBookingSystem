-- Migration: thêm bảng ReviewDeletionLog (lịch sử manager xóa đánh giá vi phạm)
-- Dùng để chặn 1 user bị xóa đánh giá >= 10 lần trên CÙNG 1 phim khỏi đánh giá lại phim đó.
-- Chạy trên DB đã có nếu không muốn reset create_database.sql

USE MovieTicketDB;
GO

IF OBJECT_ID('ReviewDeletionLog', 'U') IS NOT NULL
BEGIN
    PRINT N'ReviewDeletionLog đã tồn tại — bỏ qua.';
    RETURN;
END
GO

CREATE TABLE ReviewDeletionLog (
    id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    movie_id     UNIQUEIDENTIFIER NOT NULL,
    user_id      UNIQUEIDENTIFIER NOT NULL,
    reason       NVARCHAR(500)    NOT NULL,
    deleted_by   UNIQUEIDENTIFIER NULL,
    deleted_at   DATETIME2        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_ReviewDeletionLog          PRIMARY KEY (id),
    CONSTRAINT FK_ReviewDeletionLog_Movie     FOREIGN KEY (movie_id)   REFERENCES Movies(id),
    CONSTRAINT FK_ReviewDeletionLog_User      FOREIGN KEY (user_id)    REFERENCES Users(id),
    CONSTRAINT FK_ReviewDeletionLog_DeletedBy FOREIGN KEY (deleted_by) REFERENCES Users(id)
);
GO

CREATE INDEX IX_ReviewDeletionLog_UserMovie ON ReviewDeletionLog(user_id, movie_id);
GO

PRINT N'Đã tạo bảng ReviewDeletionLog.';
GO
