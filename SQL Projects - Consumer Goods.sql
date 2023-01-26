#Task 1
SELECT distinct market
FROM gdb023.dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

#Task 2
WITH unique_products AS (
SELECT fiscal_year, COUNT(DISTINCT Product_code) as unique_products 
FROM fact_gross_price 
GROUP BY fiscal_year
)
SELECT up_2020.unique_products as unique_products_2020,
	   up_2021.unique_products as unique_products_2021,
       round((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) as percentage_change
FROM unique_products up_2020
CROSS JOIN unique_products up_2021
WHERE up_2020.fiscal_year = 2020 AND up_2021.fiscal_year = 2021;

#Task 3
SELECT segment, count(distinct product_code) product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;

#Task 4
WITH UP AS (
SELECT pro.segment segment,
	   pri.fiscal_year fiscal_year,
       count(distinct pro.product_code) product_count
FROM dim_product pro
JOIN fact_gross_price pri
ON pro.product_code = pri.product_code
GROUP BY segment, fiscal_year
)
SELECT UP20.segment segment, 
	   UP20.product_count product_count_2020, 
       UP21.product_count product_count_2021,
       (UP21.product_count - UP20.product_count) difference
FROM UP UP20
JOIN UP UP21
ON UP20.segment = UP21.segment
WHERE UP20.fiscal_year = 2020 AND UP21.fiscal_year = 2021
ORDER BY difference DESC;

#Task 5
SELECT cost.product_code, pro.product, cost.manufacturing_cost
FROM fact_manufacturing_cost cost
JOIN dim_product pro
ON cost.product_code = pro.product_code
WHERE cost.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
	  OR cost.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

#TASK 6
SELECT disc.customer_code, cust.customer, avg(disc.pre_invoice_discount_pct) average_discount_percentage
FROM fact_pre_invoice_deductions disc
JOIN dim_customer cust
ON disc.customer_code = cust.customer_code
WHERE disc.fiscal_year = 2021 AND cust.market = 'India'
GROUP BY disc.customer_code, cust.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

#Task 7
SELECT year(sales.date) Year, month(sales.date) Month, sum(sales.sold_quantity * price.gross_price) Gross_sales_Amount
FROM fact_Sales_monthly sales
JOIN fact_gross_price price
ON sales.product_code = price.product_code
JOIN dim_customer cust
ON sales.customer_code = cust.customer_code
WHERE cust.customer = 'Atliq Exclusive'
GROUP BY year(sales.date), month(sales.date)
ORDER BY year(sales.date) ASC;

#Task 8
WITH a AS (
SELECT month(date) month, fiscal_year, sum(sold_quantity) total_sold_quantity
FROM fact_sales_monthly
GROUP BY month, fiscal_year
)
SELECT CASE
when month in (9,10,11) then "Q1"
when month in (12,1,2) then "Q2"
when month in (3,4,5) then "Q3"
when month in (6,7,8) then "Q4" END Quarter,
sum(total_sold_quantity) as total_sold_quantity
FROM a
WHERE fiscal_year = 2020
GROUP BY Quarter;

#Task 9
WITH a AS (
SELECT cust.channel channel, 
	   sum(sales.sold_quantity * price.gross_price) Gross_sales_Amount
FROM fact_sales_monthly sales
JOIN dim_customer cust
ON sales.customer_code = cust.customer_code
JOIN fact_gross_price price
ON sales.product_code = price.product_code
WHERE sales.fiscal_year = 2021
GROUP BY cust.channel
)
SELECT channel,
	   round(Gross_sales_Amount/1000000,2) gross_sales_mln,
       round(Gross_sales_Amount/(sum(Gross_sales_Amount) OVER())*100,2) percentage
FROM a;

#Task 10
WITH a AS (
SELECT pro.division division, 
	   sales.product_code product_code,
       concat(pro.product,"-", pro.variant) product,
       sum(sales.sold_quantity) total_sold_quantity,  
       DENSE_RANK() OVER(PARTITION BY division ORDER BY sum(sales.sold_quantity) DESC) rank_order
FROM fact_sales_monthly sales
JOIN dim_product pro
ON sales.product_code = pro.product_code
WHERE sales.fiscal_year = 2021
GROUP BY division, product_code, concat(pro.product,"-", pro.variant)
ORDER BY total_sold_quantity DESC
)
SELECT *
FROM a
WHERE rank_order IN(1,2,3);

