--Init Tables:

CREATE TABLE IF NOT EXISTS Employers (
	employer_ID serial PRIMARY KEY,
	full_name Varchar(64) NOT NULL,
	joining_date date NOT NULL,
	current_position varchar(64),
	department varchar(64) 
		CHECK (department IN (	'Finance',
								'HR', 
								'Travel', 
								'Sofware and Data', 
								'IT Support')),
	assigned_project varchar(64)
);  

----------------------------------------

CREATE TABLE IF NOT EXISTS Services (
	software_ID serial PRIMARY KEY,
	name varchar(64),
	category char CHECK (category IN ('A', 'B', 'C', 'D')),
	SIZE int,
	number_of_installments int DEFAULT 0
);

----------------------------------------

CREATE TABLE IF NOT EXISTS Service_Requests (
	request_ID serial PRIMARY KEY,
	employer_ID int REFERENCES Employers(employer_ID) NOT NULL,
	software_ID int REFERENCES Services(software_ID) NOT NULL,
	request_start_date  date NOT NULL,
	request_close_date  date,
	status varchar(64) CHECK (status IN ('incomplete', 'complete', 'invalid'))
);


CREATE OR REPLACE FUNCTION increment_number_of_service_installments()
	RETURNS TRIGGER
	AS $$
		BEGIN
			UPDATE services SET number_of_installments = number_of_installments + 1
				WHERE software_id = NEW.software_ID;
			RETURN NEW;
		END;
	$$
	LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER on_new_request
	BEFORE INSERT
	ON Service_Requests 
	FOR EACH ROW 
		EXECUTE PROCEDURE increment_number_of_installments();

----------------------------------------------------------------
--Test:
	
INSERT INTO employers (full_name, joining_date) VALUES ('John Doe', '2022-06-20');
INSERT INTO employers (full_name, joining_date) VALUES ('Jane Doe', '2022-06-20');
SELECT * FROM employers;

INSERT INTO services (name) VALUES ('My service 01');
INSERT INTO services (name) VALUES ('My service 02');
SELECT * FROM services;	
	
INSERT INTO Service_Requests (employer_id, software_ID, request_start_date) 
	VALUES (1, 1, '2022-06-29');
INSERT INTO Service_Requests (employer_id, software_ID, request_start_date) 
	VALUES (2, 2, '2022-06-30');
SELECT * FROM Service_Requests;
	
UPDATE Service_Requests SET status = 'invalid' WHERE request_ID = 6;
SELECT * FROM Service_Requests;

---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION decrement_number_of_service_installments()
	RETURNS TRIGGER
	AS $do$
		BEGIN
			IF ('invalid' = NEW.status AND ('invalid' != OLD.status OR OLD.status IS NULL)) THEN
				UPDATE services SET number_of_installments = number_of_installments - 1
					WHERE software_id = NEW.software_ID;
			END IF;
			RETURN NEW;
		END;
	$do$
	LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER on_invalidation
	BEFORE UPDATE
	ON Service_Requests
	FOR EACH ROW 
		EXECUTE PROCEDURE decrement_number_of_service_installments();


