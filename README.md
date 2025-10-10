<h1 name="content" align="center"><a href=""><img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/></a> MSSQL</h1>

<p align="center">
  <a href="#-lab1"><img alt="lab1" src="https://img.shields.io/badge/Lab1-blue"></a> 
  <a href="#-lab2"><img alt="lab2" src="https://img.shields.io/badge/Lab2-red"></a>
</p>

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab1

[Назад](#content)
<h3 align="center">
  <a href="#client"></a>
  1.1 Разработать ER-модель данной предметной области: выделить сущности, их атрибуты, связи между сущностями. 
</h3>

![image](/Lab1BD/lab1er.png)

<h3 align="center">
  <a href="#client"></a>
  1.2 По имеющейся ER-модели создать реляционную модель данных и отобразить ее в виде списка сущностей с их атрибутами и типами атрибутов,  для атрибутов указать, явл. ли он первичным или внешним ключом 
</h3>

![image](/Lab1BD/lab1er.png)

# <img src="https://github.com/user-attachments/assets/e080adec-6af7-4bd2-b232-d43cb37024ac" width="20" height="20"/> Lab2
[Назад](#content) 
<h3 align="center"> 
  <a href="#client"></a>
  2 В соответствии с реляционной моделью данных, разработанной в Лаб.№1, создать реляционную БД на учебном сервере БД :
- создать таблицы, определить первичные ключи и иные ограничения
- определить связи между таблицами
- создать диаграмму
- заполнить все таблицы адекватной информацией (не меньше 10 записей в таблицах, наличие примеров для связей типа 1:M )
</h3>

Создание таблицы

```tsql
CREATE TABLE Doctor (
    id INT IDENTITY(1,1) PRIMARY KEY,
    office_number INT,
    full_name NVARCHAR(50) NOT NULL,
    phone NVARCHAR(20),
    speciality NVARCHAR(30)
);

CREATE TABLE District (
    id INT IDENTITY(1,1) PRIMARY KEY ,
    number INT NOT NULL,
    doctor_id INT REFERENCES Doctor(id) ON DELETE SET NULL
);

CREATE TABLE Schedule (
    id INT IDENTITY(1,1) PRIMARY KEY,
    day_of_the_week NVARCHAR(15) NOT NULL,
    start_time TIME NOT NULL,
    duration INT NOT NULL,
    doctor_id INT REFERENCES Doctor(id) ON DELETE CASCADE
);

CREATE TABLE Patient (
    id INT IDENTITY(1,1) PRIMARY KEY,
    phone NVARCHAR(20),
    full_name NVARCHAR(50) NOT NULL,
    district_Id INT REFERENCES District(id) ON DELETE SET NULL
);

CREATE TABLE Reception (
    id INT IDENTITY(1,1) PRIMARY KEY,
    reception_time DATETIME NOT NULL,
    diagnosis NVARCHAR(100),
    patient_id INT REFERENCES Patient(id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctor(id) ON DELETE NO ACTION
);

CREATE TABLE Stattalon (
    id INT IDENTITY(1,1) PRIMARY KEY,
    purpose NVARCHAR(100),
    schedule_id INT REFERENCES Schedule(id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctor(id) ON DELETE NO ACTION,
    patient_id INT REFERENCES Patient(id) ON DELETE NO ACTION
);
```

Диаграмма

![image](/Lab2BD/lab2diagram.png)

Заполненные данными таблицы:

Doctor

![image](/Lab2BD/lab2doctor.png)

Patient

![image](/Lab2BD/lab2patient.png)

Reception

![image](/Lab2BD/lab2reeception.png)

Schedule

![image](/Lab2BD/lab2schedule.png)

Stattalon

![image](/Lab2BD/lab2stattalon.png)

District

![image](/Lab2BD/lab2district.png)
