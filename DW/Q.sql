USE BikeStores
GO
-- ===================================================================================
-- What is the total order dollar amount by bike category and store for the year 2017? 
-- ===================================================================================
SELECT 
	dp.category_name AS "category",	
	ds.store_name AS "store",
	sum(fbo.order_amount) AS "total order amount"
FROM dwh.fact_bike_order AS fbo, 
	dwh.dim_product AS dp,
	dwh.dim_store ds, 
	dwh.dim_date dd 
WHERE fbo.order_date_id = dd.date_id 
	AND fbo.product_id = dp.product_id
	AND fbo.store_id = ds.store_id 
	AND dd.year = 2017
GROUP BY
	dp.category_name,
	ds.store_name;

-- ===========================================================================
-- What is the percentage of delayed shipments compared to the total number of shipments? 
-- ===========================================================================
SELECT 
	dc.zip_code AS "customerZipCode",
	SUM(
		CASE 
			WHEN sdate."date" IS NOT NULL 
				AND rdate."date" < sdate."date" THEN 1 
			WHEN sdate."date" IS NULL
				AND rdate."date" < GETDATE() THEN 1
			ELSE 0 
		END
	) AS "delayedShipmentsCount",
	COUNT(*) AS "shipmentsCount"
FROM (
	SELECT order_id, customer_id, store_id, requirement_date_id 
	FROM dwh.fact_bike_order
	GROUP BY order_id, customer_id, store_id, requirement_date_id
) orders
LEFT JOIN (
	SELECT order_id, shipment_date_id
	FROM dwh.fact_bike_shipment
	GROUP BY order_id, shipment_date_id
) shipments 
	ON orders.order_id = shipments.order_id
LEFT JOIN dwh.dim_customer dc 
	ON orders.customer_id = dc.customer_id 
LEFT JOIN dwh.dim_store ds 
	ON orders.store_id = ds.store_id
LEFT JOIN dwh.dim_date rdate 
	ON orders.requirement_date_id = rdate.date_id
LEFT JOIN dwh.dim_date sdate
	ON shipments.shipment_date_id = sdate.date_id
GROUP BY dc.zip_code;

-- ===============================================================================================================
-- What is the total order dollar amount of each staff managed by Jannette for the first quarter of the year 2017?
-- ===============================================================================================================
SELECT 
	CONCAT(ds.first_name, ' ', ds.last_name) AS "Name",
	SUM(fbo.order_amount) AS "Sales Amount"
FROM 
	dwh.fact_bike_order fbo
	INNER JOIN dwh.staff_hierarchy bridge ON fbo.staff_id = bridge.subordinate_id
	INNER JOIN dwh.dim_staff ds ON ds.staff_id = bridge.staff_id
	INNER JOIN dwh.dim_date dd ON fbo.order_date_id = dd.date_id
WHERE
	ds.first_name = 'Jannette'
	AND dd."year" = 2017
	AND dd.quarter = 1
GROUP BY
	ds.staff_id, ds.first_name, ds.last_name;

-- ==============================================================================================================================
-- What is the total order dollar amount of each staff above Layla in the staff hierarchy for the first quarter of the year 2017?
-- ==============================================================================================================================
SELECT 
	CONCAT(ds.first_name, ' ', ds.last_name) AS "Name",
	SUM(fbo.order_amount) AS "Sales Amount"
FROM 
	dwh.fact_bike_order fbo
	INNER JOIN dwh.staff_hierarchy bridge ON fbo.staff_id = bridge.staff_id
	INNER JOIN dwh.dim_staff ds ON ds.staff_id = bridge.subordinate_id
	INNER JOIN dwh.dim_date dd ON fbo.order_date_id = dd.date_id
WHERE
	ds.first_name = 'Layla'
	AND dd."year" = 2017
	AND dd.quarter = 1
GROUP BY
	ds.staff_id, ds.first_name, ds.last_name;


