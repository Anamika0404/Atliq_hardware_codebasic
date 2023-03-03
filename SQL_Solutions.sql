-- -----------Provide Insights to Management in Consumer Goods Domain ---------------------------
-- --------------------Challenge Project by Codebasics--------------------------------------------
----------------------------- Anamika kumari --------------------------------------------------


-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select  market
from gdb023.dim_customer
where region = 'APAC' and customer= 'Atliq Exclusive';

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,-- unique_products_2020-- unique_products_2021-- percentage_chg

select unique_product_2020,unique_product_2021,((unique_product_2021-unique_product_2020)/unique_product_2020*100 )  as perc_increase
from
(SELECT count(distinct product_code) as unique_product_2020
 FROM gdb023.fact_sales_monthly
 where fiscal_year = '2020') as p,
 (SELECT count(distinct product_code) as unique_product_2021
 FROM gdb023.fact_sales_monthly
 where fiscal_year = '2021') as q ;
 
 -- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts.
--  The final output contains 2 fields,segment,product_count 

SELECT  segment , count(distinct product ) as product_count
FROM gdb023.dim_product
Group by 1
order by 2 desc; 

-- Q4  Which segment had the most increase in unique products in-- 2021 vs 2020? The final output contains these fields,
-- segment,product_count_2020,product_count_2021,difference

SELECT dp.segment, 
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2020 THEN dp.product_code END) AS product_count_2020,
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2021 THEN dp.product_code END) AS product_count_2021,
  COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2021 THEN dp.product_code END) - COUNT(DISTINCT CASE WHEN fgp.fiscal_year = 2020 THEN dp.product_code END) AS difference
FROM gdb023.dim_product dp
JOIN gdb023.fact_gross_price fgp ON dp.product_code = fgp.product_code
GROUP BY dp.segment
ORDER BY difference DESC;

-- 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost

select dp.product_code, dp.product, fmc.manufacturing_cost
from gdb023.dim_product dp
join gdb023.fact_manufacturing_cost fmc on dp.product_code = fmc.product_code
WHERE 
  fmc.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost) 
  OR fmc.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost);


-- 6. Generate a report which contains the top 5 customers who received an 
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the 
-- Indian market. The final output contains these fields, customer_code 
-- customer average_discount_percentage

select * from gdb023.fact_sales_monthly

select t.*
from
(select p.* , round(p.average_discount*100.0,2) as avg_disc_percent
from
(SELECT c.customer_code,c.customer, avg(pre_invoice_discount_pct) as average_discount
FROM gdb023.fact_pre_invoice_deductions as f
join
gdb023.dim_customer as c
on f.customer_code= c.customer_code
where fiscal_year= '2021' and c.market = 'India'
group by 1,2
order by 3 desc) as p) as t
where t.avg_disc_percent > t.average_discount                -- -<<<-  why greater than-- 
order by avg_disc_percent desc
limit 5;



-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:-- Month-- Year-- Gross sales Amount

select DATE_FORMAT(s.date,'%M') as Month,YEAR(s.date) as Year ,
floor(sum(gross_price * sold_quantity)) as Gross_sales_amount
FROM gdb023.fact_gross_price as g
join gdb023.fact_sales_monthly as s
on g.product_code= s.product_code
join gdb023.dim_customer as c
on c.customer_code= s.customer_code
 where customer = 'Atliq Exclusive'
group by 1,2
order by 3 desc

-- Q8 In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,-- Quarter-- total_sold_quantity

SELECT CONCAT(YEAR(date), '-Q', QUARTER(date)) AS quarter, SUM(sold_quantity) AS total_sold_quantity
FROM gdb023.fact_sales_monthly
WHERE YEAR(date) = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;


-- Q9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel-- gross_sales_mln-- percentage

select dc.channel, 
	round(sum(fg.gross_price * fs.sold_quantity),3) as gross_sales_mln,
	round(sum((fg.gross_price * fs.sold_quantity) / (SELECT SUM(gross_price) 
    FROM gdb023.fact_gross_price WHERE fiscal_year = 2021) * 100),3) AS percentage
from gdb023.fact_gross_price fg
join gdb023.fact_sales_monthly fs on fg.product_code = fs.product_code and fg.fiscal_year = fs.fiscal_year
join gdb023.dim_customer dc on fs.customer_code = dc.customer_code
WHERE fg.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC
LIMIT 1;


-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,-- division-- product_code--  product-- total_sold_quantity-- rank_orde


select t.*
from
(
select r.*,
rank() over( partition by division order by total_sold desc) as ranking_sold
from
(select distinct p.division,  p.product_code, p.product, sum(m.sold_quantity) as total_sold
FROM gdb023.fact_sales_monthly as m
join
gdb023.dim_product as p
on m.product_code= p.product_code
where fiscal_year ='2021'
group by 1,2,3
order by 4) as r) as t
where ranking_sold < 4

