-- FR-04 — Phân loại token: đăng ký / quên MK / xác minh profile
-- Chạy trên DB đã có PasswordResetTokens (không reset toàn bộ DB).

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.PasswordResetTokens') AND name = N'purpose'
)
BEGIN
    ALTER TABLE PasswordResetTokens
        ADD purpose NVARCHAR(30) NOT NULL
            CONSTRAINT DF_PasswordResetTokens_Purpose DEFAULT 'REGISTER_VERIFY';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_PasswordResetTokens_Purpose'
)
BEGIN
    ALTER TABLE PasswordResetTokens
        ADD CONSTRAINT CK_PasswordResetTokens_Purpose
            CHECK (purpose IN ('REGISTER_VERIFY', 'PASSWORD_RESET', 'PROFILE_SECURITY'));
END
GO
