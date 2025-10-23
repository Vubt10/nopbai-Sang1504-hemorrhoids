USE QLDA
GO

-- Xóa trigger nếu đã tồn tại
IF OBJECT_ID('trg_InsertNhanVien', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsertNhanVien
GO

CREATE TRIGGER trg_InsertNhanVien
ON NHANVIEN
FOR INSERT
AS
BEGIN
    DECLARE @Luong FLOAT, @NgSinh DATE, @Tuoi INT
    SELECT @Luong = LUONG, @NgSinh = NGSINH FROM INSERTED
    SET @Tuoi = YEAR(GETDATE()) - YEAR(@NgSinh)

    IF (@Luong <= 15000)
    BEGIN
        RAISERROR(N'Lương phải >15000', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    IF (@Tuoi < 18 OR @Tuoi > 65)
    BEGIN
        RAISERROR(N'Tuổi nhân viên phải trong khoảng 18 đến 65', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO
-- 1. Nhân viên hợp lệ ✅
INSERT INTO NHANVIEN VALUES
(N'Ngô', N'Lê', N'Anh', 'NV100', '1995-03-02', N'12 Nguyễn Trãi, Hà Nội', N'Nam', 20000, NULL, NULL)

-- 2. Nhân viên lương thấp ❌
INSERT INTO NHANVIEN VALUES
(N'Trần', N'Thị', N'Hoa', 'NV101', '1990-02-10', N'123 Lê Lợi, Đà Nẵng', N'Nữ', 10000, NULL, NULL)

-- 3. Nhân viên chưa đủ tuổi ❌
INSERT INTO NHANVIEN VALUES
(N'Nguyễn', N'Văn', N'Bé', 'NV102', '2010-06-12', N'456 Pasteur, TP HCM', N'Nam', 20000, NULL, NULL)
IF OBJECT_ID('trg_UpdateNhanVien', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateNhanVien
GO

CREATE TRIGGER trg_UpdateNhanVien
ON NHANVIEN
FOR UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM DELETED WHERE DCHI LIKE N'%TP HCM%' OR DCHI LIKE N'%TP.HCM%')
    BEGIN
        RAISERROR(N'Không được cập nhật nhân viên ở TP HCM', 16, 1)
        ROLLBACK TRANSACTION
    END
END
GO
-- Nhân viên ở nơi khác → cho phép
UPDATE NHANVIEN SET LUONG = LUONG + 1000 WHERE MANV = 'NV100'

-- Nhân viên ở TP HCM → báo lỗi
UPDATE NHANVIEN SET LUONG = LUONG + 1000 WHERE DCHI LIKE N'%TP HCM%'
---------------
IF OBJECT_ID('trg_AfterInsertNhanVien', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterInsertNhanVien
GO

CREATE TRIGGER trg_AfterInsertNhanVien
ON NHANVIEN
AFTER INSERT
AS
BEGIN
    DECLARE @Nam INT, @Nu INT
    SELECT @Nam = COUNT(*) FROM NHANVIEN WHERE PHAI = N'Nam'
    SELECT @Nu = COUNT(*) FROM NHANVIEN WHERE PHAI = N'Nữ'

    PRINT N'Tổng nhân viên Nam: ' + CAST(@Nam AS NVARCHAR)
    PRINT N'Tổng nhân viên Nữ: ' + CAST(@Nu AS NVARCHAR)
END
GO
INSERT INTO NHANVIEN VALUES
(N'Lê', N'Thị', N'Hoa', 'NV200', '1998-06-12', N'Đà Nẵng', N'Nữ', 22000, NULL, NULL)





IF OBJECT_ID('trg_AfterUpdateGender', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterUpdateGender
GO

CREATE TRIGGER trg_AfterUpdateGender
ON NHANVIEN
AFTER UPDATE
AS
BEGIN
    IF UPDATE(PHAI)
    BEGIN
        DECLARE @Nam INT, @Nu INT
        SELECT @Nam = COUNT(*) FROM NHANVIEN WHERE PHAI = N'Nam'
        SELECT @Nu = COUNT(*) FROM NHANVIEN WHERE PHAI = N'Nữ'

        PRINT N'Sau cập nhật giới tính:'
        PRINT N'Tổng nhân viên Nam: ' + CAST(@Nam AS NVARCHAR)
        PRINT N'Tổng nhân viên Nữ: ' + CAST(@Nu AS NVARCHAR)
    END
END
GO
UPDATE NHANVIEN SET PHAI = N'Nam' WHERE MANV = 'NV200'
IF OBJECT_ID('trg_AfterDeleteDean', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterDeleteDean
GO

CREATE TRIGGER trg_AfterDeleteDean
ON DEAN
AFTER DELETE
AS
BEGIN
    PRINT N'Tổng số đề án mà mỗi nhân viên đã làm:'
    SELECT MA_NVIEN, COUNT(*) AS SoLuongDeAn
    FROM PHANCONG
    GROUP BY MA_NVIEN
END
GO
DELETE FROM DEAN WHERE MADA = 1
-------------
IF OBJECT_ID('trg_InsteadOfDeleteNhanVien', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsteadOfDeleteNhanVien
GO

CREATE TRIGGER trg_InsteadOfDeleteNhanVien
ON NHANVIEN
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM THANNHAN WHERE MA_NVIEN IN (SELECT MANV FROM DELETED)
    DELETE FROM NHANVIEN WHERE MANV IN (SELECT MANV FROM DELETED)
    PRINT N'Đã xóa nhân viên và các thân nhân liên quan.'
END
GO
DELETE FROM NHANVIEN WHERE MANV = 'NV200'
IF OBJECT_ID('trg_InsteadOfInsertNhanVien', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsteadOfInsertNhanVien
GO

CREATE TRIGGER trg_InsteadOfInsertNhanVien
ON NHANVIEN
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO NHANVIEN (HONV, TENLOT, TENNV, MANV, NGSINH, DCHI, PHAI, LUONG, MA_NQL, PHG)
    SELECT HONV, TENLOT, TENNV, MANV, NGSINH, DCHI, PHAI, LUONG, MA_NQL, PHG FROM INSERTED

    INSERT INTO PHANCONG(MA_NVIEN, MADA, THOIGIAN)
    SELECT MANV, 1, 10 FROM INSERTED

    PRINT N'Nhân viên mới đã được phân công vào đề án MADA = 1.'
END
GO
INSERT INTO NHANVIEN VALUES
(N'Lê', N'Hữu', N'Phát', 'NV300', '1999-07-10', N'Hà Nội', N'Nam', 25000, NULL, NULL)

SELECT * FROM PHANCONG WHERE MA_NVIEN = 'NV300'

