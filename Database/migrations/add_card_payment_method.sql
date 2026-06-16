-- Migration: Allow CARD payment method for offline counter POS
-- Run after create_database.sql
USE MovieTicketDB;
GO

ALTER TABLE Payments DROP CONSTRAINT CK_Payments_Method;
GO

ALTER TABLE Payments ADD CONSTRAINT CK_Payments_Method
    CHECK (payment_method IN ('VNPAY', 'MOMO', 'CASH', 'CARD'));
GO
