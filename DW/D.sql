USE BikeStores
go
-- Drop the schema if it exists
IF EXISTS (SELECT schema_id FROM sys.schemas WHERE name = 'dwh')
BEGIN
    DROP SCHEMA dwh;
END;
GO

CREATE SCHEMA dwh;
go

CREATE TABLE dwh.dim_product (
  product_id INT NOT NULL, 
  product_name VARCHAR(255) NOT NULL,
  list_price DECIMAL(10, 2) NOT NULL,
  model_year SMALLINT NOT NULL,
  brand_name VARCHAR(255),
  category_name VARCHAR(255),
);

INSERT INTO dwh.dim_product (product_id, product_name, list_price, model_year, brand_name, category_name)
SELECT 
  p.product_id,
  p.product_name,
  p.list_price,
  p.model_year,
  b.brand_name,
  c.category_name
FROM production.products AS p
JOIN production.brands AS b ON p.brand_id = b.brand_id
JOIN production.categories AS c ON p.category_id = c.category_id;

ALTER TABLE dwh.dim_product
ADD CONSTRAINT dim_product_pk PRIMARY KEY (product_id);

-- ===================
-- Customer Dimension
-- ===================
CREATE TABLE dwh.dim_customer(
	customer_id INT NOT NULL,
	first_name VARCHAR (255) NOT NULL,
	last_name VARCHAR (255) NOT NULL,
	phone VARCHAR (25),
	email VARCHAR (255) NOT NULL,
	street VARCHAR (255),
	city VARCHAR (50),
	state VARCHAR (25),
	zip_code VARCHAR (5)
);

INSERT INTO dwh.dim_customer (customer_id, first_name, last_name, phone, email, street, zip_code, state)
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	COALESCE (c.phone, 'Unknown') AS phone,
	COALESCE (c.email, 'Unknown') AS email,
	COALESCE (c.street, 'Unknown') AS street,
	COALESCE (c.zip_code, 'Unknown') AS zip_code,
	COALESCE (c.state, 'Unknown') AS state
FROM sales.customers AS c;

ALTER TABLE dwh.dim_customer
ADD CONSTRAINT dim_customer_pk PRIMARY KEY (customer_id)
;
-- ================
-- Store Dimension
-- ================
CREATE TABLE dwh.dim_store (
	store_id INT NOT NULL,
	store_name VARCHAR (255) NOT NULL,
	phone VARCHAR (25),
	email VARCHAR (255),
	street VARCHAR (255),
	city VARCHAR (255),
	zip_code VARCHAR (5)
);

INSERT INTO dwh.dim_store(store_id, store_name, phone, email, street, city, zip_code)
SELECT 
	s.store_id, 
	s.store_name, 
	COALESCE (s.phone, 'Unknown') AS phone,
	COALESCE (s.email, 'Unknown') AS email, 
	s.street, 
	s.city, 
	s.zip_code
FROM sales.stores AS s

ALTER TABLE dwh.dim_store 
ADD CONSTRAINT dim_store_pk PRIMARY KEY (store_id)
;

-- ================
-- Staff Dimension
-- ================
CREATE TABLE dwh.dim_staff (
  staff_id INT NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  phone VARCHAR(255),
  email VARCHAR(255),
  active BIT NOT NULL,
  manager_id INT,
  manager_first_name VARCHAR(255),
  manager_last_name VARCHAR(255)
);

INSERT INTO dwh.dim_staff (staff_id, first_name, last_name, phone, email, active, manager_id, manager_first_name, manager_last_name)
SELECT 
  s.staff_id,
  s.first_name,
  s.last_name,
  COALESCE (s.phone, 'Unknown') AS PHONE,
  COALESCE (s.email, 'Unknown') AS EMAIL,
  s.active,
  s.manager_id,
  s2.first_name AS manager_first_name,
  s2.last_name AS manager_last_name
FROM sales.staffs AS s
LEFT JOIN sales.staffs AS s2 ON s.manager_id = s2.staff_id;

ALTER TABLE dwh.dim_staff
ADD CONSTRAINT dim_staff_pk PRIMARY KEY (staff_id);

-- ==========================
-- Staff Hierarchy Bridge
-- ==========================
CREATE TABLE dwh.staff_hierarchy(
	staff_id INT,
	subordinate_id INT,
	hierarchy_depth INT
);

WITH sh (staff_id, subordinate_id, hierarchy_depth)
AS (
	SELECT
		staff_id,
		staff_id AS subordinate_id,
		0 AS hierarchy_depth
	FROM sales.staffs
	UNION ALL
	SELECT
		sh.staff_id AS staff_id,
		s.staff_id AS subordinate_id,
		sh.hierarchy_depth + 1 AS hierarchy_depth
	FROM sh
	JOIN sales.staffs AS s ON sh.subordinate_id = s.manager_id
)
INSERT INTO dwh.staff_hierarchy (staff_id, subordinate_id, hierarchy_depth)
SELECT staff_id, subordinate_id, hierarchy_depth
FROM sh;
--where staff_id = 5

ALTER TABLE dwh.staff_hierarchy
ADD CONSTRAINT staff_hierarchy_d_staff_fk 
	FOREIGN KEY (staff_id) REFERENCES dwh.dim_staff(staff_id);


ALTER TABLE dwh.staff_hierarchy 
ADD CONSTRAINT staff_hierarchy_d_subordinate_fk 
	FOREIGN KEY (subordinate_id) REFERENCES dwh.dim_staff(staff_id);

-- ===============
-- Date Dimension
-- ===============
CREATE TABLE dwh.dim_date (
	date_id INT NOT NULL,
	date DATE NOT NULL,
	day_name TEXT NOT NULL,
	day_of_month INT NOT NULL,
	week_of_month INT NOT NULL,
	week_of_year INT NOT NULL,
	month INT NOT NULL,
	month_name TEXT NOT NULL,
	quarter INT NOT NULL,
	year INT NOT NULL,
	is_weekend BIT NOT NULL,
);

INSERT INTO dwh.dim_date (
	date_id, 
	date, 
	day_name, 
	day_of_month, 
	week_of_month, 
	week_of_year, 
	month,
	month_name,
	quarter,
	year,
	is_weekend)
SELECT
	CAST(REPLACE(CONVERT(VARCHAR, d, 23), '-', '') AS INT) AS d_id,
	d AS DATE,
	DATENAME(dw, d) AS day_name,
	DAY(d) AS day_of_month,
	DATEPART(ISO_WEEK, d) AS week_of_month,
	DATEPART(WEEK, d) AS week_of_year,
	MONTH(d) AS month,
	DATENAME(MONTH, d) AS month_name,
	DATEPART(QUARTER, d) AS quarter,
	YEAR(d) AS year,
	CASE 
		WHEN DATEPART(WEEKDAY, d) IN (6, 7) THEN 1
		ELSE 0
	END AS is_weekend
FROM (
    SELECT 
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2016-01-01') AS d
	FROM master..spt_values 
) date_seq
ORDER BY 1;

ALTER TABLE dwh.dim_date
ADD CONSTRAINT dim_date_pk PRIMARY KEY (date_id)
;
ALTER TABLE dwh.dim_date
ADD CONSTRAINT dim_date_date_u UNIQUE([date])
;