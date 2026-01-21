--ПРЕДСТАВЛЕНИЯ
--полная информация о студенте. многотабличное
CREATE VIEW edu.FullStudentInfo
AS
SELECT
    stud.student_id, stud.surname, stud.first_name, stud.last_name,
    stud.birth_date, stud.sex, cl.number AS class_number,
    cl.letter AS class_letter, ben.benefit_name,
    stud.address, stud.date_enrollment,
    ISNULL(
      (SELECT STRING_AGG(par.surname + ' ' + par.first_name + ' ' + par.last_name + ' (' + par.phone_number + ')', '; ')
       FROM parents.StudentParents AS stud_par
       JOIN parents.Parents AS par ON par.parent_id = stud_par.parent_id
       WHERE stud_par.student_id = stud.student_id
      ), '') AS parents_info,
    hc.allergy_info, hc.chronic_illnesses, hc.blood_type, hc.vaccination_status
FROM edu.Students AS stud
LEFT JOIN edu.Classes AS cl ON cl.class_id = stud.class_id
LEFT JOIN dict.Benefits AS ben ON ben.benefit_id = stud.benefit_id
LEFT JOIN med.HealthCards AS hc ON hc.student_id = stud.student_id

--SELECT * FROM edu.FullStudentInfo

--Успеваемость по предметам. Агрегирующее представление
CREATE VIEW edu.SubjectPerformance
AS
WITH Perf AS
(
    SELECT
        cls.class_id,  cls.number,  cls.letter,
        sub.SubjectID, sub.Name AS SubjectName, COUNT(gr.grade_id) AS grades_count,
        AVG(CAST(gr.grade AS FLOAT)) AS avg_grade
    FROM edu.Grades AS gr
    JOIN edu.Students AS stud ON stud.student_id = gr.student_id
    JOIN edu.Classes AS cls ON cls.class_id = stud.class_id
    JOIN dict.Subjects AS sub ON sub.SubjectID = gr.subject_id
    GROUP BY cls.class_id, cls.number, cls.letter, sub.SubjectID, sub.Name
)
SELECT
    *, DENSE_RANK() OVER (PARTITION BY class_id ORDER BY avg_grade DESC) AS SubjectRankWithinClass
FROM Perf

--SELECT * FROM edu.SubjectPerformance

--Учителя с нагрузкой. Аналитическое представление 
CREATE VIEW edu.TeachersWorkload
AS
SELECT
    teach.teacher_id, teach.surname, teach.first_name, teach.last_name,
    ISNULL(COUNT(sch.schedule_id),0) AS lessons_count,
    ISNULL(COUNT(DISTINCT sch.class_id),0) AS distinct_classes_count
FROM edu.Teachers AS teach
LEFT JOIN edu.Schedule AS sch ON sch.teacher_id = teach.teacher_id
GROUP BY teach.teacher_id, teach.surname, teach.first_name, teach.last_name


--SELECT * FROM edu.TeachersWorkload

--ЛОГИРОВАНИЕ ИЗМЕНЕНИЙ В Auditlog
CREATE PROCEDURE security.sp_WriteAudit
    @table_name NVARCHAR(100), @action_type NVARCHAR(10), 
    @user_name NVARCHAR(128), @old_value NVARCHAR(MAX),
    @new_value NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO security.AuditLog (table_name, action_type, user_name, action_datetime, old_value, new_value)
    VALUES (@table_name, @action_type, @user_name, GETDATE(), @old_value, @new_value)
END

CREATE TRIGGER trg_Students_Audit
ON edu.Students
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @uname NVARCHAR(128) = SUSER_SNAME()

    -- INSERT или UPDATE
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO security.AuditLog 
            (table_name, action_type, user_name, action_datetime, old_value, new_value)
        VALUES (
            'edu.Students',
            CASE 
                WHEN EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE' 
                ELSE 'INSERT' 
            END,
            @uname, GETDATE(),
            (SELECT * FROM deleted FOR JSON PATH),
            (SELECT * FROM inserted FOR JSON PATH)
        )
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO security.AuditLog 
            (table_name, action_type, user_name, action_datetime, old_value, new_value)
        VALUES (
            'edu.Students', 'DELETE', @uname, GETDATE(),
            (SELECT * FROM deleted FOR JSON PATH), NULL
        )
    END
END

--INSERT INTO edu.Students (surname, first_name, last_name, birth_date, sex, class_id, snils, benefit_id, address, date_enrollment) 
--VALUES ('Родичкина', 'Марта', 'Николаевна', '2007-03-23', 'Ж', 22, '29805681209', NULL, 'г.Санкт-Петербург, пр.Стачек , д. 91', '2014-09-01')
--SELECT * FROM security.AuditLog ORDER BY log_id DESC

--UPDATE edu.Students SET surname = 'Новиков' WHERE student_id = 6
--SELECT * FROM security.AuditLog ORDER BY log_id DESC

--DELETE FROM edu.Students WHERE student_id = 40
--SELECT * FROM security.AuditLog ORDER BY log_id DESC


--Представление текущих просроченных займов
CREATE VIEW lib.OverdueLoans
AS
SELECT 
    l.loan_id, l.copy_id, l.student_id, l.date_issued,
    l.date_due, l.date_returned,
    CASE WHEN l.date_returned IS NULL AND l.date_due < CONVERT(date, GETDATE()) THEN 1 ELSE 0 END AS is_overdue,
    DATEDIFF(day, l.date_due, CONVERT(date, GETDATE())) AS days_overdue,
    stud.surname + ' ' + stud.first_name + ' ' + stud.last_name AS student_fullname,
    bo.title AS book_title
FROM lib.Loans AS l
JOIN edu.Students AS stud ON stud.student_id = l.student_id
JOIN lib.BookCopies AS bc ON bc.copy_id = l.copy_id
JOIN lib.Books AS bo ON bo.book_id = bc.book_id
WHERE l.date_returned IS NULL AND l.date_due < CONVERT(date, GETDATE())

--SELECT * FROM lib.OverdueLoans

--ТРИГГЕРЫ
--создание карточки при добавлении ученика
CREATE TRIGGER trg_CreateHealthCard_OnStudentInsert
ON edu.Students
AFTER INSERT
AS
BEGIN
    INSERT INTO med.HealthCards (student_id, blood_type, chronic_illnesses, allergy_info, disability_group, vaccination_status)
    SELECT i.student_id, NULL, NULL, NULL, NULL, NULL
    FROM inserted i
    LEFT JOIN med.HealthCards hc ON hc.student_id = i.student_id
    WHERE hc.student_id IS NULL;  
END


--ХРАНИМЫЕ ПРОЦЕДУРЫ
--добавление студента. Хранимая процедура с параметрами
CREATE PROCEDURE edu.sp_AddStudent
    @surname NVARCHAR(50), @first_name NVARCHAR(50), @last_name NVARCHAR(50),
    @birth_date DATE, @sex CHAR(1), @class_id INT,
    @snils CHAR(11), @benefit_id INT = NULL, @address NVARCHAR(200),
    @date_enrollment DATE = NULL
AS
BEGIN
    IF @date_enrollment IS NULL SET @date_enrollment = CONVERT(date, GETDATE())
    INSERT INTO edu.Students (surname, first_name, last_name, birth_date, sex, class_id, snils, benefit_id, address, date_enrollment)
    VALUES (@surname, @first_name, @last_name, @birth_date, @sex, @class_id, @snils, @benefit_id, @address, @date_enrollment)
    DECLARE @new_id INT = SCOPE_IDENTITY()
    SELECT @new_id AS student_id
END

--EXEC edu.sp_AddStudent 'Чехонина', 'Лариса', 'Георгиевна', '2011-05-10', 'Ж', 3, '45670979418', NULL, 'Адрес', NULL
--SELECT * FROM med.HealthCards WHERE student_id = 41 

--поиск ученика по параметрам. Хранимая процедура SELECT с необязательными параметрами
CREATE PROCEDURE edu.sp_FindStudents
    @surname NVARCHAR(50) = NULL, @first_name NVARCHAR(50) = NULL,
    @snils CHAR(11) = NULL, @class_id INT = NULL, @benefit_id INT = NULL
AS
BEGIN
    SELECT stud.student_id, stud.surname, stud.first_name, 
            stud.last_name, stud.snils, stud.class_id, stud.address
    FROM edu.Students AS stud
    WHERE (@surname IS NULL OR stud.surname LIKE @surname + '%')
      AND (@first_name IS NULL OR stud.first_name LIKE @first_name + '%')
      AND (@snils IS NULL OR stud.snils = @snils)
      AND (@class_id IS NULL OR stud.class_id = @class_id)
      AND (@benefit_id IS NULL OR stud.benefit_id = @benefit_id);
END

--EXEC edu.sp_FindStudents 'Новиков'

--число дней просрочки в библиотеке. скалярная функция.
CREATE FUNCTION lib.DaysOverdue (@loan_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @days INT
    SELECT 
        @days = CASE 
                    WHEN date_returned IS NULL AND date_due < CONVERT(date, GETDATE())
                        THEN DATEDIFF(day, date_due, CONVERT(date, GETDATE()))
                    WHEN date_returned IS NOT NULL AND date_returned > date_due
                        THEN DATEDIFF(day, date_due, date_returned)
                    ELSE 0
                 END
    FROM lib.Loans
    WHERE loan_id = @loan_id
    RETURN ISNULL(@days, 0)
END

SELECT
    loan_id,
    date_issued,
    date_due,
    date_returned,
    lib.DaysOverdue(loan_id) AS days_overdue
FROM lib.Loans
WHERE loan_id IN (1,2)

DROP FUNCTION lib.fn_DaysOverdue

--SELECT lib.DaysOverdue(1) AS DaysOverdue


--все оценки ученика за период. функция возвращающая таблицу.
CREATE FUNCTION edu.fn_GetGrades
( @student_id INT, @start_date DATE, @end_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT G.grade_id, G.subject_id, G.grade, G.grade_date, G.teacher_id, G.type_work
    FROM edu.Grades G
    WHERE G.student_id = @student_id AND G.grade_date BETWEEN @start_date AND @end_date
)

SELECT * FROM edu.fn_GetGrades(6, '2014-01-09', GETDATE())

--медицинские посещения за период. 
CREATE PROCEDURE med.sp_MedVisitsByPeriod
    @date_from DATE, @date_to DATE, @student_id INT = NULL
AS
BEGIN
    SELECT mv.visit_id, mv.student_id, stud.surname + ' ' + stud.first_name AS student_name,
           mv.visit_date, mv.reason, mv.diagnosis, mv.treatment, mv.sent_home
    FROM med.MedVisits AS mv
    JOIN edu.Students AS stud ON stud.student_id = mv.student_id
    WHERE mv.visit_date BETWEEN @date_from AND @date_to
      AND (@student_id IS NULL OR mv.student_id = @student_id)
    ORDER BY mv.visit_date DESC;
END

--EXEC med.sp_MedVisitsByPeriod '2014-01-09', '2025-09-01', 31

--многооператорная функция. родители + кол-во детей родитетелй
CREATE FUNCTION parents.fn_StudentFamilyInfo
(@student_id INT)
RETURNS @Family TABLE
( parent_id INT, full_name NVARCHAR(150), phone NVARCHAR(20),
  email NVARCHAR(100), relation_type NVARCHAR(50), total_children INT)
AS
BEGIN
    INSERT INTO @Family (parent_id, full_name, phone, email, relation_type, total_children)
    SELECT
        par.parent_id,
        par.surname + ' ' + par.first_name + ' ' + par.last_name AS full_name,
        par.phone_number,
        par.email,
        sp.relation,
        (SELECT COUNT(*) FROM parents.StudentParents AS sp WHERE sp.parent_id = par.parent_id) AS total_children
    FROM parents.Parents AS par
    JOIN parents.StudentParents AS sp ON sp.parent_id = par.parent_id
    WHERE sp.student_id = @student_id
    RETURN
END

--SELECT * FROM parents.fn_StudentFamilyInfo (10)






