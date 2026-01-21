--ÑÎÇÄÀÍÈÅ ÁÀÇÛ ÄÀÍÍÛÕ
CREATE DATABASE SchoolDB
ON PRIMARY 
(
	NAME = N'SCHOOL',
	FILENAME = 'C:\Users\rodic\Desktop\Óíèâåð\5 ñåìåñòð\ÁÄ\ÈÄÇ\School_data_base.mdf',
	SIZE = 50MB,
	MAXSIZE = 200MB,
	FILEGROWTH = 10MB
)
LOG ON
(
	NAME = N'SCHOOL_log',
	FILENAME = 'C:\Users\rodic\Desktop\Óíèâåð\5 ñåìåñòð\ÁÄ\ÈÄÇ\School_data_base.ldf',
	SIZE = 50MB,
	MAXSIZE = 200MB,
	FILEGROWTH = 10MB
)


--ÑÎÇÄÀÍÈÅ ÑÕÅÌ
CREATE SCHEMA dict
CREATE SCHEMA edu
CREATE SCHEMA lib
CREATE SCHEMA med
CREATE SCHEMA parents
CREATE SCHEMA security


SELECT table_name FROM information_schema.tables

--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ dict
CREATE TABLE dict.Subjects (
    SubjectID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    ShortName NVARCHAR(20) NULL,
    IsActive BIT NOT NULL DEFAULT 1
)


CREATE TABLE dict.Rooms (
    room_id INT IDENTITY(1,1) NOT NULL,
    room_number INT NOT NULL,
    floor_number INT NULL,
    CONSTRAINT PK_Rooms PRIMARY KEY (room_id),
    CONSTRAINT UQ_Rooms_Number UNIQUE (room_number),
    CONSTRAINT CHK_Rooms_Floor CHECK (floor_number BETWEEN 1 AND 5)
)


CREATE TABLE dict.Benefits (
    benefit_id INT IDENTITY(1,1) PRIMARY KEY,
    benefit_name NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(300) NULL,
    valid_until DATE NULL
)

--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ edu
CREATE TABLE edu.Students (
    student_id INT IDENTITY(1,1) NOT NULL,
    surname NVARCHAR(50) NOT NULL,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    sex CHAR(1) NOT NULL,
    class_id INT NOT NULL,
    snils CHAR(11) NOT NULL,
    benefit_id INT NULL,
    address NVARCHAR(200) NOT NULL,
    date_enrollment DATE NOT NULL,
    CONSTRAINT PK_Students PRIMARY KEY (student_id),
    CONSTRAINT CHK_Students_Sex CHECK (sex IN ('Ì', 'Æ')),
    CONSTRAINT CHK_Students_SNILS_Length CHECK (LEN(snils) = 11),
    CONSTRAINT UQ_Students_SNILS UNIQUE (snils),
    CONSTRAINT FK_Students_Class FOREIGN KEY (class_id) REFERENCES edu.Classes(class_id),
    CONSTRAINT FK_Students_Benefit FOREIGN KEY (benefit_id) REFERENCES dict.Benefits(benefit_id)
)


CREATE TABLE edu.Classes (
    class_id INT IDENTITY(1,1) NOT NULL,
    number INT NOT NULL,
    letter CHAR(1) NOT NULL,
    teacher_id INT NOT NULL,
    CONSTRAINT PK_Classes PRIMARY KEY (class_id),
    CONSTRAINT CHK_Classes_Number CHECK (number BETWEEN 1 AND 11),
    CONSTRAINT CHK_Classes_Letter CHECK (letter LIKE '[À-ß]'),
    CONSTRAINT UQ_Classes_NumberLetter UNIQUE (number, letter),
    CONSTRAINT FK_Classes_Teacher FOREIGN KEY (teacher_id) REFERENCES edu.Teachers(teacher_id)
)


CREATE TABLE edu.Teachers (
    teacher_id INT IDENTITY(1,1) NOT NULL,
    surname NVARCHAR(50) NOT NULL,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    sex CHAR(1) NOT NULL,
    passport_number CHAR(10) NOT NULL,
    experience INT NULL,
    address NVARCHAR(200) NULL,
    phone_number CHAR(11) NULL,
    email NVARCHAR(50) NULL,
    CONSTRAINT PK_Teachers PRIMARY KEY (teacher_id),
    CONSTRAINT CHK_Teachers_Sex CHECK (sex IN ('Ì', 'Æ')),
    CONSTRAINT CHK_Teachers_Passport CHECK (LEN(passport_number) = 10),
    CONSTRAINT UQ_Teachers_Passport UNIQUE (passport_number),
    CONSTRAINT UQ_Teachers_Phone UNIQUE (phone_number)
)


CREATE TABLE edu.Grades (
    grade_id INT IDENTITY(1,1) NOT NULL,
    student_id INT NOT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    grade INT NOT NULL,
    grade_date DATE NOT NULL,
    type_work NVARCHAR(100) NOT NULL DEFAULT 'Ðàáîòà íà óðîêå',
    CONSTRAINT PK_Grades PRIMARY KEY (grade_id),
    CONSTRAINT CHK_Grades_Grade CHECK (grade BETWEEN 1 AND 5),
    CONSTRAINT FK_Grades_Student FOREIGN KEY (student_id) REFERENCES edu.Students(student_id),
    CONSTRAINT FK_Grades_Subject FOREIGN KEY (subject_id) REFERENCES dict.Subjects(SubjectID),
    CONSTRAINT FK_Grades_Teacher FOREIGN KEY (teacher_id) REFERENCES edu.Teachers(teacher_id)
)


CREATE TABLE edu.Schedule (
    schedule_id INT IDENTITY(1,1) NOT NULL,
    class_id INT NOT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NULL,
    room_id INT NOT NULL,
    week_day CHAR(2) NOT NULL,
    lesson_number INT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT PK_Schedule PRIMARY KEY (schedule_id),
    CONSTRAINT CHK_Schedule_Day CHECK (week_day IN ('ÏÍ','ÂÒ','ÑÐ','×Ò','ÏÒ','ÑÁ')),
    CONSTRAINT CHK_Schedule_Lesson CHECK (lesson_number BETWEEN 1 AND 10),
    CONSTRAINT FK_Schedule_Class FOREIGN KEY (class_id) REFERENCES edu.Classes(class_id),
    CONSTRAINT FK_Schedule_Subject FOREIGN KEY (subject_id) REFERENCES dict.Subjects(SubjectID),
    CONSTRAINT FK_Schedule_Teacher FOREIGN KEY (teacher_id) REFERENCES edu.Teachers(teacher_id),
    CONSTRAINT FK_Schedule_Room FOREIGN KEY (room_id) REFERENCES dict.Rooms(room_id)
)


--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ med
CREATE TABLE med.HealthCards (
    healthcard_id INT IDENTITY(1,1) NOT NULL,
    student_id INT NOT NULL,
    blood_type CHAR(3) NULL,   -- 0+, A-, AB+...
    chronic_illnesses NVARCHAR(500) NULL,
    allergy_info NVARCHAR(500) NULL,
    disability_group CHAR(1) NULL,   -- 1 / 2 / 3
    vaccination_status NVARCHAR(200) NULL,  
    CONSTRAINT PK_HealthCards PRIMARY KEY (healthcard_id),
    CONSTRAINT CHK_HealthCards_Blood_New
CHECK (
    blood_type LIKE '0[+-]' OR
    blood_type LIKE 'A[+-]' OR
    blood_type LIKE 'B[+-]' OR
    blood_type LIKE 'AB[+-]'
),
    CONSTRAINT CHK_HealthCards_Disability CHECK (disability_group IN ('1','2','3')),
    CONSTRAINT FK_HealthCards_Student FOREIGN KEY(student_id) REFERENCES edu.Students(student_id) ON DELETE CASCADE
)


CREATE TABLE med.MedVisits (
    visit_id INT IDENTITY(1,1) NOT NULL,
    student_id INT NOT NULL,
    visit_date DATETIME NOT NULL,
    reason NVARCHAR(500) NOT NULL,
    diagnosis NVARCHAR(300) NULL,
    treatment NVARCHAR(300) NULL,
    sent_home BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_MedVisits PRIMARY KEY (visit_id),
    CONSTRAINT FK_MedVisits_Student FOREIGN KEY (student_id) REFERENCES edu.Students(student_id)
)


--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ lib
CREATE TABLE lib.Books (
    book_id INT IDENTITY(1,1) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    author NVARCHAR(200) NOT NULL,
    publish_year INT NULL,
    genre NVARCHAR(100) NULL,
    CONSTRAINT PK_Books PRIMARY KEY (book_id),
    CONSTRAINT CHK_Books_Year CHECK (publish_year IS NULL OR publish_year BETWEEN 1900 AND YEAR(GETDATE()))
)

CREATE TABLE lib.BookCopies (
    copy_id INT IDENTITY(1,1) NOT NULL,
    book_id INT NOT NULL,
    inventory_number NVARCHAR(50) NOT NULL,
    condition_note NVARCHAR(200) NULL,
    CONSTRAINT PK_BookCopies PRIMARY KEY (copy_id),
    CONSTRAINT UQ_BookCopies_Inv UNIQUE (inventory_number),
    CONSTRAINT FK_BookCopies_Book FOREIGN KEY (book_id) REFERENCES lib.Books(book_id)
)

CREATE TABLE lib.Loans (
    loan_id INT IDENTITY(1,1) NOT NULL,
    copy_id INT NOT NULL,
    student_id INT NOT NULL,
    date_issued DATE NOT NULL,
    date_due DATE NOT NULL,
    date_returned DATE NULL,
    CONSTRAINT PK_Loans PRIMARY KEY (loan_id),
    CONSTRAINT CHK_Loans_Dates CHECK (date_due > date_issued AND 
        (date_returned IS NULL OR date_returned >= date_issued)),
    CONSTRAINT FK_Loans_Copy FOREIGN KEY (copy_id) REFERENCES lib.BookCopies(copy_id),
    CONSTRAINT FK_Loans_Student FOREIGN KEY (student_id) REFERENCES edu.Students(student_id)
)

ALTER TABLE lib.Loans
ADD is_overdue AS (
    CASE 
        WHEN date_returned IS NULL AND date_due < CONVERT(date, GETDATE()) THEN 1 
        ELSE 0 
    END
);

--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ parents
CREATE TABLE parents.Parents (
    parent_id INT IDENTITY(1,1) NOT NULL,
    surname NVARCHAR(50) NOT NULL,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    phone_number CHAR(11) NOT NULL,
    email NVARCHAR(100) NULL,
    address NVARCHAR(200) NULL,
    CONSTRAINT PK_Parents PRIMARY KEY (parent_id),
    CONSTRAINT UQ_Parents_Phone UNIQUE (phone_number)
)

CREATE TABLE parents.StudentParents (
    student_parent_id INT IDENTITY(1,1) NOT NULL,
    student_id INT NOT NULL,
    parent_id INT NOT NULL,
    relation NVARCHAR(20) NOT NULL,  -- ìàìà, ïàïà, îïåêóí
    CONSTRAINT PK_StudentParents PRIMARY KEY (student_parent_id),
    CONSTRAINT FK_StudentParents_Student FOREIGN KEY (student_id)
        REFERENCES edu.Students(student_id),
    CONSTRAINT FK_StudentParents_Parent FOREIGN KEY (parent_id)
        REFERENCES parents.Parents(parent_id),
    CONSTRAINT CHK_StudentParents_Relation CHECK (relation IN ('ìàìà','ïàïà','îïåêóí'))
)

--ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ security
CREATE TABLE security.AuditLog (
    log_id INT IDENTITY(1,1) NOT NULL,
    table_name NVARCHAR(50) NOT NULL,
    action_type NVARCHAR(10) NOT NULL CHECK(action_type IN ('INSERT','UPDATE','DELETE')),
    user_name NVARCHAR(50) NOT NULL,
    action_datetime DATETIME NOT NULL DEFAULT GETDATE(),
    old_value NVARCHAR(MAX) NULL,
    new_value NVARCHAR(MAX) NULL,
    CONSTRAINT PK_AuditLog PRIMARY KEY (log_id)
)

















