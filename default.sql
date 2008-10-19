/* Default SQLite database for Glucose application
   Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>
*/
/*
CREATE TABLE GlucoseSettings
( 'key' TEXT,
  'value' TEXT
);

INSERT INTO GlucoseSettings VALUES ('DatabaseSchemaVersion', '0');
-- INSERT INTO GlucoseSettings VALUES ('CategoriesVersion', '0');
-- INSERT INTO GlucoseSettings VALUES ('InsulinTypesVersion', '0');
*/
CREATE TABLE InsulinTypes
( 'typeID' INTEGER PRIMARY KEY AUTOINCREMENT,
  'sequence' INTEGER UNIQUE,
  'fullName' TEXT,
  'shortName' TEXT
);

-- Default Insulin Types
INSERT INTO InsulinTypes(sequence, shortName) VALUES (0, 'Aspart');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (1, 'Detemir');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (2, 'Glargine');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (3, 'Glulisine');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (4, 'Lispro');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (5, 'NPH');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (6, 'Regular');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (7, 'Lente');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (8, 'UltraLente');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (9, '70/30');
INSERT INTO InsulinTypes(sequence, shortName) VALUES (10, '50/50');

CREATE TABLE LogEntryCategories
( 'categoryID' INTEGER PRIMARY KEY AUTOINCREMENT, 
  'sequence' INTEGER UNIQUE,
  'name' TEXT
);

-- Default Categories
INSERT INTO LogEntryCategories(sequence, name) VALUES (0, 'Breakfast');
INSERT INTO LogEntryCategories(sequence, name) VALUES (1, 'Lunch');
INSERT INTO LogEntryCategories(sequence, name) VALUES (2, 'Dinner');
INSERT INTO LogEntryCategories(sequence, name) VALUES (3, 'After Breakfast');
INSERT INTO LogEntryCategories(sequence, name) VALUES (4, 'After Lunch');
INSERT INTO LogEntryCategories(sequence, name) VALUES (5, 'After Dinner');
INSERT INTO LogEntryCategories(sequence, name) VALUES (6, 'Bedtime');

CREATE TABLE localLogEntries
( 'ID' INTEGER PRIMARY KEY AUTOINCREMENT,
  'timestamp' INTEGER,		-- UNIX time
  'glucose' REAL,
  'glucoseUnits' INTEGER,	-- 0=mg/dL 1=mmol/L
  'categoryID' INTEGER,		-- foreign key
  'dose0' INTEGER,
  'dose1' INTEGER,
  'typeID0' INTEGER,		-- foreign key
  'typeID1' INTEGER,		-- foreign key
  'note' TEXT
);

-- Test entries
/*
INSERT INTO "localLogEntries" VALUES(1,1220113636,94.0,0,1,10,9,6,1,NULL);
INSERT INTO "localLogEntries" VALUES(2,1220134162,187.0,0,2,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "localLogEntries" VALUES(3,1220145732,177.0,0,3,10,7,6,1,NULL);
INSERT INTO "localLogEntries" VALUES(4,1220200509,151.0,0,1,10,8,6,1,NULL);
INSERT INTO "localLogEntries" VALUES(5,1220227324,88.0,0,5,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "localLogEntries" VALUES(6,1220230004,92.0,0,3,10,7,6,1,NULL);
INSERT INTO "localLogEntries" VALUES(7,1220249914,101.0,0,7,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "localLogEntries" VALUES(8,1220302462,182.0,0,1,10,8,6,1,NULL);
*/