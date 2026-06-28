-- Thêm cột seat_span (1 ô / 2 ô liền nhau) cho loại ghế
-- Lưu ý: SQL Server biên dịch cả batch trước khi chạy — phải tách ADD cột / CHECK / UPDATE bằng GO

USE MovieTicketDB;
GO

IF COL_LENGTH('SeatTypes', 'seat_span') IS NULL
BEGIN
    ALTER TABLE SeatTypes
        ADD seat_span INT NOT NULL CONSTRAINT DF_SeatTypes_SeatSpan DEFAULT 1;
END
GO

IF COL_LENGTH('SeatTypes', 'seat_span') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.check_constraints
       WHERE name = N'CK_SeatTypes_SeatSpan'
         AND parent_object_id = OBJECT_ID(N'dbo.SeatTypes')
   )
BEGIN
    ALTER TABLE SeatTypes
        ADD CONSTRAINT CK_SeatTypes_SeatSpan CHECK (seat_span IN (1, 2));
END
GO

IF COL_LENGTH('SeatTypes', 'seat_span') IS NOT NULL
BEGIN
    UPDATE SeatTypes
    SET seat_span = 2
    WHERE type_name IN (N'COUPLE', N'SWEETBOX');
END
GO
