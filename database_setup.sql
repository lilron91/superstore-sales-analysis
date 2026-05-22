--- Create the database

CREATE DATABASE superstore_sales_dataset;

---

USE superstore_sales_dataset;

---Drop table if exists
DROP TABLE IF EXISTS raw_data;

--- Create a RAW table before cleaning
CREATE TABLE raw_data (
	row_id int,
	order_id varchar(30),
	order_date date,
	ship_date date,
	ship_mode varchar(20),
	customer_id varchar(30),
	customer_name varchar(30),
	segment varchar(30),
	country varchar(50),
	city varchar(100),
	state varchar(50),
	postal_code int,
	region varchar(50),
	product_id varchar(100),
	category varchar(50),
	sub_category varchar(50),
	product_name varchar (250),
	sales float
) ;

--- Created Table

SELECT * FROM raw_data;

------------------
-- Create dimensional and fact tables
------------------

CREATE TABLE customers (
	customer_id varchar(30) PRIMARY KEY,
	customer_name varchar(30),
	segment varchar(30)
);
CREATE TABLE products(
	 product_id varchar(100) PRIMARY KEY,
	 product_name varchar(250),
	 category varchar(50),
	 sub_category varchar(50)
);
CREATE TABLE locations (
	location_id int IDENTITY(1,1) PRIMARY KEY,
	country varchar(50),
	region varchar(50),
	state varchar(50),
	city varchar(100),
	postal_code int
);

CREATE TABLE orders(
	order_id varchar(30) PRIMARY KEY, 
	order_date date,
	ship_date date,
	ship_mode varchar(20),
	customer_id varchar(30),
	location_id int,
	FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
	FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE order_details (
	order_detail_id int IDENTITY(1,1) PRIMARY KEY,
	order_id varchar(30),
	product_id varchar(100),
	sales float,
	FOREIGN KEY (order_id) REFERENCES orders(order_id),
	FOREIGN KEY (product_id) REFERENCES products(product_id)
);

------------------
-- Insert data FROM raw_data to tables
------------------

-- Customer Table
INSERT INTO customers(customer_id,customer_name,segment)
SELECT
	DISTINCT customer_id,
	customer_name,
	segment
FROM raw_data;

-- Products Table

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT 
    product_id,
    MIN(product_name),
    MIN(category),
    MIN(sub_category)
FROM raw_data
GROUP BY product_id;

--Locations Table
INSERT INTO locations (country ,region ,state ,city ,postal_code)
SELECT DISTINCT
	country ,
	region ,
	state ,
	city ,
	postal_code
FROM raw_data

--Orders Table
--We add a column to raw_Data cause after we have to insert it to order table
ALTER TABLE  raw_data ADD location_id INT;

UPDATE r
SET r.location_id = l.location_id
FROM raw_data r
JOIN locations l
	ON r.country = l.country
	AND r.region = l.region
	AND r.state = l.state
	AND r.city = l.city
	AND r.postal_code = l.postal_code;

SELECT * from orders

INSERT INTO orders(order_id,order_date,ship_date,ship_mode,customer_id,location_id)
SELECT DISTINCT 
	order_id ,
	order_date ,
	ship_date ,
	ship_mode ,
	customer_id, 
	location_id
FROM raw_data;

-- Order_details table

Select * FROM order_details;

INSERT INTO order_details(order_id,product_id,sales)
SELECT 
	order_id,
	product_id,
	sales
FROM raw_data;

-- Float was not the right choice as it generates numbers that are too long, changing to DECIMAL
ALTER TABLE order_details
ALTER COLUMN sales DECIMAL(10,2)
