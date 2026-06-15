-- Thêm VIETQR vào CHECK constraint Payments (chạy trên DB đã tạo trước đó)
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Payments_Method')
BEGIN
    ALTER TABLE Payments DROP CONSTRAINT CK_Payments_Method;
END
GO
ALTER TABLE Payments ADD CONSTRAINT CK_Payments_Method
    CHECK (payment_method IN ('VNPAY','MOMO','CASH','VIETQR'));
GO
