--B. 
--Transformation function
CREATE OR REPLACE FUNCTION month_name(payment_date TIMESTAMP)
RETURNS VARCHAR(10)
LANGUAGE plpgsql
AS
$$
DECLARE month_return VARCHAR(10);
BEGIN
	month_return = TO_CHAR(payment_date, 'month');
	RETURN month_return;
END;
$$;

--Test for transformation function
SELECT month_name('2024-10-28');

--drops the tables if they are already created
DROP TABLE summary_table;
DROP TABLE detailed_table;

--C.
--Detailed table
CREATE TABLE detailed_table (
	store_Id INT,
	staff_Id INT,
	payment_Id INT,
	amount FLOAT,
	payment_date TIMESTAMP,
	PRIMARY KEY (payment_Id)
);
	
--Summary Table
CREATE TABLE summary_table (
	store_Id INT,
	month VARCHAR(10),
	total_sales INT,
	PRIMARY KEY (store_Id, month),
	FOREIGN KEY (store_id) REFERENCES store (store_Id)
);

--Test to make sure empty tables were created
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

--D.
--Extract Raw Data for detailed table
INSERT INTO detailed_table
SELECT store.store_id, staff.staff_id, payment.payment_id, payment.amount, payment.payment_date
FROM store
INNER JOIN staff
	ON store.store_id = staff.store_id
INNER JOIN payment
	ON staff.staff_id = payment.staff_id
ORDER BY 2,3,5;

--Extra row to add to detailed table
INSERT INTO detailed_table
VALUES (1,1,123456,10.99,NOW());


--E.
--Trigger function
CREATE OR REPLACE FUNCTION trigger_function()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS
$$
BEGIN
DELETE FROM summary_table;
INSERT INTO summary_table
	SELECT store_id, month_name(payment_date) AS month, SUM(amount) AS total_sales
	FROM detailed_table
	GROUP BY store_id, month
	ORDER BY 1,2;
RETURN NEW;
END;
$$;

--Delete if trigger exists
DROP TRIGGER IF EXISTS update_summary_table ON detailed_table;

CREATE TRIGGER update_summary_table AFTER INSERT ON detailed_table
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_function();

--F.
--Stored Procedure
CREATE PROCEDURE refresh_both_tables()
LANGUAGE plpgsql
AS
$$
BEGIN
DELETE FROM detailed_table;
DELETE FROM summary_table;

INSERT INTO detailed_table
SELECT store.store_id, staff.staff_id, payment.payment_id, payment.amount, payment.payment_date
FROM store
INNER JOIN staff
	ON store.store_id = staff.store_id
INNER JOIN payment
	ON staff.staff_id = payment.staff_id
ORDER BY 2,3,5;

RETURN;
END;
$$;

DROP PROCEDURE refresh_both_tables;
CALL refresh_both_tables();

SELECT * FROM detailed_table;
SELECT * FROM summary_table;