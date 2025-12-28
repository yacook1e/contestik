USE BD_lab

--логины
CREATE LOGIN User_yacook1e WITH PASSWORD = '1234567';
CREATE LOGIN User1_yacook1e WITH PASSWORD = '1234567';
--юзеры
CREATE USER User_yacook1e FOR LOGIN User_yacook1e
CREATE USER User1_yacook1e FOR LOGIN User1_yacook1e;


--роли
CREATE ROLE Role_Admin;
CREATE ROLE Role_Employee;


--разрешения админа
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO Role_Admin;


--разрешения/денаи сотрудника
GRANT SELECT ON Doctor TO Role_Employee;
GRANT SELECT ON District TO Role_Employee;
GRANT SELECT ON Schedule TO Role_Employee;
GRANT SELECT ON Patient TO Role_Employee;
GRANT SELECT ON Reception TO Role_Employee;
GRANT SELECT ON Stattalon TO Role_Employee;
DENY UPDATE, DELETE ON Reception TO Role_Employee;
DENY UPDATE, DELETE ON Stattalon TO Role_Employee;
DENY UPDATE, DELETE ON Patient TO Role_Employee;
DENY UPDATE, DELETE ON Doctor TO Role_Employee;


--назначение ролей юзерам
ALTER ROLE Role_Admin ADD MEMBER User_yacook1e;
ALTER ROLE Role_Employee ADD MEMBER User1_yacook1e;
GRANT CONNECT TO User_yacook1e;
GRANT CONNECT TO User1_yacook1e;


--маскирование
ALTER TABLE Doctor ALTER COLUMN full_name ADD MASKED WITH (FUNCTION = 'partial(2,"xxxx",0)');
ALTER TABLE Patient ALTER COLUMN full_name ADD MASKED WITH (FUNCTION = 'partial(2,"xxxx",0)');

ALTER TABLE Doctor ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'default()');
ALTER TABLE Patient ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'default()');

GRANT UNMASK TO User_yacook1e;


--тесты
SELECT 'Просмотр Doctor' AS Test;
SELECT id, office_number, full_name, phone, speciality FROM Doctor WHERE id = 1;

-- Попытка вставить данные
INSERT INTO Doctor (office_number, full_name, phone, speciality) 
VALUES (111, N'Новый Админ', '+79999999999', N'Терапевт');
SELECT 'Вставка в Doctor' AS Test;
DECLARE @NewId INT = SCOPE_IDENTITY();
SELECT id, office_number, full_name, phone, speciality FROM Doctor WHERE id = @@IDENTITY;

-- Удаление
DELETE FROM Doctor WHERE id = @@IDENTITY;
SELECT 'Удаление из Doctor' AS Test;
