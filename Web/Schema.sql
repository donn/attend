-- Database - attend - SQL Script
-- Naming Conventions
-- -- If the fields name starts with Is and is of type char(1), then it is equivalent to boolean, and accepts only values Y and N.
-- -- A field should not be named YX in Table Y, X is enough.
-- -- If a field is named X in Table Y, then as a foreign key it's named YX.
-- -- In constraint names, they're abbreviated if the name is too long. Otherwise, y_x_fk/ck/uk

Drop database attend;
Create database attend;
Use attend;

Create table Course
(
    ID int AUTO_INCREMENT,
    Title varchar(64) not null,
    Code varchar(8) null,
    Section varchar(2) null,    
    MissableEvents int null,
    Primary Key (ID)
);

Create table Event -- Abstract event - if not special, count it as a schedule
(
    ID int AUTO_INCREMENT,
    CourseID int not null,
    Title text not null,
    IsSpecial char(1) not null,
    TypicalStartTime time,
    constraint event_isspecial_ck check ((IsSpecial = 'Y') or (IsSpecial = 'N')),
    constraint event_courseid_fk Foreign Key (CourseID) references Course(ID) on delete cascade on update restrict,
    Primary Key (ID)
);

-- @Deprecated
Create table Day -- Dictionary for Days
(
    DayCharacter char(1), -- Breaking the convention, yes, but MySQL has 'Character' as a keyword apparently
    Description text,
    Primary Key (DayCharacter)
);

-- @Deprecated
Insert into Day values
    ('U', 'Sunday'),
    ('M', 'Monday'),
    ('T', 'Tuesday'),
    ('W', 'Wednesday'),
    ('R', 'Thursday'),
    ('F', 'Friday'),
    ('S', 'Saturday');

-- @Deprecated
Create table Event_TypicalDays
(
    EventID int,
    DayCharacter char(1),
    constraint etd_eventid_fk Foreign Key (EventID) references Event(ID) on delete cascade on update restrict,
    constraint etd_daycharacter_fk Foreign Key (DayCharacter) references Day(DayCharacter) on delete restrict on update restrict,
    Primary Key (EventID, DayCharacter)
);

Create table EventInstance -- An actual, physical event
(
    ID int AUTO_INCREMENT,
    EventID int not null,
    StartTime timestamp not null,
    QRString varchar(6) null, -- one generated on instance. Whenever the professor closes the QR Code display, regenerate
    IsQRCodeActive char(1) not null, -- "where IsQRCodeActive = 'Y'" when trying to attend
    IsLate char(1) not null, -- If true, any attendances are marked late
    constraint ei_qrstring_uk Unique (QRString),
    constraint ei_isqrcodeactive_ck check ((IsQRCodeActive = 'Y') or (IsQRCodeActive = 'N')),
    constraint ei_islate_ck check ((IsLate = 'Y') or (IsLate = 'N')),
    constraint ei_eventid_fk Foreign Key (EventID) references Event(ID) on delete cascade on update restrict,
    Primary Key (ID)
);

Create view EventInstanceExpanded as
(
    Select e.CourseID as CourseID, i.EventID as EventID, i.ID as ID, e.Title as Title, e.IsSpecial as IsSpecial, UNIX_TIMESTAMP(i.StartTime) as UnixStartTime, i.StartTime as StartTime, i.QRString as QRString, i.IsQRCodeActive as IsQRCodeActive, i.IsLate as IsLate
    from Event e, EventInstance i
    where e.ID = i.EventID
);

-- Users without confirmed emails can be overwritten after LastLoggedIn > 24 hours (24 * 60 * 60 seconds)
Create table User
(
    ID int AUTO_INCREMENT,
    FirstName varchar(35) not null,
    LastName varchar(35) not null,
    Password text not null,
    RegistrationEmail varchar(255), -- If null, email unconfirmed
    IsVerifiedProfessor char(1) not null,
    LastLoggedIn numeric(19) not null, -- In UNIX time    
    constraint user_ivp_ck check (IsVerifiedProfessor = 'Y' or IsVerifiedProfessor = 'N'),
    constraint user_registrationemail_uk unique (RegistrationEmail),
    Primary Key (ID)
);

Create table DropRequest
(
    UserID int,
    CourseID int,
    ConfirmationString varchar(13),
    constraint dr_userid_fk Foreign Key (UserID) references User(ID) on delete cascade on update restrict,
    constraint dr_courseid_fk Foreign Key (CourseID) references Course(ID) on delete cascade on update restrict,
    constraint dr_cs_fk Unique (ConfirmationString),
    Primary Key (UserID, CourseID)
);

Create table EmailConfirmation
(
    Email varchar(255),
    Code varchar(128) not null,
    UserID int not null,
    RegisteredOn numeric(19) not null, -- In UNIX time, for request timeouts; PHP triggered on 'late' requests
    constraint ec_userid_uk Unique (UserID),
    constraint ec_userid_fk Foreign Key (UserID) references User(ID) on delete cascade on update restrict,
    constraint ec_code_uk Unique (Code),
    Primary Key (Email)
);

Create table Attendance
(
    EventInstanceID int not null,
    UserID int not null,
    IsLate char(1) not null,
    constraint attendance_islate_ck check ((IsLate = 'Y') or (IsLate = 'N')),
    constraint attendance_eid_fk Foreign Key (EventInstanceID) references EventInstance(ID) on delete cascade on update restrict,
    constraint attendance_uid_fk Foreign Key (UserID) references User(ID) on delete cascade on update restrict,
    Primary Key (EventInstanceID, UserID)
);

Create table DegreeOfInvolvement -- Dictionary for Ranks
(
    Code char(2),
    Description text, -- The description is only for the API implementer's convenience- let the frontends do the work.
    Primary Key (Code)
);

Insert into DegreeOfInvolvement values
    ('P', 'Professor'),
    ('ST', 'Senior TA'),
    ('TA', 'TA'),
    ('S', 'Student');

Create table Involvement
(
    UserID int,
    CourseID int,
    DoICode char(2) not null,
    ExcusedAbsences int not null,
    Privilege int not null,
    -- Privilege Dictionary
    -- -- 0 -> Cannot do anything
    -- -- 1 -> Can create and instantiate //special// events
    -- -- 2 and higher -> Full privilege to delete course, excuse privilege 0 attendance, create and instantiate special and nonspecial events
    constraint inv_userid_fk Foreign Key (UserID) references User(ID) on delete cascade on update restrict,
    constraint inv_courseid_fk Foreign Key (CourseID) references Course(ID) on delete cascade on update restrict,
    constraint inv_doicode_fk Foreign Key (DoICode) references DegreeOfInvolvement(Code),
    Primary Key (UserID, CourseID)
);

Create table StudentInAbsentia
(
    Email varchar(255),
    CourseID int,
    constraint iia_courseid_fk Foreign Key (CourseID) references Course(ID) on delete cascade on update restrict,
    Primary Key(Email, CourseID)
)