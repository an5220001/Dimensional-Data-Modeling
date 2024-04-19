-- ===========
-- Order Fact
-- ===========
CREATE TABLE dwh.fact_bike_order (
	order_date_id INT,
	requirement_date_id INT,
	customer_id INT,
	staff_id INT,
	store_id INT,
	product_id INT,
	order_id INT,
	quantity INT,
	list_price  DECIMAL(10, 2),
	discount DECIMAL (4, 2),
	order_amount DECIMAL(10, 2),
	discounted_order_amount DECIMAL(10, 2)
);

INSERT INTO dwh.fact_bike_order (
	order_date_id,
	requirement_date_id,
	customer_id,
	staff_id,
	store_id,
	product_id,
	order_id,
	quantity,
	list_price,
	discount,
	order_amount,
	discounted_order_amount
)
SELECT 
	CAST(REPLACE(CONVERT(VARCHAR, o.order_date, 23), '-', '') AS INT) AS order_date_id,
	CAST(REPLACE(CONVERT(VARCHAR, o.required_date	, 23), '-', '') AS INT) AS requirement_date_id,
	o.customer_id,
	o.staff_id,
	o.store_id,
	oi.product_id,
	o.order_id,
	oi.quantity,
	oi.list_price,
	oi.discount,
	oi.list_price * oi.quantity AS order_amount,
	(oi.list_price - oi.discount) * oi.quantity AS discounted_order_amount
FROM sales.orders o 
JOIN sales.order_items oi ON o.order_id = oi.order_id
;
ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_date_fk      
		FOREIGN KEY (order_date_id) REFERENCES dwh.dim_date(date_id)
;

ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_requirement_d_date_fk      
		FOREIGN KEY (requirement_date_id) REFERENCES dwh.dim_date(date_id)
;
ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_d_customer_fk      
		FOREIGN KEY (customer_id) REFERENCES dwh.dim_customer(customer_id)
;
ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_d_product_fk      
		FOREIGN KEY (product_id) REFERENCES dwh.dim_product(product_id)
;
ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_d_staff_fk      
		FOREIGN KEY (staff_id) REFERENCES dwh.dim_staff(staff_id)
;
ALTER TABLE dwh.fact_bike_order 
ADD CONSTRAINT f_bike_order_d_store_fk      
		FOREIGN KEY (store_id) REFERENCES dwh.dim_store(store_id)
;

-- ===============
-- Shipment Fact
-- ===============
CREATE TABLE dwh.fact_bike_shipment (
	shipment_date_id INT,
	customer_id INT,
	staff_id INT,
	store_id INT,
	product_id INT,
	order_id INT,
	quantity INT,
	list_price  DECIMAL(10, 2),
	discount DECIMAL (4, 2),
	shipment_amount DECIMAL(10, 2),
	discounted_shipment_amount DECIMAL(10, 2)
);

INSERT INTO dwh.fact_bike_shipment (
	shipment_date_id,
	customer_id,
	staff_id,
	store_id,
	product_id,
	order_id,
	quantity,
	list_price,
	discount,
	shipment_amount,
	discounted_shipment_amount
)
SELECT 
	CAST(REPLACE(CONVERT(VARCHAR, o.shipped_date, 23), '-', '') AS INT) AS shipment_date_id,
	o.customer_id,
	o.staff_id,
	o.store_id,
	oi.product_id,
	o.order_id,
	oi.quantity,
	oi.list_price,
	oi.discount,
	oi.list_price * oi.quantity AS shipment_amount,
	(oi.list_price - oi.discount) * oi.quantity AS discounted_shipment_amount
from sales.orders o 
join sales.order_items oi
	on o.order_id = oi.order_id
where o.shipped_date is not null

;
ALTER TABLE dwh.fact_bike_shipment 
ADD CONSTRAINT f_bike_shipment_d_date_fk      
		FOREIGN KEY (shipment_date_id) REFERENCES dwh.dim_date(date_id)
;
ALTER TABLE dwh.fact_bike_shipment 
ADD CONSTRAINT f_bike_shipment_d_customer_fk      
		FOREIGN KEY (customer_id) REFERENCES dwh.dim_customer(customer_id)
;

ALTER TABLE dwh.fact_bike_shipment 
ADD CONSTRAINT f_bike_shipment_d_product_fk      
		FOREIGN KEY (product_id) REFERENCES dwh.dim_product(product_id)
;
ALTER TABLE dwh.fact_bike_shipment 
ADD CONSTRAINT f_bike_shipment_d_staff_fk      
		FOREIGN KEY (staff_id) REFERENCES dwh.dim_staff(staff_id)
;
ALTER TABLE dwh.fact_bike_shipment 
ADD CONSTRAINT f_bike_shipment_d_store_fk      
		FOREIGN KEY (store_id) REFERENCES dwh.dim_store(store_id)
;


-- ============================
-- Store Stock Fact
-- ============================
CREATE TABLE dwh.fact_store_stock (
	date_id INT,
	store_id INT,
	product_id INT,
	quantity INT,
);

INSERT INTO dwh.fact_store_stock (
	date_id,
	store_id,
	product_id,
	quantity
)
SELECT 
	CAST(REPLACE(CONVERT(VARCHAR, '2021-06-23', 23), '-', '') AS INT) AS shipment_date_id,
	store_id,
	product_id,
	quantity
from 
	production.stocks
;

ALTER TABLE dwh.fact_store_stock
ADD CONSTRAINT f_store_stock_d_store_fk
	FOREIGN KEY (store_id) REFERENCES dwh.dim_store(store_id)
;
ALTER TABLE dwh.fact_store_stock
ADD CONSTRAINT f_store_stock_d_product_fk
	FOREIGN KEY (product_id) REFERENCES dwh.dim_product(product_id)
;
ALTER TABLE dwh.fact_store_stock
ADD CONSTRAINT f_store_stock_d_date_fk
	FOREIGN KEY (date_id) REFERENCES dwh.dim_date(date_id)
;