--Assessment 2

--1 select Artists and albums:

SELECT ar."Name" AS "Artist Name", COALESCE (al."Title", 'No album') AS "Album Name" 
	FROM "Artist" AS ar LEFT OUTER JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId"
	ORDER BY ar."Name";
	
--------------------------------------------------

--2 select At least one album:

SELECT ar."Name" AS "Artist Name", al."Title"  AS "Album Name"
	FROM "Artist" AS ar JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId" 
	ORDER BY al."Title"  DESC;
	
-------------------------------------------------

-- 3 Have no album:

SELECT "Name" AS "Artist Name" FROM "Artist"
	WHERE "ArtistId" NOT IN (SELECT "ArtistId" FROM "Album")
	ORDER BY "Name";

------------------------------------------------

-- 4 No of albums:

SELECT ar."Name" AS "Artist name", COUNT(al."ArtistId") AS "No of albums"
	FROM "Artist" AS ar LEFT OUTER JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId"
	GROUP BY ar."Name"
	ORDER BY "No of albums" DESC, ar."Name" ASC;

-----------------------------------------------

-- 5 10 or more albums:

SELECT ar."Name" AS "Artist name", COUNT(al."ArtistId") AS "No of albums"
	FROM "Artist" AS ar JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId"
	GROUP BY ar."Name"
	HAVING COUNT(al."ArtistId") >= 10
	ORDER BY "No of albums" DESC, ar."Name" ASC;

---------------------------------------------

-- 6 TOP 3 artists:
SELECT ar."Name" AS "Artist name", COUNT(al."ArtistId") AS "No of albums"
	FROM "Artist" AS ar JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId"
	GROUP BY ar."Name"
	ORDER BY "No of albums" DESC
	LIMIT 3;

------------------------------------------------

-- 7 Santana album tracks:

SELECT ar."Name" AS "Artist name", al."Title" AS "Album Title", tr."Name" AS "Track"
	FROM "Artist" AS ar 
		JOIN "Album" AS al ON ar."ArtistId" = al."ArtistId"
		JOIN "Track" AS tr ON al."AlbumId" = tr."AlbumId"
	WHERE UPPER(ar."Name") LIKE UPPER('%Santana%')
	ORDER BY tr."TrackId";

-----------------------------------------

-- 8 Employees and managers:

SELECT 	e."EmployeeId" AS "Employee ID", 
		(e."FirstName" || ' ' || e."LastName") AS "Employee Name",
		e."Title" AS "Employee Title",
		m."EmployeeId" AS "Manager ID",
		(m."FirstName" || ' ' || m."LastName") AS "Manager Name",
		m."Title" AS "Manager Title"
FROM "Employee" AS e JOIN "Employee" AS m ON e."ReportsTo" = m."EmployeeId"
ORDER BY e."EmployeeId";

-------------------------------------------

-- 9 TOP Employees view:

CREATE OR REPLACE VIEW top_employees 
	AS
	(SELECT e."EmployeeId" AS "emp_id",
	(e."FirstName" || ' ' || e."LastName") AS "emp_name",
	count(c."CustomerId") AS "cust_count"
	FROM "Employee" AS e JOIN "Customer" AS c ON e."EmployeeId" = c."SupportRepId"
	GROUP BY e."EmployeeId"
	);

-- Best employee

SELECT te.emp_name AS "Employee Name", (c."FirstName" || ' ' || c."LastName") AS "Customer Name"
	FROM top_employees AS te JOIN "Customer" AS c ON te.emp_id = c."SupportRepId"
	WHERE te.cust_count = (SELECT MAX(cust_count) FROM top_employees)
	ORDER BY "Customer Name";

-------------------------------------------

-- 10 New MP3 media type:

INSERT INTO "MediaType" ("MediaTypeId", "Name")
	VALUES ((SELECT MAX("MediaTypeId") FROM "MediaType") + 1, 'MP3');

--Trigger for preventing insertion of track with MP3 type:

CREATE FUNCTION prevent_mp3()
	RETURNS TRIGGER
	AS
	$$
		BEGIN
			IF (NEW."MediaTypeId" = (SELECT "MediaTypeId" FROM "MediaType" WHERE "Name" = 'MP3')) THEN 
				RAISE EXCEPTION 'Trying to insert track with MP3 media type!';
			END IF;
			RETURN NEW;
		END;		
	$$
	LANGUAGE plpgsql;

CREATE TRIGGER on_track_insert
	BEFORE INSERT ON "Track"
	FOR EACH ROW
		EXECUTE PROCEDURE prevent_mp3();

-- TEST:
	
INSERT INTO "Track" ("TrackId", "Name", "MediaTypeId", "Milliseconds", "UnitPrice") 
	VALUES ((SELECT MAX("TrackId") FROM "Track") + 1,
		'My demo track01',
		(SELECT "MediaTypeId" FROM "MediaType" WHERE "Name" = 'MP3'),
		2000,
		3500
	);

-------------------------------------------------------------

-- 11 track Log:

CREATE TABLE IF NOT EXISTS tracks_audit_log (
	operation varchar(6),
	datetime timestamp,
	username varchar(64),
	old_value text,
	new_value text
);

CREATE OR REPLACE FUNCTION track_audit_func()
	RETURNS TRIGGER
	AS $$
		BEGIN
			INSERT INTO tracks_audit_log (operation, datetime, username, old_value, new_value) 
				VALUES(TG_OP, NOW(), USER, OLD, NEW);
			RETURN NEW;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE OR REPLACE TRIGGER track_audit
	BEFORE UPDATE OR INSERT OR DELETE ON "Track"
	FOR EACH ROW
	EXECUTE PROCEDURE track_audit_func();


-- TEST:
	
INSERT INTO "Track" ("TrackId", "Name", "MediaTypeId", "Milliseconds", "UnitPrice") 
	VALUES ((SELECT MAX("TrackId") FROM "Track") + 1,
		'My demo track01',
		(SELECT "MediaTypeId" FROM "MediaType" WHERE "Name" = 'AAC audio file'),
		2000,
		3500
	);

UPDATE "Track" SET "UnitPrice" = 3700 
	WHERE "Name" = 'My demo track01';

DELETE FROM "Track"
	WHERE "Name" = 'My demo track01';
--------------------------------------------------------------



