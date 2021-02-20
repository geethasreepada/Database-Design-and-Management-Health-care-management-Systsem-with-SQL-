USE TEAM3;

---create DMK--
CREATE MASTER KEY
ENCRYPTION BY PASSWORD ='P@$$WORD';

---create certificate---
CREATE CERTIFICATE TestCertificate
WITH SUBJECT = 'Team3 Project Certificate',
EXPIRY_DATE = '2025-10-05'

---create certificate for encryption---
CREATE SYMMETRIC KEY TestSymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY CERTIFICATE TestCertificate


---open symmetric key---
OPEN SYMMETRIC KEY TestSymmetricKey
DECRYPTION BY CERTIFICATE TestCertificate


---Person
CREATE TABLE dbo.Person(
	PersonID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(20) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    Password VARBINARY(250),
    Gender VARCHAR(20),
    Email VARCHAR(100) NOT NULL,
    DOB DATE,
    Age  AS DATEDIFF(hour,DOB,getDate())/8766 ,
    Phone BIGINT,
    City VARCHAR(100) NOT NULL
);

---Disease
CREATE TABLE dbo.Disease(
	DiseaseID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	Name VARCHAR(50) NOT NULL
);

---SickPatient
CREATE TABLE dbo.SickPatient(
	PatientID INT NOT NULL REFERENCES dbo.Person (PersonID),
	DiseaseID INT NOT NULL REFERENCES dbo.Disease (DiseaseID)
	CONSTRAINT PkSickPatient PRIMARY KEY CLUSTERED (PatientID,DiseaseID)
);

---Specialization
CREATE TABLE dbo.Specialization(
	SpecializationID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	SpecializationName VARCHAR(40) NOT NULL
);


---HealthProvider
CREATE TABLE dbo.HealthProvider(
	SpecializationID INT NOT NULL REFERENCES dbo.Specialization(SpecializationID),
	HealthProviderID INT NOT NULL  REFERENCES dbo.Person(PersonID),
	Shifts VARCHAR(40) NULL
	CONSTRAINT PkHealthProvider PRIMARY KEY CLUSTERED (HealthProviderID,SpecializationID)
);

---HealthSupporter
CREATE TABLE dbo.HealthSupporter(
	PatientID INT NOT NULL REFERENCES dbo.Person(PersonID),
	HealthSupporterType VARCHAR(10) NOT NULL,
	HealthSupporterID INT NOT NULL REFERENCES dbo.Person(PersonID),
	AuthorizationDate DATE
	CONSTRAINT PkHealthSupporter PRIMARY KEY CLUSTERED (HealthSupporterID,PatientID, HealthSupporterType)
)
ALTER TABLE dbo.HealthSupporter ADD CHECK(HealthSupporterType IN('PRIMARY', 'SECONDARY'));

---ActivityTracker
CREATE TABLE dbo.ActivityTracker(
	ActivityID INT  NOT NULL PRIMARY KEY IDENTITY(1,1),
	PersonID INT NOT NULL FOREIGN KEY REFERENCES Person(PersonID),
	Activity VARCHAR(20) NOT null,
	Date DATE
);

---Appointment
CREATE TABLE dbo.Appointment(
	AppointmentID BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
	PatientID INT FOREIGN KEY REFERENCES Person(PersonID),
	HealthProviderID INT FOREIGN KEY REFERENCES Person(PersonID),
	DiseaseID INT FOREIGN KEY REFERENCES Disease(DiseaseID),
	Rating SMALLINT,
	Time DATETIME2
);
ALTER TABLE dbo.Appointment ADD CHECK(5 >= Rating AND Rating >= 0);
ALTER TABLE dbo.Appointment ADD CONSTRAINT BookWithGoodDoc CHECK(dbo.checkDocRating(HealthProviderID) > 1);

CREATE FUNCTION dbo.checkDocRating(@hid INT)
RETURNS FLOAT
AS
BEGIN
	DECLARE @avg FLOAT = (SELECT AVG(Rating) FROM dbo.Appointment WHERE HealthProviderID = @hid);
	RETURN @avg;
END

INSERT INTO Appointment(PatientID,HealthProviderID,DiseaseID, Rating,Time) VALUES(1,7,4,0,'2020-11-30 10:34:09 AM')


---Alert
CREATE TABLE dbo.Alert(
	AlertID INT  NOT NULL PRIMARY KEY IDENTITY(1,1),
	PatientID INT FOREIGN KEY REFERENCES Person(PersonID),
	AlertType VARCHAR(20) NOT NULL,
	AlertMessage VARCHAR(100) NOT NULL
);
ALTER TABLE dbo.Alert ADD CHECK(AlertType IN('OUTSIDE_LIMIT_ALERT', 'SEVERITY_ALERT'));

---HealthIndicator
CREATE TABLE dbo.HealthIndicator(
	HealthIndicatorID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	HealthIndicatorName VARCHAR(30) NOT NULL,
	HealthIndicatorType VARCHAR(10) NOT NULL
)
ALTER TABLE dbo.HealthIndicator ADD CHECK(HealthIndicatorType IN('RANGE', 'ENUM'));

---DiseaseHealthIndicator
CREATE TABLE dbo.DiseaseHealthIndicator(
	HealthIndicatorID INT NOT NULL REFERENCES  dbo.HealthIndicator (HealthIndicatorID),
	DiseaseID INT NOT NULL REFERENCES dbo.Disease (DiseaseID),
	CONSTRAINT PkDiseaseHealthIndicator PRIMARY KEY CLUSTERED(HealthIndicatorID,DiseaseID)
);


---HealthIndicatorEnum
CREATE TABLE dbo.HealthIndicatorEnum(
	HealthIndicatorID INT REFERENCES HealthIndicator(HealthIndicatorID),
	ParamName VARCHAR(30) NOT NULL,
	EnumValue VARCHAR(30) NOT NULL
	CONSTRAINT PkHealthIndicatorEnum PRIMARY KEY CLUSTERED (HealthIndicatorID, ParamName, EnumValue)
)
ALTER TABLE dbo.HealthIndicatorEnum ADD CHECK(EnumValue IN('Happy', 'Sad', 'Angry', 'Anxious', 
'Mild', 'Moderate','Severe' ,'Dry', 'Whooping', 'Chesty', 'Transient', 'Cumulative', 'Circadian', 'None'));

/*ALTER TABLE dbo.HealthIndicatorEnum ADD CONSTRAINT InsertCheckEnum CHECK(dbo.checkInsertEnum(HealthIndicatorID) = 0);

CREATE FUNCTION dbo.checkInsertEnum(@hid INT)
RETURNS SMALLINT
AS 
BEGIN
	DECLARE @out SMALLINT = -1;
	IF EXISTS(SELECT 1 FROM dbo.HealthIndicator WITH(NOLOCK)
          WHERE HealthIndicatorID = @hid)
		BEGIN
			SET @out = 0;
		END
	RETURN @out
END; */


---HealthIndicatorRange
CREATE TABLE dbo.HealthIndicatorRange(
	HealthIndicatorID INT REFERENCES HealthIndicator(HealthIndicatorID),
	ParamName VARCHAR(30) NOT NULL,
	MinValue FLOAT NOT NULL,
	MaxValue FLOAT NOT NULL
	CONSTRAINT PkHealthIndicatorRange PRIMARY KEY CLUSTERED (HealthIndicatorID, ParamName)
)

ALTER TABLE dbo.HealthIndicatorRange ADD CHECK(MaxValue >= MinValue);

/*ALTER TABLE dbo.HealthIndicatorRange ADD CONSTRAINT InsertCheckRange CHECK(dbo.checkInsertRange(HealthIndicatorID) = 0);

CREATE FUNCTION dbo.checkInsertRange(@hid INT)
RETURNS SMALLINT
AS 
BEGIN
	DECLARE @out SMALLINT = -1;
	IF EXISTS(SELECT 1 FROM dbo.HealthIndicator WITH(NOLOCK)
          WHERE HealthIndicatorID = @hid)
		BEGIN
			SET @out = 0;
		END
	RETURN @out
END; */


---Observation
CREATE TABLE dbo.Observation(
	ObservationID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	PatientID INT NOT NULL REFERENCES dbo.Person(PersonID),
	HealthIndicatorID INT NOT NULL REFERENCES dbo.HealthIndicator(HealthIndicatorID),
	ParamName VARCHAR(30) NOT NULL,
	ObservationValue VARCHAR(20) NOT NULL,
	ObservationTime TIME NOT NULL,
	RecordedDate DATE NOT NULL
);

---PatientSpecificHIRange
CREATE TABLE dbo.PatientSpecificHIRange(
    PatientID INT NOT NULL REFERENCES dbo.Person(PersonID),
    HealthIndicatorID INT NOT NULL,
    ParamName VARCHAR(30) NOT NULL,
    MinValue FLOAT NOT NULL,
    MaxValue FLOAT NOT NULL,
    CONSTRAINT PKPatientSpecificHIRange PRIMARY KEY CLUSTERED(PatientID, HealthIndicatorID, ParamName),
    CONSTRAINT FKHealthIndicatorRange FOREIGN KEY(HealthIndicatorID, ParamName) REFERENCES dbo.HealthIndicatorRange(HealthIndicatorID, ParamName)
)


---PatientSpecificHIEnum
CREATE TABLE dbo.PatientSpecificHIEnum(
    PatientID INT NOT NULL REFERENCES dbo.Person(PersonID),
    HealthIndicatorID INT NOT NULL,
    ParamName VARCHAR(30) NOT NULL,
	EnumValue VARCHAR(30) NOT NULL,
    CONSTRAINT PKPatientSpecificHIEnum PRIMARY KEY CLUSTERED(PatientID, HealthIndicatorID, ParamName, EnumValue),
    CONSTRAINT FKHealthIndicatorEmunValues FOREIGN KEY(HealthIndicatorID, ParamName, EnumValue) REFERENCES dbo.HealthIndicatorEnum(HealthIndicatorID, ParamName, EnumValue)
)

---TestRanges
CREATE TABLE dbo.TestRanges(
	TestID INT NOT NULL PRIMARY KEY identity(1,1),
	TestName VARCHAR(30) NOT NULL,
	MinValue FLOAT NOT NULL,
	MaxValue FLOAT NOT NULL
)

---LabReport
CREATE TABLE dbo.LabReport(
	LabReportID INT NOT NULL PRIMARY KEY identity(1,1),
	PatientID INT NOT NULL REFERENCES dbo.Person(PersonID),
	TestID INT NOT NULL REFERENCES dbo.TestRanges(TestID),
	TestResult FLOAT NOT NULL
)
ALTER TABLE dbo.LabReport  ADD TestAnalysis AS (dbo.AnalyzeTestResult(TestID, TestResult));

CREATE FUNCTION dbo.AnalyzeTestResult(@tid INT, @tresult FLOAT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @Out VARCHAR(20);
	DECLARE @Min FLOAT = (SELECT MinValue FROM dbo.TestRanges WHERE TestID = @tid);
	DECLARE @Max FLOAT = (SELECT MaxValue FROM dbo.TestRanges WHERE TestID = @tid);
	IF @tresult < @Min OR @tresult > @Max
	BEGIN
		SET @Out = 'Abnormal';
	END
	ELSE
	BEGIN
		SET @Out = 'Normal';
	END
	RETURN @Out;
END

INSERT INTO Appointment(PatientID,HealthProviderID,DiseaseID, Rating,Time) VALUES(1,7,4,0,'2020-11-30 10:34:09 AM')


----Insert Data into Tables

---Person
INSERT INTO dbo.Person VALUES('Geetha','Sreepada',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS1'),'F','geetha.sreepada@gmail.com','02-08-1994',4252410372,'Sammamish'),
                         ('Swati','Bhojwani',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS2'),'F','sarada.sripada@gmail.com','02-09-1994',425873720,'Washington'),
                         ('Amrutha','Gupta',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS3'),'F','amrutha.gupta.com','01-08-1990',6252410372,'Iowa'),
                         ('Maheswari','kanti',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS4'),'F','Mahi.kanti@gmail.com','02-09-1995',4282410372,'LeavenWorth'),
                         ('Yeshu','Gupta',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS5'),'F','yeshu.gupta@gmail.com','01-08-1990',4252490372,'Redmond'),
                         ('Sahithi','Sarabu',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS6'),'F','sahithi.sarabu@gmail.com','01-07-1994',7252410372,'Bellevue'),
                         ('Mahendra','Dhoni',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS7'),'M','mahendra.dhoni@gmail.com','01-08-1984',4352410372,'Canada'),
                         ('Keerthi','Spada',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS8'),'F','keerthi.spada@gmail.com','01-12-1974',4252460372,'kirkland'),
                         ('Virat','Kohli',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS9'),'M','virat.kohli@gmail.com','12-08-1990',4292410372,'Tokyo'),
                         ('Lakshmi','Veda',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS10'),'F','lakshmi.veda@gmail.com','02-11-1994',4269410372,'Seattle'),
						 ('Anushka','Sharma',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS10'),'F','anushka.sharma@gmail.com','02-11-1991',4269410372,'Portland'),
						 ('Sachin','Tendulkar',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS10'),'F','sachin.tendulkar@gmail.com','02-11-1992',4269410372,'Los Angeles'),
						 ('Lakshmi','Gajala',ENCRYPTBYKEY(KEY_GUID(N'TestSymmetricKey'),'PassTS10'),'F','lakshmi.gajala@gmail.com','02-11-1993',4269410372,'San Jose');

SELECT * FROM Person;

---Disease
INSERT INTO Disease (Name) 
values 
('Heart Disease'),
('HIV'),
('COPD'),
('Asthma'),
('Malaria'),
('Dengue'),
('Tuberculosis'),
('Measles'),
('Thyroid'),
('Diabetes');

SELECT * FROM Disease;

---SickPatient
Insert into dbo.SickPatient (PatientID,DiseaseID) 
values (1,1),
(1,2),
(1,3),
(2,2),
(2,3),
(2,4),
(3,6),
(3,8),
(3,9),
(4,10),
(11, 9),
(11,7);

SELECT * FROM SickPatient;

---Specialization
insert into [dbo].[Specialization] (SpecializationName) values ('Cardiology')
insert into [dbo].[Specialization] (SpecializationName) values ('Oncology')
insert into [dbo].[Specialization] (SpecializationName) values ('Neurology')
insert into [dbo].[Specialization] (SpecializationName) values ('Urology')
insert into [dbo].[Specialization] (SpecializationName) values ('Surgical Gastroenterology')
insert into [dbo].[Specialization] (SpecializationName) values ('Medical Gastroenterology')
insert into [dbo].[Specialization] (SpecializationName) values ('Obstetrics and Gynaecology')
insert into [dbo].[Specialization] (SpecializationName) values ('Bone Marrow Transplant')
insert into [dbo].[Specialization] (SpecializationName) values ('Anesthesiology')
insert into [dbo].[Specialization] (SpecializationName) values ('Family medicine')
insert into [dbo].[Specialization] (SpecializationName) values ('Emergency medicine')
insert into [dbo].[Specialization] (SpecializationName) values ('Radiology')
insert into [dbo].[Specialization] (SpecializationName) values ('Dermatology')
insert into [dbo].[Specialization] (SpecializationName) values ('Internal medicine')
insert into [dbo].[Specialization] (SpecializationName) values ('Medical genetics')

SELECT * FROM Specialization;

---HealthProvider
insert into HealthProvider (SpecializationID, HealthProviderID, Shifts) values 
(3, 7, 'First'),
(5, 7, 'Second'),
(14, 7, 'Third'),
(13, 5, 'Second'),
(15,5, 'Third'),
(9, 5, 'First'),
(11, 6, 'Third'),
(1, 6, 'First'),
(12, 6, 'Third'),
(6, 6, 'Second')

SELECT * FROM HealthProvider;

---HealthSupporter
INSERT dbo.HealthSupporter
VALUES
(1, 'Primary', 8,'02-11-2020'),
(1, 'Secondary',9,'06-13-2020'),
(2, 'Primary', 9, '10-11-2020'),
(2, 'Secondary',10,'11-19-2020'),
(3, 'Primary', 10 ,'02-15-2020'),
(3, 'Secondary', 8,'07-21-2020'),
(4, 'Primary', 12,'02-11-2019'),
(4, 'Primary', 13,'09-11-2020'),
(11, 'Secondary', 13,'10-30-2020'),
(11, 'Secondary', 12,'04-21-2020');

SELECT * FROM HealthSupporter;

---ActivityTracker
INSERT INTO ActivityTracker VALUES (1,'jogging','12-02-2007'),
                                    (1,'running','12-02-2008'),
                                    (2,'yoga','11-02-2005'),
                                    (3,'walking','10-02-2005'),
                                    (2,'running','11-01-2009'),
                                    (3,'jogging','12-02-2010'),
                                    (1,'yoga','12-02-2009'),
                                    (4,'walking','11-08-2007'),
                                    (2,'walking','10-02-2007'),
                                    (4,'walking','12-02-2015');

SELECT * FROM ActivityTracker;

---Appointment

INSERT INTO Appointment 
VALUES
(1,5,1,1,'2007-12-02 10:34:09 AM'),
(1,6,2,2,'2008-10-20 10:35:09 AM'),
(1,7,3,0,'2009-1-20 11:34:09 AM'),
(2,5,4,5,'2010-10-20 13:34:09 PM'),
(3,6,5,4,'2010-11-20 13:35:09 PM'),
(2,7,6,3,'2011-12-01 14:34:09 PM'),
(3,5,7,5,'2015-1-03 10:34:09 AM'),
(4,6,8,2,'2018-12-05 09:34:09 AM'),
(3,7,9,4,'2019-09-12 10:34:09 AM'),
(4,5,10,4,'2020-09-12 11:34:09 AM');

SELECT * FROM Appointment;

---Alert
INSERT INTO Alert 
VALUES 
(1,'OUTSIDE_LIMIT_ALERT', '11 is beyond the minimum 120 and the maximum 140 for 2-Systolic'),
(1,'SEVERITY_ALERT','Dry is not in acceptable values for 9-Cough'),
(2,'SEVERITY_ALERT','Dry is not in acceptable values for 9-Cough'),
(2,'OUTSIDE_LIMIT_ALERT','11 is beyond the minimum 120 and the maximum 140 for 2-Systolic'),
(3,'OUTSIDE_LIMIT_ALERT','11 is beyond the minimum 120 and the maximum 140 for 2-Systolic'),
(2,'SEVERITY_ALERT','Dry is not in acceptable values for 9-Cough'),
(2,'SEVERITY_ALERT','Dry is not in acceptable values for 9-Cough'),
(3,'OUTSIDE_LIMIT_ALERT','11 is beyond the minimum 120 and the maximum 140 for 2-Systolic'),
(4,'SEVERITY_ALERT','Dry is not normal, for 9-Cough'),
(4,'SEVERITY_ALERT','Dry is not normal, for 9-Cough');

SELECT * FROM Alert;

---HealthIndicator
INSERT INTO HealthIndicator (HealthIndicatorName, HealthIndicatorType) 
VALUES 
('Weight', 'RANGE'),
('Blood Pressure', 'RANGE'),
('Oxygen Saturation', 'RANGE'),
('Pain', 'ENUM'),
('Mood', 'ENUM'),
('Temperature', 'RANGE'),
('Sugar Level', 'RANGE'),
('Body Mass Index', 'RANGE'),
('Cough', 'ENUM'),
('Fatigue', 'ENUM'),
('Heart Rate', 'RANGE'),
('Hemoglobin', 'RANGE'),
('Ferritin', 'RANGE')

SELECT * FROM HealthIndicator;

---HealthIndicatorEnum

CREATE PROCEDURE dbo.InsertHealthIndicatorEnum 
	@hid INT,
	@param VARCHAR(30),
	@enum VARCHAR(30)
AS
BEGIN
	INSERT INTO dbo.HealthIndicatorEnum (HealthIndicatorID, ParamName, EnumValue )
	VALUES (@hid, @param, @enum)
END

DECLARE @h1 INT = 5;
DECLARE @p1 VARCHAR(30) = 'Mood';
DECLARE @e1 VARCHAR(30) = 'Happy';
EXEC InsertHealthIndicatorEnum @h1, @p1, @e1;
DECLARE @h2 INT = 5;
DECLARE @p2 VARCHAR(30) = 'Mood';
DECLARE @e2 VARCHAR(30) = 'Sad';
EXEC InsertHealthIndicatorEnum @h2, @p2, @e2;
DECLARE @h3 INT = 5;
DECLARE @p3 VARCHAR(30) = 'Mood';
DECLARE @e3 VARCHAR(30) = 'Angry';
EXEC InsertHealthIndicatorEnum @h3, @p3, @e3;
DECLARE @h4 INT = 5;
DECLARE @p4 VARCHAR(30) = 'Mood';
DECLARE @e4 VARCHAR(30) = 'Anxious';
EXEC InsertHealthIndicatorEnum @h4, @p4, @e4;


DECLARE @h5 INT = 4;
DECLARE @p5 VARCHAR(30) = 'Pain';
DECLARE @e5 VARCHAR(30) = 'None';
EXEC InsertHealthIndicatorEnum @h5, @p5,@e5;
DECLARE @h6 INT = 4;
DECLARE @p6 VARCHAR(30) = 'Pain';
DECLARE @e6 VARCHAR(30) = 'Mild';
EXEC InsertHealthIndicatorEnum @h6, @p6,@e6;
DECLARE @h7 INT = 4;
DECLARE @p7 VARCHAR(30) = 'Pain';
DECLARE @e7 VARCHAR(30) = 'Moderate';
EXEC InsertHealthIndicatorEnum @h7, @p7, @e7;
DECLARE @h8 INT = 4;
DECLARE @p8 VARCHAR(30) = 'Pain';
DECLARE @e8 VARCHAR(30) = 'Severe';
EXEC InsertHealthIndicatorEnum @h8, @p8, @e8;



DECLARE @h9 INT = 9;
DECLARE @p9 VARCHAR(30) = 'Cough';
DECLARE @e9 VARCHAR(30) = 'Dry';
EXEC InsertHealthIndicatorEnum @h9, @p9, @e9;
DECLARE @h10 INT = 9;
DECLARE @p10 VARCHAR(30) = 'Cough';
DECLARE @e10 VARCHAR(30) = 'Whooping';
EXEC InsertHealthIndicatorEnum @h10, @p10, @e10;
DECLARE @h11 INT = 9;
DECLARE @p11 VARCHAR(30) = 'Cough';
DECLARE @e11 VARCHAR(30) = 'Chesty';
EXEC InsertHealthIndicatorEnum @h11, @p11,@e11;
DECLARE @h12 INT = 9;
DECLARE @p12 VARCHAR(30) = 'Cough';
DECLARE @e12 VARCHAR(30) = 'None';
EXEC InsertHealthIndicatorEnum @h12, @p12,@e12;


DECLARE @h13 INT = 10;
DECLARE @p13 VARCHAR(30) = 'Fatigue';
DECLARE @e13 VARCHAR(30) = 'Transient';
EXEC InsertHealthIndicatorEnum @h13, @p13, @e13;
DECLARE @h14 INT = 10;
DECLARE @p14 VARCHAR(30) = 'Fatigue';
DECLARE @e14 VARCHAR(30) = 'Cumulative';
EXEC InsertHealthIndicatorEnum @h14, @p14, @e14;
DECLARE @h15 INT = 10;
DECLARE @p15 VARCHAR(30) = 'Fatigue';
DECLARE @e15 VARCHAR(30) = 'Circadian';
EXEC InsertHealthIndicatorEnum @h15, @p15, @e15;
DECLARE @h16 INT = 10;
DECLARE @p16 VARCHAR(30) = 'Fatigue';
DECLARE @e16 VARCHAR(30) = 'None';
EXEC InsertHealthIndicatorEnum @h16, @p16, @e16;

SELECT * from HealthIndicatorEnum;

---HealthIndicatorRange
INSERT INTO HealthIndicatorRange (HealthIndicatorID, ParamName, MinValue, MaxValue) 
VALUES 
(1, 'Weight', 120,200),
(2,'Systolic',120,140),
(2,'Diastolic',80,90),
(3,'Oxygen Saturation',90,99),
(6,'Temperature',97,99),
(7,'Sugar Level',140,199),
(8,'Healthy',18.5, 24.9),
(11,'Heart Rate',60,100),
(12, 'Hemoglobin',12.1, 17.2),
(13, 'Ferritin',20, 250)

SELECT * from HealthIndicatorRange;

---DiseaseHealthIndicator
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (1,1);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (2,1);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (1,2);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (4,2);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (3,3);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (6,3);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (1,4);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (6,4);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (4,5);
Insert into dbo.DiseaseHealthIndicator (HealthIndicatorID,DiseaseID) values (2,5);

SELECT * FROM DiseaseHealthIndicator;

---PatientSpecificHIRange
INSERT dbo.PatientSpecificHIRange
VALUES
(1, 1, 'Weight', 120, 200),
(1, 2, 'Diastolic', 80,90),
(1, 3, 'Oxygen Saturation', 90, 99),
(2, 3, 'Oxygen Saturation', 90, 99),
(2, 6, 'Temperature', 97, 99),
(1, 6, 'Temperature', 97, 99),
(1, 2, 'Systolic', 110, 130),
(1, 7, 'Sugar Level', 140, 199),
(1, 8, 'Healthy', 18.5, 24.9),
(1, 11, 'Heart Rate', 100,160)

SELECT * FROM PatientSpecificHIRange;


---PatientSpecificHIEnum
INSERT dbo.PatientSpecificHIEnum
VALUES
(1, 4, 'Pain','None'),
(1, 4, 'Pain','Mild'),
(2, 4,'Pain', 'None'),
(2, 4, 'Pain','Mild'),
(2, 4, 'Pain','Moderate'),
(1, 5,'Mood', 'Happy'),
(1, 5,'Mood', 'Angry'),
(4, 9, 'Cough','None'),
(4, 9, 'Cough','Dry'),
(3, 10, 'Fatigue','Transient'),
(3, 10, 'Fatigue','None')

SELECT * FROM PatientSpecificHIEnum;

---TestRanges
INSERT INTO dbo.TestRanges (TestName, MinValue, MaxValue)
values
('RBC', 4.5, 9.0),
('WBC', 2.5, 8.0),
('Hemoglobin', 3, 15),
('ESR', 1, 6),
('PLT', 128, 1024),
('MCV', 40, 120),
('MHC', 10, 60),
('Ferritin', 5, 60),
('TSH', 1.2, 4.5),
('HDL', 40, 60),
('LDL', 10, 160)

SELECT * FROM TestRanges;

---LabReport
insert into [dbo].[LabReport] (PatientID,TestID,TestResult) 
values 
(1, 1, 3.3),
(1, 2, 6.7),
(1, 3, 12),
(1, 4, 2),
(1, 5, 256),
(1, 6, 83),
(2, 7, 28),
(2, 1, 3.4),
(2, 2, 6.8),
(2, 3, 13),
(3, 4, 3),
(4, 5, 257),
(4, 6, 84),
(3, 7, 29)

SELECT * FROM LabReport;


---Observation
INSERT dbo.Observation
VALUES 
(1, 1, 'Weight', 120, '18:20:11', '2017-09-09'),
(1, 2, 'Diastolic', 56, '18:21:11', '2017-10-09'),
(1, 3, 'Oxygen Saturation', 98, '19:20:11', '2018-09-09'),
(2, 3, 'Oxygen Saturation', 98, '18:20:11', '2017-09-10'),
(1, 6, 'Temperature', 99,'20:20:11', '2009-09-09'),
(2, 6, 'Temperature', 99, '18:20:10', '2007-09-09'),
(1, 7, 'Sugar Level', 150, '18:23:11', '2017-08-09'),
(2, 7, 'Sugar Level', 160, '19:20:11', '2016-09-09'),
(1, 8, 'Healthy', 25, '18:10:11', '2017-09-10'),
(1, 11, 'Heart Rate', 120, '18:20:11', '2008-09-09')

SELECT * FROM Observation;



-----------------------------------------------------------------------------------------------------------------

--VIEWS
--1
CREATE VIEW PatientLabReport
AS
SELECT p.FirstName,p.LastName, p.Gender, p.DOB, p.Email, p.Age, p.Phone, 
	(SELECT FirstName FROM Person WHERE PersonID = h.HealthSupporterID) AS HealthSupporterFirstName,
	(SELECT LastName FROM Person WHERE PersonID = h.HealthSupporterID) AS HealthSupporterLastName, 
	h.AuthorizationDate, h.HealthSupporterType,(SELECT TestName FROM TestRanges WHERE TestID = l.TestID) AS TestName, l.TestResult, l.TestAnalysis
FROM dbo.Person p 
JOIN dbo.LabReport l
ON p.PersonID = l.PatientID
JOIN dbo.HealthSupporter h 
ON p.PersonID = h.PatientID

SELECT * FROM PatientLabReport;

DROP VIEW PatientLabReport;

--2
CREATE VIEW PatientObservation
WITH ENCRYPTION, SCHEMABINDING
AS
SELECT p.FirstName, p.LastName, p.Gender, p.Age, p.DOB, 
	o.ParamName AS HealthIndicatorMeasured, o.ObservationTime, o.ObservationValue, o.RecordedDate
FROM dbo.Person p 
JOIN dbo.Observation o 
ON p.PersonID = o.PatientID

SELECT * FROM PatientObservation;

DROP VIEW PatientObservation;

---3
CREATE VIEW HorizontalReports
AS
WITH temp 
as 
(SELECT p.PersonID 
AS PatientID,p.FirstName, p.LastName, STUFF((SELECT ', '+ RTRIM(CAST((SELECT TestName FROM TestRanges WHERE TestID = l.TestID) AS VARCHAR)) FROM dbo.LabReport l
WHERE l.PatientID = p.PersonID for XML PATH('')), 1, 2, '') AS [Patient's Lab Tests] FROM dbo.Person p)
SELECT t.PatientID, t.FirstName, t.LastName, t.[Patient's Lab Tests] FROM temp t WHERE [Patient's Lab Tests] IS NOT NULL 

SELECT * FROM HorizontalReports

DROP VIEW HorizontalReports


---4
CREATE VIEW MaximumDiseaseOccurance
AS
SELECT TOP 2147483647 d.Name, COUNT(s.PatientID) 
AS MaximumOccurances 
FROM SickPatient s 
JOIN Disease d 
ON s.DiseaseID = d.DiseaseID 
GROUP BY d.Name 
ORDER BY COUNT(s.PatientID) DESC

SELECT * FROM MaximumDiseaseOccurance

DROP VIEW MaximumDiseaseOccurance


---5
CREATE VIEW MostTestsTaken
AS
SELECT TOP 2147483647 t.TestName, COUNT(l.PatientID) AS Frequency
FROM LabReport l 
JOIN TestRanges t 
ON l.TestID = t.TestID 
GROUP BY t.TestName 
ORDER BY COUNT(l.PatientID) DESC

SELECT * FROM MostTestsTaken

DROP VIEW MostTestsTaken

---------------------------------------------------------------------------------------------------------------------------------

---Trigger to generate alert on Insert to observation
CREATE TRIGGER Generate_Alert ON dbo.Observation
FOR  INSERT
AS 
BEGIN
	DECLARE @PatientID INT = (SELECT PatientID FROM inserted);
	DECLARE @HI INT = (SELECT HealthIndicatorID FROM inserted);
	DECLARE @Param VARCHAR(30) = (SELECT ParamName FROM inserted);
	DECLARE @Min FLOAT;
	DECLARE @Max FLOAT;
	DECLARE @ObservationValue VARCHAR(30) = (SELECT ObservationValue FROM inserted);
	DECLARE @NumPatientSpecificRangeValues INT = (SELECT COUNT(*) FROM PatientSpecificHIRange WHERE PatientID = @PatientID AND HealthIndicatorID = @HI);
	DECLARE @NumPatientSpecificEnumValues INT = (SELECT COUNT(*) FROM PatientSpecificHIEnum WHERE PatientID = @PatientID AND HealthIndicatorID = @HI);
	DECLARE @NumRegularRangeValues INT = (SELECT COUNT(*) FROM HealthIndicatorRange WHERE HealthIndicatorID = @HI);
	DECLARE @NumRegularEnumValues INT = (SELECT COUNT(*) FROM HealthIndicatorEnum WHERE HealthIndicatorID = @HI);
	
	IF @NumPatientSpecificRangeValues > 0
	BEGIN
		PRINT N'In patient specific range values';
		SELECT @Min = MinValue,
		@Max = MaxValue
		FROM PatientSpecificHIRange WHERE PatientID = @PatientID AND HealthIndicatorID = @HI AND ParamName = @Param;
		IF(CAST(@ObservationValue AS INT) < @Min OR CAST(@ObservationValue AS INT) > @Max)
		BEGIN
			PRINT N'Creating alert from patient specific range values';
			INSERT INTO Alert VALUES(@PatientID,'OUTSIDE_LIMIT_ALERT', 
			CONCAT(@ObservationValue, ' is beyond the minimum ', @Min, ' and the maximum ', @Max, ' for ', @HI, '-',@Param));
		END
	END
	ELSE 
		IF @NumRegularRangeValues > 0
		BEGIN
			PRINT N'In general range values';
			SELECT @Min = MinValue,
			@Max = MaxValue
			FROM HealthIndicatorRange WHERE HealthIndicatorID = @HI AND ParamName = @Param;
			IF(CAST(@ObservationValue AS INT) < @Min OR CAST(@ObservationValue AS INT) > @Max)
			BEGIN
				PRINT N'Creating alert from general range values'
				INSERT INTO Alert VALUES(@PatientID,'OUTSIDE_LIMIT_ALERT',
				CONCAT(@ObservationValue, ' is beyond the minimum ', @Min, ' and the maximum ', @Max, ' for ', @HI, '-',@Param));
			END
		END
	ELSE
		IF @NumPatientSpecificEnumValues > 0
		BEGIN
			PRINT N'In patient specific enum values';
			--- Check if there's a patient specific enum value for which alert should not be generated
			DECLARE @count INT = (SELECT count(*) FROM PatientSpecificHIEnum WHERE PatientID = @PatientID AND HealthIndicatorID = @HI AND EnumValue = @ObservationValue);
			IF(@count = 0)
			BEGIN
				PRINT N'Creating alert from patient specific enum values'
				INSERT INTO Alert VALUES(@PatientID, 'SEVERITY_ALERT',
				CONCAT(@ObservationValue, ' is not in acceptable values for ', @HI, '-',@Param));
			END
		END
	ELSE
		IF @NumRegularEnumValues > 0
		BEGIN
			PRINT N'In general enum values';
			IF(@ObservationValue <> 'None' AND @ObservationValue <> 'Happy')
			BEGIN
				PRINT N'Creating alert from general enum values'
				INSERT INTO Alert VALUES(@PatientID, 'SEVERITY_ALERT',
				CONCAT(@ObservationValue, ' is not normal, for ', @HI, '-',@Param));
			END
		END
END

DROP TRIGGER Generate_Alert 

INSERT dbo.Observation
VALUES 
(1, 2, 'Systolic', 1000, '18:20:11', '2020-11-29')

INSERT dbo.Observation
VALUES 
(3, 2, 'Systolic', 11, '18:20:11', '2020-11-29')

INSERT dbo.Observation
VALUES 
(4, 9, 'Cough', 'Whooping', '18:20:11', '2020-11-29')

INSERT dbo.Observation
VALUES 
(4, 9, 'Cough', 'Dry', '18:20:11', '2020-11-29')

INSERT dbo.Observation
VALUES 
(1, 9, 'Cough', 'None', '18:20:11', '2020-11-29')
			
			

SELECT * FROM Observation;
SELECT * FROM Alert;
