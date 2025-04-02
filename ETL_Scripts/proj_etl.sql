-- Drop the tables if they exist in the data_warehouse schema with CASCADE
DROP TABLE IF EXISTS data_warehouse.grades CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics_grades_demographic CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics_grades_school CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics_grades_course CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics_grades_district CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics_grades CASCADE;
DROP TABLE IF EXISTS data_warehouse.analytics CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_type CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_subType CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_district CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_phase CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_studentDemographic CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_year CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_course CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_school CASCADE;
DROP TABLE IF EXISTS data_warehouse.dim_exam CASCADE;
-- Create Data Warehouse Schema
SET search_path TO enes_2013, data_warehouse;

-- Create Data Warehouse Schema 
CREATE SCHEMA IF NOT EXISTS data_warehouse;
SET search_path TO data_warehouse;

-- Create Dimension Tables
CREATE TABLE dim_exam (
    examId INT PRIMARY KEY,
    examName VARCHAR(255)
);

CREATE TABLE dim_course (
    courseId SERIAL PRIMARY KEY,
    courseName VARCHAR(255),  
    start_date DATE,
    end_date DATE, 
    subTypeId INT,
    subTypeName VARCHAR(100), 
    typeId INT,
    typeName VARCHAR(100)
);

CREATE TABLE dim_school (
    schoolId SERIAL PRIMARY KEY,
    schoolName VARCHAR(255), 
    start_date DATE,
    end_date DATE, 
    pubPrivId INT,
    pubPrivAcro VARCHAR(50),
    municipalityId INT,
    municipalityName VARCHAR(100), 
    districtId INT,
    districtName VARCHAR(100),
    region VARCHAR(100) 
);

CREATE TABLE dim_year (
    yearId SERIAL PRIMARY KEY,
    year INT UNIQUE NOT NULL 
);

CREATE TABLE dim_studentDemographic (
    studentDemographicId SERIAL PRIMARY KEY,
    sex VARCHAR(10),
    age INT,
    ageCategory VARCHAR(50)
);

CREATE TABLE dim_phase (
    phaseId SERIAL PRIMARY KEY,
    phase VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE dim_district (
    districtId SERIAL PRIMARY KEY,
    districtName VARCHAR(100) UNIQUE NOT NULL,
    region VARCHAR(100) 
);

CREATE TABLE dim_subType (
    subTypeId SERIAL PRIMARY KEY,
    subTypeName VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dim_type (
    typeId SERIAL PRIMARY KEY,
    typeName VARCHAR(100) UNIQUE NOT NULL
);

-- Create Fact Table for Grades
CREATE TABLE grades (
    examId INT REFERENCES dim_exam(examId),
    schoolId INT REFERENCES dim_school(schoolId),
    courseId INT REFERENCES dim_course(courseId),
    yearId INT REFERENCES dim_year(yearId),
    studentDemographicId INT REFERENCES dim_studentDemographic(studentDemographicId),
    phaseId INT REFERENCES dim_phase(phaseId),
    forAproval BOOLEAN,
    intern BOOLEAN,
    forImprove BOOLEAN,
    hasAplication BOOLEAN,
    hasIntern BOOLEAN,
    grade INT,
    cif INT,
    cfd INT
);

-- Fact Tables for Aggregated Grades
CREATE TABLE analytics_grades (
    examId INT REFERENCES dim_exam(examId),
    yearId INT REFERENCES dim_year(yearId),
    phaseId INT REFERENCES dim_phase(phaseId),
    averageGrade INT,
    averageCif FLOAT,
    averageCfd FLOAT,
    nrExams INT,
    maxGrade INT,
    minGrade INT,
    medianGrade INT
);

CREATE TABLE analytics_grades_district (
    examId INT REFERENCES dim_exam(examId),
    yearId INT REFERENCES dim_year(yearId),
    districtId INT REFERENCES dim_district(districtId),
    studentDemographicId INT REFERENCES dim_studentDemographic(studentDemographicId),
    averageGrade INT,
    averageCif FLOAT,
    averageCfd FLOAT,
    nrExams INT,
    maxGrade INT,
    minGrade INT,
    medianGrade INT
);

CREATE TABLE analytics_grades_course (
    examId INT REFERENCES dim_exam(examId),
    yearId INT REFERENCES dim_year(yearId),
    courseId INT REFERENCES dim_course(courseId),
    subTypeId INT REFERENCES dim_subType(subTypeId),
    typeId INT REFERENCES dim_type(typeId),
    averageGrade INT,
    averageCif FLOAT,
    averageCfd FLOAT,
    nrExams INT,
    maxGrade INT,
    minGrade INT,
    medianGrade INT
);

CREATE TABLE analytics_grades_school (
    examId INT REFERENCES dim_exam(examId),
    yearId INT REFERENCES dim_year(yearId),
    schoolId INT REFERENCES dim_school(schoolId),
    phaseId INT REFERENCES dim_phase(phaseId),
    averageGrade INT,
    averageCif FLOAT,
    averageCfd FLOAT,
    nrExams INT,
    maxGrade INT,
    minGrade INT,
    medianGrade INT
);

CREATE TABLE analytics_grades_demographic (
    examId INT REFERENCES dim_exam(examId),
    yearId INT REFERENCES dim_year(yearId),
    studentDemographicId INT REFERENCES dim_studentDemographic(studentDemographicId),
    phaseId INT REFERENCES dim_phase(phaseId),
    averageGrade INT,
    averageCif FLOAT,
    averageCfd FLOAT,
    nrExams INT,
    maxGrade INT,
    minGrade INT,
    medianGrade INT
);

-- Load Dimensions from the Relational Database
-- Load dim_exam
INSERT INTO dim_exam (examId, examName)
SELECT *
FROM enes_2013.tblexames;

-- Load dim_district
INSERT INTO dim_district (districtId, districtName, region)
SELECT DISTINCT 
    distrito AS districtId, 
    descr AS districtName,
    CASE 
        WHEN descr IN ('Braga', 'Braganca', 'Porto', 'Viana do Castelo', 'Vila Real') THEN 'Norte'
        WHEN descr IN ('Aveiro', 'Castelo Branco', 'Coimbra', 'Guarda', 'Leiria', 'Viseu') THEN 'Centro'
        WHEN descr IN ('Beja', 'Evora', 'Faro', 'Portalegre', 'Lisboa', 'Santarem', 'Setubal') THEN 'Sul'
        WHEN descr IN ('R. A. Acores', 'R. A. Madeira') THEN 'Regiões Autónomas'
        WHEN descr = 'Estrangeiro' THEN 'Estrangeiro'
        ELSE NULL 
    END AS region
FROM enes_2013.tblcodsdistrito;

-- Load dim_year
INSERT INTO dim_year (year)
SELECT DISTINCT ano
FROM enes_2013.tblhomologa;

-- Load dim_phase
INSERT INTO dim_phase (phase)
SELECT DISTINCT fase
FROM enes_2013.tblhomologa;

-- Load dim_studentDemographic
INSERT INTO dim_studentDemographic (sex, age, ageCategory)
SELECT DISTINCT 
    sexo, 
    idade,
    CASE 
        WHEN idade <= 15 THEN '< 16 years'
        WHEN idade BETWEEN 16 AND 18 THEN '16-18 years'
        WHEN idade BETWEEN 19 AND 21 THEN '19-21 years'
        WHEN idade BETWEEN 22 AND 25 THEN '22-25 years'
        WHEN idade BETWEEN 26 AND 30 THEN '26-30 years'
        WHEN idade > 30 THEN '> 30 years'
        ELSE 'Unknown' -- Handle NULL or unexpected values
    END AS ageCategory
FROM enes_2013.tblhomologa;

-- Load dim_type 
INSERT INTO dim_type (typeName)
SELECT DISTINCT tpcurso
FROM enes_2013.tblcursostipos;

-- Load dim_subType 
INSERT INTO dim_subType (subTypeName)
SELECT DISTINCT subtipo
FROM enes_2013.tblcursossub;

-- Load dim_school
INSERT INTO dim_school (schoolId, schoolName, pubPrivId, pubPrivAcro, municipalityId, municipalityName, districtId, districtName, region)
SELECT DISTINCT 
    e.escola AS schoolId,
    e.descr AS schoolName,
    CASE 
        WHEN e.pubpriv = 'PRI' THEN 1
        WHEN e.pubpriv = 'PUB' THEN 2
        ELSE NULL 
    END AS pubPrivId, 
    e.pubpriv AS pubPrivAcro,
    e.concelho AS municipalityId,
    c.descr AS municipalityName,
    e.distrito AS districtId,
    d.descr AS districtName,
    -- Assign region based on district
    CASE 
        WHEN d.descr IN ('Braga', 'Braganca', 'Porto', 'Viana do Castelo', 'Vila Real') THEN 'Norte'
        WHEN d.descr IN ('Aveiro', 'Castelo Branco', 'Coimbra', 'Guarda', 'Leiria', 'Viseu') THEN 'Centro'
        WHEN d.descr IN ('Beja', 'Evora', 'Faro', 'Portalegre', 'Lisboa', 'Santarem', 'Setubal') THEN 'Sul'
        WHEN d.descr IN ('R. A. Acores', 'R. A. Madeira') THEN 'Regiões Autónomas'
        WHEN d.descr = 'Estrangeiro' THEN 'Estrangeiro'
        ELSE NULL 
    END AS region
FROM enes_2013.tblescolas e
JOIN enes_2013.tblcodsdistrito d ON e.distrito = d.distrito
JOIN enes_2013.tblcodsconcelho c ON e.concelho = c.concelho AND e.distrito = c.distrito;



-- Load dim_course
INSERT INTO dim_course (courseName, subTypeId, subTypeName, typeId, typeName)
SELECT DISTINCT 
    c.curso AS courseName,
    (SELECT subTypeId FROM dim_subType WHERE subTypeName = c.subtipo) AS subTypeId,
    c.subtipo AS subTypeName,
    (SELECT typeId FROM dim_type WHERE typeName = c.tpcurso) AS typeId,
    c.tpcurso AS typeName
FROM enes_2013.tblcursos c;


-- Load Fact Table Grades from the Relational Database
INSERT INTO grades (examId, schoolId, courseId, yearId, studentDemographicId, phaseId, forAproval, intern, forImprove, hasAplication, hasIntern, grade, cif, cfd)
SELECT 
    h.exame,
    h.escola,
    (SELECT courseId FROM dim_course WHERE courseName = c.courseName) AS courseId,
    (SELECT yearId FROM dim_year WHERE year = h.ano) AS yearId,
    (SELECT studentDemographicId FROM dim_studentDemographic WHERE sex = h.sexo AND age = h.idade) AS studentDemographicId,
    (SELECT phaseId FROM dim_phase WHERE phase = h.fase) AS phaseId,
    h.paraaprov,
    h.interno,
    h.paramelhoria,
    h.paraingresso,
    h.teminterno,
    h.class_exam,  -- Convert to INTEGER
    h.cif,  -- Convert to FLOAT
    h.cfd   -- Convert to FLOAT
FROM enes_2013.tblhomologa h
JOIN dim_course c ON h.curso = c.courseName;

INSERT INTO analytics_grades (examId, yearId, phaseId, averageGrade, averageCif, averageCfd, nrExams, maxGrade, minGrade, medianGrade)
SELECT 
    g.examId,
    g.yearId,
    g.phaseId,
    AVG(g.grade) AS averageGrade,
    AVG(g.cif) AS averageCif,
    AVG(g.cfd) AS averageCfd,
    COUNT(g.grade) AS nrExams,
    MAX(g.grade) AS maxGrade,
    MIN(g.grade) AS minGrade,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade) AS medianGrade 
FROM grades g
GROUP BY g.examId, g.yearId, g.phaseId;

INSERT INTO analytics_grades_district (examId, yearId, districtId, studentDemographicId, averageGrade, averageCif, averageCfd, nrExams, maxGrade, minGrade, medianGrade)
SELECT 
    g.examId,
    g.yearId,
    s.districtId,
    g.studentDemographicId,
    AVG(g.grade) AS averageGrade,
    AVG(g.cif) AS averageCif,
    AVG(g.cfd) AS averageCfd,
    COUNT(g.grade) AS nrExams,
    MAX(g.grade) AS maxGrade,
    MIN(g.grade) AS minGrade,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade) AS medianGrade 
FROM grades g
JOIN dim_school s ON g.schoolId = s.schoolId
GROUP BY g.examId, g.yearId, s.districtId, g.studentDemographicId;

INSERT INTO analytics_grades_course (examId, yearId, courseId, subTypeId, typeId, averageGrade, averageCif, averageCfd, nrExams, maxGrade, minGrade, medianGrade)
SELECT 
    g.examId,
    g.yearId,
    c.courseId,
    c.subTypeId,
    c.typeId,
    AVG(g.grade) AS averageGrade,
    AVG(g.cif) AS averageCif,
    AVG(g.cfd) AS averageCfd,
    COUNT(g.grade) AS nrExams,
    MAX(g.grade) AS maxGrade,
    MIN(g.grade) AS minGrade,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade) AS medianGrade 
FROM grades g
JOIN dim_course c ON g.courseId = c.courseId
GROUP BY g.examId, g.yearId, c.courseId, c.subTypeId, c.typeId;

INSERT INTO analytics_grades_school (examId, yearId, schoolId, phaseId, averageGrade, averageCif, averageCfd, nrExams, maxGrade, minGrade, medianGrade)
SELECT 
    g.examId,
    g.yearId,
    g.schoolId,
    g.phaseId,
    AVG(g.grade) AS averageGrade,
    AVG(g.cif) AS averageCif,
    AVG(g.cfd) AS averageCfd,
    COUNT(g.grade) AS nrExams,
    MAX(g.grade) AS maxGrade,
    MIN(g.grade) AS minGrade,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade) AS medianGrade 
FROM grades g
GROUP BY g.examId, g.yearId, g.schoolId, g.phaseId;

INSERT INTO analytics_grades_demographic (examId, yearId, studentDemographicId, phaseId, averageGrade, averageCif, averageCfd, nrExams, maxGrade, minGrade, medianGrade)
SELECT 
    g.examId,
    g.yearId,
    g.studentDemographicId,
    g.phaseId,
    AVG(g.grade) AS averageGrade,
    AVG(g.cif) AS averageCif,
    AVG(g.cfd) AS averageCfd,
    COUNT(g.grade) AS nrExams,
    MAX(g.grade) AS maxGrade,
    MIN(g.grade) AS minGrade,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY g.grade) AS medianGrade 
FROM grades g
GROUP BY g.examId, g.yearId, g.studentDemographicId, g.phaseId;