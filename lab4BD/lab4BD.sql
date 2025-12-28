-- a) Процедура без параметров, возвращающая расписание работы врачей на текущую дату
CREATE OR ALTER PROCEDURE GetTodaySchedule
AS
BEGIN
    DECLARE @today_day NVARCHAR(20)
    SET @today_day = DATENAME(WEEKDAY, GETDATE())
    
    SELECT 
        d.Full_name AS Врач,
        d.Office_number AS Кабинет,
        s.Start_time AS [Время начала],
        COUNT(r.id) AS [Количество пациентов]
    FROM Schedule s
    INNER JOIN Doctor d ON s.Doctor_Id = d.id
    LEFT JOIN Reception r ON s.Doctor_Id = r.Doctor_Id 
        AND CAST(r.Reception_time AS DATE) = CAST(GETDATE() AS DATE)
    WHERE s.Day_of_the_week = @today_day
    GROUP BY d.Full_name, d.Office_number, s.Start_time
    ORDER BY s.Start_time;
END;
GO

EXEC GetTodaySchedule;

GO

-- b) Процедура, на входе получающая номер участка и формирующая список улиц
CREATE OR ALTER PROCEDURE GetStreetsByDistrict
    @district_number INT
AS
BEGIN
    SELECT name AS Улица
    FROM Street
    WHERE district_id = @district_number
    ORDER BY name;
END;
GO

EXEC GetStreetsByDistrict @district_number = 1;

GO

-- c) Процедура, получающая номер участка, возвращающая ФИО врача
CREATE OR ALTER PROCEDURE GetDoctorByDistrict
    @district_number INT,
    @doctor_name NVARCHAR(100) OUTPUT
AS
BEGIN
    SELECT @doctor_name = d.Full_name
    FROM District dist
    INNER JOIN Doctor d ON dist.Doctor_Id = d.id
    WHERE dist.Number = @district_number;
END;
GO

DECLARE @doctor_name NVARCHAR(100);
EXEC GetDoctorByDistrict @district_number = 1, @doctor_name = @doctor_name OUTPUT;
SELECT @doctor_name AS Врач;

GO

-- d) Процедура, находящая участок с максимальным количеством домов и возвращающая ФИО врача
CREATE OR ALTER PROCEDURE GetDoctorFromMaxHousesDistrict
AS
BEGIN
    DECLARE @max_district_id INT;
    DECLARE @doctor_name NVARCHAR(100);
    
    SELECT TOP 1 @max_district_id = s.district_id
    FROM House h
    INNER JOIN Street s ON h.street_id = s.id
    GROUP BY s.district_id
    ORDER BY COUNT(h.id) DESC;
    
    EXEC GetDoctorByDistrict @max_district_id, @doctor_name OUTPUT;
    
    SELECT @doctor_name AS [Врач участка], @max_district_id AS [Номер участка];
END;
GO

EXEC GetDoctorFromMaxHousesDistrict;

GO

-- a) Скалярная функция, возвращающая по адресу номер участка
CREATE OR ALTER FUNCTION GetDistrictByAddress
(
    @street_name NVARCHAR(100),
    @house_number NVARCHAR(20)
)
RETURNS INT
AS
BEGIN
    DECLARE @district_id INT;
    
    SELECT @district_id = s.district_id
    FROM House h
    INNER JOIN Street s ON h.street_id = s.id
    WHERE s.name = @street_name AND h.number = @house_number;
    
    RETURN ISNULL(@district_id, 0);
END;
GO

SELECT dbo.GetDistrictByAddress(N'Ленина', '10') AS [Номер участка];

GO

-- b) Inline-функция, возвращающая все посещения заданного пациента за текущий год
CREATE OR ALTER FUNCTION GetPatientVisitsCurrentYear
(
    @patient_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        r.Reception_time AS [Дата и время],
        d.Full_name AS Врач,
        r.Diagnosis AS Диагноз
    FROM Reception r
    INNER JOIN Doctor d ON r.Doctor_Id = d.id
    WHERE r.Patient_ID = @patient_id 
        AND YEAR(r.Reception_time) = YEAR(GETDATE())
);
GO

SELECT * FROM dbo.GetPatientVisitsCurrentYear(1);

GO

-- c) Multi-statement-функция, возвращающая список свободных явок на текущую неделю
CREATE OR ALTER FUNCTION GetAvailableAppointments
(
    @doctor_id INT
)
RETURNS @appointments TABLE
(
    Day_of_week NVARCHAR(20),
    Appointment_time TIME
)
AS
BEGIN
    DECLARE @current_date DATE = GETDATE();
    DECLARE @week_start DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @current_date), @current_date);
    DECLARE @week_end DATE = DATEADD(DAY, 7, @week_start);
    
    DECLARE @day_name NVARCHAR(20);
    DECLARE @start_time TIME;
    DECLARE @duration INT;
    DECLARE @appointment_time TIME;
    
    DECLARE schedule_cursor CURSOR FOR
    SELECT Day_of_the_week, Start_time, Duration
    FROM Schedule
    WHERE Doctor_Id = @doctor_id;
    
    OPEN schedule_cursor;
    FETCH NEXT FROM schedule_cursor INTO @day_name, @start_time, @duration;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @appointment_time = @start_time;
        
        WHILE DATEDIFF(MINUTE, @start_time, @appointment_time) < @duration
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM Reception 
                WHERE Doctor_Id = @doctor_id 
                AND CAST(Reception_time AS DATE) BETWEEN @week_start AND @week_end
                AND CAST(Reception_time AS TIME) = @appointment_time
            )
            BEGIN
                INSERT INTO @appointments (Day_of_week, Appointment_time)
                VALUES (@day_name, @appointment_time);
            END
            
            SET @appointment_time = DATEADD(MINUTE, 15, @appointment_time);
        END
        
        FETCH NEXT FROM schedule_cursor INTO @day_name, @start_time, @duration;
    END
    
    CLOSE schedule_cursor;
    DEALLOCATE schedule_cursor;
    
    RETURN;
END;
GO

SELECT * FROM dbo.GetAvailableAppointments(1);

GO

-- a) Триггер на добавление нового врача
CREATE OR ALTER TRIGGER trg_CheckTherapistDistrict
ON Doctor
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.Speciality = N'Терапевт' 
        AND NOT EXISTS (
            SELECT 1 FROM District d 
            WHERE d.Doctor_Id = i.id
        )
    )
    BEGIN
        RAISERROR('Для терапевта должен быть указан номер участка в таблице District!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Тест триггера
BEGIN TRY
    INSERT INTO Doctor (Office_number, Full_name, Phone, Speciality) 
    VALUES (111, N'Тестовый Терапевт', N'+79111111112', N'Терапевт');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH

GO

-- b) Триггер на изменение номера кабинета у врача
CREATE OR ALTER TRIGGER trg_CheckOfficeConflict
ON Doctor
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Office_number)
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN Doctor d ON i.Office_number = d.Office_number 
                AND i.id <> d.id
            WHERE EXISTS (
                SELECT 1 FROM Schedule s1
                INNER JOIN Schedule s2 ON s1.Day_of_the_week = s2.Day_of_the_week
                WHERE s1.Doctor_Id = i.id AND s2.Doctor_Id = d.id
            )
        )
        BEGIN
            RAISERROR('Кабинет уже занят другим врачом в один из дней недели!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

-- Тест триггера
BEGIN TRY
    INSERT INTO Schedule (Day_of_the_week, Start_time, Duration, Doctor_Id)
    VALUES (N'Понедельник', '09:00', 30, 2);
    
    UPDATE Doctor SET Office_number = 101 WHERE id = 2;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH

GO

IF OBJECT_ID('trg_PreventScheduleDeletion', 'TR') IS NOT NULL
    DROP TRIGGER trg_PreventScheduleDeletion;
GO

-- c) Триггер на удаление строки из графика приема врача
CREATE OR ALTER TRIGGER trg_PreventScheduleDeletion
ON Schedule
INSTEAD OF DELETE
AS
BEGIN
    -- Проверяем, есть ли талоны для удаляемых записей расписания
    IF EXISTS (
        SELECT 1 FROM deleted d
        WHERE EXISTS (
            SELECT 1 FROM Stattalon st
            WHERE st.Schedule_Id = d.id
        )
    )
    BEGIN
        RAISERROR('Нельзя удалить расписание, так как на него выданы талоны!', 16, 1);
        RETURN;
    END
    
    DECLARE @id INT;
    
    DECLARE del_cursor CURSOR FOR
        SELECT id FROM deleted;
    
    OPEN del_cursor;
    FETCH NEXT FROM del_cursor INTO @id;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM Schedule WHERE id = @id;
        FETCH NEXT FROM del_cursor INTO @id;
    END
    
    CLOSE del_cursor;
    DEALLOCATE del_cursor;
END;
GO
-- Тест триггера
DELETE FROM Schedule WHERE id = 1;