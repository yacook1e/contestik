-- сортировка по двум полям
SELECT * FROM Doctor
ORDER BY Speciality ASC, Full_name DESC;
GO

-- where
SELECT * FROM Doctor
WHERE Speciality = N'Терапевт';
GO

-- where с несколькими условиями
SELECT Full_name, Age, District_Id FROM Patient
WHERE Age >= 40 AND District_Id = 5;
GO

-- агрегатные функции без группировки
SELECT 
    COUNT(*) AS [Количество пациентов],
    AVG(Age) AS [Средний возраст]
FROM Patient;
GO

-- агрегатные функции с группировкой
SELECT 
    District_Id,
    COUNT(*) AS [Кол-во пациентов],
    MIN(Age) AS [Минимальный возраст]
FROM Patient
GROUP BY District_Id;
GO

-- rollup
SELECT 
    COALESCE(Speciality, 'Итого') AS [Специальность],
    COALESCE(CAST(Office_number AS NVARCHAR(20)), 'Все кабинеты') AS [Номер кабинета],
    COUNT(*) AS [Количество врачей]
FROM Doctor
GROUP BY ROLLUP (Speciality, Office_number)
ORDER BY Speciality, Office_number;
GO

-- cube
SELECT 
    COALESCE(Diagnosis, 'Все диагнозы') AS [Диагноз],
    COALESCE(CAST(Doctor_Id AS NVARCHAR(20)), 'Все врачи') AS [ID врача],
    COUNT(*) AS [Количество приемов]
FROM Reception
GROUP BY CUBE (Diagnosis, Doctor_Id)
ORDER BY Diagnosis, Doctor_Id;
GO

-- like
SELECT * FROM Patient
WHERE Full_name NOT LIKE N'%ова%';
GO

-- where
SELECT 
    r.Reception_time,
    r.Diagnosis,
    p.Full_name AS [Пациент],
    d.Full_name AS [Врач]
FROM Reception r, Patient p, Doctor d
WHERE r.Patient_ID = p.Id AND r.Doctor_Id = d.Id;
GO

-- inner join
SELECT 
    p.Full_name AS Пациент,
    p.Age AS Возраст,
    d.Number AS Участок,
    dr.Full_name AS [Участковый врач]
FROM Patient p
INNER JOIN District d ON p.District_Id = d.Id
INNER JOIN Doctor dr ON d.Doctor_Id = dr.Id;
GO

-- inner join 2
SELECT 
    d.Full_name AS Врач,
    d.Speciality AS Специальность,
    COUNT(r.Id) AS [Количество приемов]
FROM Doctor d
INNER JOIN Reception r ON d.Id = r.Doctor_Id
GROUP BY d.Full_name, d.Speciality;
GO

-- left join
SELECT 
    d.Full_name,
    d.Speciality,
    s.Day_of_the_week,
    s.Start_time
FROM Doctor d
LEFT JOIN Schedule s ON d.Id = s.Doctor_Id;
GO

-- left join 2
SELECT 
    p.Full_name AS Пациент,
    p.Age AS Возраст,
    r.Reception_time AS [Дата приема],
    r.Diagnosis AS Диагноз
FROM Patient p
LEFT JOIN Reception r ON p.Id = r.Patient_ID;
GO

-- right join
SELECT 
    s.Day_of_the_week,
    s.Start_time,
    d.Full_name,
    d.Speciality
FROM Doctor d
RIGHT JOIN Schedule s ON d.Id = s.Doctor_Id;
GO

-- right join 2
SELECT 
    s.Day_of_the_week AS День,
    s.Start_time AS [Время начала],
    d.Speciality AS Специальность,
    d.Office_number AS Кабинет
FROM Schedule s
RIGHT JOIN Doctor d ON s.Doctor_Id = d.Id
ORDER BY s.Day_of_the_week, s.Start_time;
GO

-- агрегатные функции
SELECT 
    d.Full_name AS [Врач],
    COUNT(r.Patient_ID) AS [Количество приемов]
FROM Doctor d
LEFT JOIN Reception r ON d.Id = r.Doctor_Id
GROUP BY d.Full_name;
GO

-- агрегатные функции 2
SELECT 
    Day_of_the_week AS День,
    COUNT(*) AS [Количество слотов],
    MIN(Start_time) AS [Самое раннее время],
    MAX(Start_time) AS [Самое позднее время]
FROM Schedule
GROUP BY Day_of_the_week;
GO

-- having
SELECT 
    Doctor_Id,
    COUNT(*) AS [Количество приемов]
FROM Reception
GROUP BY Doctor_Id
HAVING COUNT(*) >= 1;
GO

-- having 2
SELECT 
    Day_of_the_week AS День,
    COUNT(*) AS [Количество записей]
FROM Schedule
GROUP BY Day_of_the_week
HAVING COUNT(*) > 1;
GO

-- in
SELECT * FROM Patient
WHERE District_Id IN (
    SELECT Id FROM District 
    WHERE Doctor_Id IN (
        SELECT Id FROM Doctor WHERE Speciality = N'Терапевт'
    )
);
GO

-- in 2
SELECT 
    Full_name AS Пациент,
    Age AS Возраст,
    District_Id AS Участок
FROM Patient
WHERE District_Id IN (1, 2, 3);
GO


-- exists
SELECT * FROM Doctor d
WHERE EXISTS (
    SELECT 1 FROM Schedule s 
    WHERE s.Doctor_Id = d.Id AND s.Day_of_the_week = N'Понедельник'
);
GO

-- представление
IF OBJECT_ID('vw_ReceptionDetails', 'V') IS NOT NULL
    DROP VIEW vw_ReceptionDetails;
GO

CREATE VIEW vw_ReceptionDetails AS
SELECT 
    r.Id,
    r.Reception_time,
    r.Diagnosis,
    p.Full_name AS PatientName,
    p.Age,
    d.Full_name AS DoctorName,
    d.Speciality
FROM Reception r
INNER JOIN Patient p ON r.Patient_ID = p.Id
INNER JOIN Doctor d ON r.Doctor_Id = d.Id;
GO

SELECT * FROM vw_ReceptionDetails WHERE Diagnosis = N'Пневмония';
GO

-- представление 2
IF OBJECT_ID('vw_DistrictPatientCount', 'V') IS NOT NULL
    DROP VIEW vw_DistrictPatientCount;
GO

CREATE VIEW vw_DistrictPatientCount AS
SELECT 
    d.Number AS DistrictNumber,
    COUNT(p.Id) AS PatientCount
FROM District d
LEFT JOIN Patient p ON d.Id = p.District_Id
GROUP BY d.Number;
GO

SELECT * FROM vw_DistrictPatientCount ORDER BY PatientCount DESC;
GO

-- cte с ранжированием
WITH DoctorReceptionCount AS (
    SELECT 
        Doctor_Id,
        COUNT(*) as ReceptionCount
    FROM Reception
    GROUP BY Doctor_Id
)
SELECT 
    d.Full_name,
    d.Speciality,
    rc.ReceptionCount,
    RANK() OVER (ORDER BY rc.ReceptionCount DESC) AS Rank
FROM DoctorReceptionCount rc
INNER JOIN Doctor d ON rc.Doctor_Id = d.Id;
GO

-- рекурсивное cte
WITH RankedDoctors AS (
    SELECT 
        Id,
        Full_name,
        Office_number,
        1 AS Level
    FROM Doctor
    WHERE Office_number BETWEEN 101 AND 105
    UNION ALL
    SELECT 
        d.Id,
        d.Full_name,
        d.Office_number,
        rd.Level + 1
    FROM Doctor d
    INNER JOIN RankedDoctors rd ON d.Office_number = rd.Office_number + 100
)
SELECT * FROM RankedDoctors;
GO

-- row_number
SELECT 
    Full_name,
    Age,
    District_Id,
    ROW_NUMBER() OVER (PARTITION BY District_Id ORDER BY Age DESC) AS RowNum
FROM Patient;
GO

-- rank и dense_rank
WITH ScheduleCount AS (
    SELECT 
        Doctor_Id,
        COUNT(*) AS ScheduleEntries
    FROM Schedule
    GROUP BY Doctor_Id
)
SELECT 
    d.Full_name,
    sc.ScheduleEntries,
    RANK() OVER (ORDER BY sc.ScheduleEntries DESC) AS [Rank],
    DENSE_RANK() OVER (ORDER BY sc.ScheduleEntries DESC) AS [DenseRank]
FROM ScheduleCount sc
INNER JOIN Doctor d ON sc.Doctor_Id = d.Id;
GO

-- union all
SELECT Speciality AS [Название] FROM Doctor
UNION ALL
SELECT Diagnosis FROM Reception;
GO

-- except
SELECT Id, Full_name FROM Patient
EXCEPT
SELECT DISTINCT p.Id, p.Full_name
FROM Patient p
INNER JOIN Reception r ON p.Id = r.Patient_ID
INNER JOIN Doctor d ON r.Doctor_Id = d.Id
WHERE d.Speciality = N'Терапевт';
GO

-- intersect
SELECT Full_name AS [Пациенты, посещавшие терапевта]
FROM Patient
WHERE Id IN (
    SELECT Patient_ID FROM Reception WHERE Doctor_Id IN (SELECT Id FROM Doctor WHERE Speciality = N'Терапевт')
)
ORDER BY Full_name;
GO

-- case
SELECT 
    District_Id,
    COUNT(CASE WHEN Age BETWEEN 0 AND 18 THEN 1 END) AS [0-18],
    COUNT(CASE WHEN Age BETWEEN 19 AND 40 THEN 1 END) AS [19-40],
    COUNT(CASE WHEN Age > 40 THEN 1 END) AS [40+]
FROM Patient
GROUP BY District_Id;
GO

-- pivot
WITH ReceptionsByDay AS (
    SELECT 
        FORMAT(Reception_time, 'dddd', 'ru-ru') AS DayOfWeek,
        Id
    FROM Reception
)
SELECT * FROM (
    SELECT DayOfWeek FROM ReceptionsByDay
) AS SourceTable
PIVOT (
    COUNT(DayOfWeek) FOR DayOfWeek IN ([понедельник], [вторник], [среда], [четверг], [пятница], [суббота], [воскресенье])
) AS PivotTable;
GO

-- unpivot
WITH PivotData AS (
    SELECT 
        District_Id,
        COUNT(CASE WHEN Age < 18 THEN 1 END) AS [Дети],
        COUNT(CASE WHEN Age BETWEEN 18 AND 60 THEN 1 END) AS [Взрослые],
        COUNT(CASE WHEN Age > 60 THEN 1 END) AS [Пенсионеры]
    FROM Patient
    GROUP BY District_Id
)
SELECT District_Id, AgeGroup, PatientCount
FROM PivotData
UNPIVOT (
    PatientCount FOR AgeGroup IN ([Дети], [Взрослые], [Пенсионеры])
) AS Unpivot_test;
GO

-- часть 2 а
SELECT 
    s.Day_of_the_week,
    s.Start_time,
    s.Duration,
    d.Full_name AS Doctor
FROM Schedule s
INNER JOIN Doctor d ON s.Doctor_Id = d.Id
WHERE d.Id = 1 
    AND s.Day_of_the_week = N'Понедельник'
    AND NOT EXISTS (
        SELECT 1 FROM Reception r 
        WHERE r.Doctor_Id = s.Doctor_Id 
          AND CAST(r.Reception_time AS TIME) = s.Start_time
          AND DATEPART(weekday, r.Reception_time) = 2
    );
GO

-- часть 2 б
SELECT 
    r.Reception_time,
    r.Diagnosis,
    d.Full_name AS Doctor,
    d.Speciality
FROM Reception r
INNER JOIN Patient p ON r.Patient_ID = p.Id
INNER JOIN Doctor d ON r.Doctor_Id = d.Id
WHERE p.Full_name = N'Смирнов Константин Дмитриевич'
    AND r.Reception_time >= '2024-01-01'
ORDER BY r.Reception_time;
GO

-- часть 2 c
SELECT DISTINCT
    d.Full_name,
    d.Speciality,
    s.Day_of_the_week,
    s.Start_time
FROM Schedule s
INNER JOIN Doctor d ON s.Doctor_Id = d.Id
WHERE s.Day_of_the_week = DATENAME(weekday, GETDATE());
GO

-- часть 2 d
SELECT 
    CASE 
        WHEN p.Age BETWEEN 14 AND 18 THEN '14-18'
        WHEN p.Age BETWEEN 19 AND 45 THEN '19-45'
        WHEN p.Age BETWEEN 46 AND 65 THEN '46-65'
        WHEN p.Age >= 66 THEN '66+'
        ELSE 'Другое'
    END AS AgeGroup,
    COUNT(*) AS PneumoniaCount
FROM Reception r
INNER JOIN Patient p ON r.Patient_ID = p.Id
WHERE r.Diagnosis = N'Пневмония'
    AND r.Reception_time >= '2024-01-01'
GROUP BY 
    CASE 
        WHEN p.Age BETWEEN 14 AND 18 THEN '14-18'
        WHEN p.Age BETWEEN 19 AND 45 THEN '19-45'
        WHEN p.Age BETWEEN 46 AND 65 THEN '46-65'
        WHEN p.Age >= 66 THEN '66+'
        ELSE 'Другое'
    END
ORDER BY AgeGroup;
GO

-- часть 2 e
SELECT 
    dist.Number AS DistrictNumber,
    COUNT(r.Id) AS VisitCount
FROM Reception r
INNER JOIN Patient p ON r.Patient_ID = p.Id
INNER JOIN District dist ON p.District_Id = dist.Id
WHERE CAST(r.Reception_time AS DATE) = '2024-01-17'
GROUP BY dist.Number
ORDER BY VisitCount DESC;
GO