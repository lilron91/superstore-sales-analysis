-- 1. Monthly Sales Trend
-- Tracks revenue performance over time to identify seasonal patterns and growth trends

	SELECT
		DATEPART(year,o.order_date) AS Year,
		DATEPART(month,o.order_date) AS Month ,
		CONCAT(FORMAT(SUM(od.sales), 'N2'),' $' )AS Sales 
	FROM orders o
	JOIN order_details od ON od.order_id = o.order_id
	GROUP BY 
		DATEPART(year,o.order_date) ,
		DATEPART(month,o.order_date) 
	ORDER BY 
		Year,
		Month;
	

-- 2.Top 10 Customers
-- Identifies highest revenue generating customers to support retention and upsell strategies
	SELECT TOP 10
		c.customer_name, 
		CONCAT(FORMAT(SUM(od.sales), 'N2'),' $' ) AS Sales 
	FROM orders o
	JOIN customers c ON c.customer_id = o.customer_id
	JOIN order_details od ON od.order_id = o.order_id
	GROUP BY 
		c.customer_name
	ORDER BY Sales DESC


-- 3.Profit by Region YoY
-- Compares regional performance year over year to identify growth and decline trends
	SELECT 
		l.region AS REGION,
		DATEPART(year,o.order_date) AS YEAR,

		--Current Year Sales
		CONCAT(FORMAT(SUM(od.sales), 'N0'), ' $') AS 'Sales this Year',

		-- Previous year sales (N\A if NULL)
		CASE
			WHEN LAG(SUM(od.sales)) OVER (PARTITION BY l.region ORDER BY DATEPART(year,o.order_date)) IS NULL
			THEN 'N/A'
			ELSE CONCAT(
				FORMAT(
					LAG(SUM(od.sales)) OVER(PARTITION BY l.region ORDER BY DATEPART(year, o.order_date)),
					'N0'),
				' $') 
		END AS 'Sales last year',

		-- Difference ( if previous year is null)
		CASE
			WHEN LAG(SUM(od.sales)) OVER (PARTITION BY l.region ORDER BY DATEPART(year,o.order_date)) IS NULL
			THEN 'N/A'
			ELSE CONCAT(
			FORMAT(
				SUM(od.sales)
				- LAG(SUM(od.sales)) OVER(PARTITION BY l.region ORDER BY DATEPART(year, o.order_date)),
				'N0'),
				' $')
		END AS 'Sales Differences'
	FROM orders o
	JOIN locations l ON l.location_id = o.location_id
	JOIN order_details od ON od.order_id = o.order_id
	GROUP BY 
		l.region, 
		DATEPART(year,o.order_date)
	ORDER BY DATEPART(year,o.order_date) DESC

-- 4. Which Sub-Category brings the most income
-- Reveals which product sub-categories drive the most revenue to support assortment decisions
	SELECT 
		p.sub_category AS SubCategory, 
		CONCAT(FORMAT(SUM(od.sales),'N0'),' $') AS Total_Income
	FROM order_details od 
	JOIN products p ON p.product_id = od.product_id
	GROUP BY p.sub_category
	ORDER BY Total_Income DESC

--5. RFM Analysis segments customers by Recency, Frequency and Monetary value
-- Helps identify high-value customers and those at risk of churning
WITH rfm AS (
	SELECT 
		c.customer_id, 
		c.customer_name,
		COUNT(o.order_id) AS Frequency,
		DATEDIFF(
			day,
			MAX(o.order_date),
			(SELECT MAX(order_date) FROM orders)
		) AS Recency,
		SUM(od.sales) as Monetary
	FROM orders o
	 JOIN customers c ON c.customer_id = o.customer_id 
	 JOIN order_details od ON od.order_id = o.order_id
	 GROUP BY c.customer_id, c.customer_name
 )
SELECT
    customer_id,
    customer_name,
    Frequency,
    Recency,
    Monetary,
    -- Recency
    NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,

    -- Frequency
    NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,

    -- Monetary
    NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
FROM rfm;

-- 6. Shipping Performance by Ship Mode
-- Identifies average delivery time per shipping method to optimize logistics and customer satisfaction

SELECT 
    ship_mode AS 'Ship Mode',
    AVG(DATEDIFF(day, order_date, ship_date)) AS 'Avg Delivery Days',
    MIN(DATEDIFF(day, order_date, ship_date)) AS 'Fastest Delivery',
    MAX(DATEDIFF(day, order_date, ship_date)) AS 'Slowest Delivery',
    COUNT(order_id) AS 'Total Orders'
FROM orders
GROUP BY ship_mode
ORDER BY 'Avg Delivery Days' ASC
