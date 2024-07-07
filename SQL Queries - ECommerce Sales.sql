-- SQL Queries for Power BI visualization
-- total $ sales by year and month
SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month_num,
	TO_CHAR(order_date, 'Mon') AS month_name,
	SUM(sales_price)::NUMERIC(10,2) AS total_sales
FROM orders
GROUP BY year, month_num, month_name
ORDER BY year, month_num ASC;

-- total cost by year and month
SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month_num,
	TO_CHAR(order_date, 'Mon') AS month_name,
	SUM(cost_price)::NUMERIC(10,2) AS total_cost
FROM orders
GROUP BY year, month_num, month_name
ORDER BY year, month_num ASC;

-- total quantity sold by year and month
SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month_num,
	TO_CHAR(order_date, 'Mon') AS month_name,
	SUM(quantity) AS total_quantity
FROM orders
GROUP BY year, month_num, month_name
ORDER BY year, month_num ASC;

-- total profit by year and month
SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month_num,
	TO_CHAR(order_date, 'Mon') AS month_name,
	SUM(profit)::NUMERIC(10,2) AS total_profit
FROM orders
GROUP BY year, month_num, month_name
ORDER BY year, month_num ASC;

-- profit margin by year
SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	(SUM(profit) / SUM(sales_price) * 100)::NUMERIC(10,2) AS profit_margin
FROM orders
GROUP BY year
ORDER BY year ASC;

-- using CTEs, CY Sales vs PY Sales by Category
WITH cy_sales AS (
	SELECT
		category,
		SUM(sales_price)::NUMERIC(10,2) AS total_sales
	FROM orders
	WHERE order_date BETWEEN '2023-01-01 00:00:00'
		AND '2023-12-31 00:00:00'
	GROUP BY category
),
py_sales AS (
	SELECT
		category,
		SUM(sales_price)::NUMERIC(10,2) AS total_sales
	FROM orders
	WHERE order_date BETWEEN '2022-01-01 00:00:00'
		AND '2022-12-31 00:00:00'
	GROUP BY category
)
	SELECT
		cy.category,
		cy.total_sales AS cy_total_sales,
		py.total_sales AS py_total_sales,
		(((cy.total_sales - py.total_sales) / py.total_sales) * 100)::NUMERIC(10, 2) AS yoy_sales_percentage
	FROM cy_sales as cy
	JOIN py_sales as py
		ON cy.category = py.category;

-- using CTEs and window function, find the Top 5 product sub-category by sales in current year
WITH year_cte AS (
	SELECT 
		*,
		EXTRACT(YEAR FROM order_date) AS year
	FROM orders
),
cy AS (
	SELECT *
	FROM year_cte
	WHERE year = 2023
),
sc_ranking AS (
	SELECT
		sub_category,
		SUM(sales_price) AS sales,
		RANK() OVER(ORDER BY SUM(sales_price) DESC) AS ranking
	FROM cy
	GROUP BY sub_category
)
SELECT
	sub_category,
	sales::NUMERIC(10,2)
FROM sc_ranking
WHERE ranking BETWEEN 1 AND 5;

-- using CTEs, find the Bottom 5 product sub-category by sales in current year
WITH year_cte AS (
	SELECT 
		*,
		EXTRACT(YEAR FROM order_date) AS year
	FROM orders
),
cy AS (
	SELECT *
	FROM year_cte
	WHERE year = 2023
)
SELECT
	sub_category,
	SUM(sales_price)::NUMERIC(10, 2) AS sales
FROM cy
GROUP BY sub_category
ORDER BY sales ASC
LIMIT 5;

-- using a from subquery, cost vs profit by region
SELECT
	region,
	SUM(cost_price) AS total_cost,
	SUM(profit)::NUMERIC(10, 2) AS total_profit
FROM
	(SELECT * 
	 FROM orders
	 WHERE order_date BETWEEN '2023-01-01 00:00:00'
	 	AND '2023-12-31 00:00:00') AS cy
GROUP BY region
ORDER BY total_cost DESC, total_profit DESC;