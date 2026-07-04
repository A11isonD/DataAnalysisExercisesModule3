USE coffeeshop_db;

-- =========================================================
-- ADVANCED SQL ASSIGNMENT
-- Subqueries, CTEs, Window Functions, Views
-- =========================================================
-- Notes:
-- - Unless a question says otherwise, use orders with status = 'paid'.
-- - Write ONE query per prompt.
-- - Keep results readable (use clear aliases, ORDER BY where it helps).

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
-- For each PAID order, compute order_total (= SUM(quantity * products.price)). --outer query is finding the paid orders
-- Return: order_id, customer_name, store_name, order_datetime, order_total.
-- Filter to orders where order_total is greater than the average PAID order_total
-- for THAT SAME store (correlated subquery). --inner query (of the paid orders, do something)
-- Sort by store_name, then order_total DESC.
select 
	oi.order_id, 
	concat(c.first_name, ' ', c.last_name) as customer_name, 
    s.name as store_name, 
    o.order_datetime, 
    o.status,
    sum(oi.quantity * p.price) as order_total
from order_items oi
join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
join stores s on o.store_id = s.store_id
join products p on oi.product_id = p.product_id
where o.status = 'paid'
group by oi.order_id, customer_name, store_name
having order_total > (
	select avg(store_orders.order_total)
	from (
		select sum(oi2.quantity * p2.price) as order_total
		from order_items oi2
		join orders o2 on oi2.order_id = o2.order_id 
		join products p2 on oi2.product_id = p2.product_id 
		where o2.status = 'paid'
        group by o2.order_id
	) as store_orders
);





-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
-- Using a CTE, compute daily revenue per store:
--   revenue_day = SUM(quantity * products.price) grouped by store_id and DATE(order_datetime).
-- Then, for each store and date, return:
--   store_name, order_date, revenue_day,
--   rolling_3day_avg = average of revenue_day over the current day and the prior 2 days.
-- Use a window function for the rolling average.
-- Sort by store_name, order_date.


with daily_revenue_per_store as (
select sum(oi.quantity * p.price) as revenue_day, 
date(o.order_datetime) as order_date, 
s.store_id
from order_items oi
join products p on oi.product_id = p.product_id
join orders o on oi.order_id = o.order_id
join stores s on o.store_id = s.store_id
where o.status = 'paid'
group by 
	store_id, 
    date(o.order_datetime)
order by
	s.store_id,
    order_date
)
select 
	* from daily_revenue_per_store,
	s.name as store_name,
	date(o.order_datetime) as order_date,
	day(o.order_datetime) as revenue_day,	
from stores
over (
	partition by store_name
    rolling_3day_avg(oi.quantity * p.price)
	order by rows between 2 preceeding and current row
)
order by
	store_name,
    order_date;

-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
-- Compute each customer's total spend across ALL stores (PAID only). Window functions produce a result for every single row.
-- Return: customer_id, customer_name, total_spend,
--         spend_rank (DENSE_RANK by total_spend DESC).
-- Also include percent_of_total = customer's total_spend / total spend of all customers.
-- Sort by total_spend DESC.

select 
	c.customer_id,
    concat (c.first_name, ' ', c.last_name) as customer_name,
    sum(oi.quantity * p.price) as customer_total_spend,
    sum(sum(oi.quantity * p.price)) over () as total_spend_of_all_customers,
    customer_total_spend / total_spend_of_all_customers * 100 as percent_of_total,
    dense_rank by customer_total_spend desc as spend_rank
from customers c
join orders o on oi.order_id = o.order_id
join order_items oi on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id
where o.status = 'paid'
group by c.customer_id, c.first_name, c.last_name
order by customer_total_spend desc;


-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
-- For each store, find the top-selling product by REVENUE (not units).
-- Revenue per product per store = SUM(quantity * products.price).
-- Return: store_name, product_name, category_name, product_revenue.
-- Use a CTE to compute product_revenue, then a window function (ROW_NUMBER)
-- partitioned by store to select the top 1.
-- Sort by store_name.


with product_revenue as (
select
	sum(oi.quantity * p.price) 
    from order_items oi
    join p.product_id on oi.product_id
)
select 
	* from product_revenue,
    s.name as store_name,
    p.name as product_name,
    ca.name as category_name,
    sum(oi.quantity * p.price) as revenue_per_product_per_store
    from stores s
    join products on oi.product_id = p.product_id
    join categories ca on p.category_id = ca.category_id
row_number(store_id)
over(
	partition by store_id
    order by store_name
    limit 1
);


/*
This is a corrected version but it's not running either.
WITH product_revenue AS (
    SELECT 
        s.store_id,
        s.name AS store_name,
        p.product_id,
        p.name AS product_name,
        ca.name AS category_name,
        SUM(oi.quantity * p.price) AS revenue_per_product_per_store,
        ROW_NUMBER() OVER (
            PARTITION BY s.store_id 
            ORDER BY SUM(oi.quantity * p.price) DESC
        ) AS product_rank
    FROM stores s
    JOIN order_items oi ON s.store_id = oi.store_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories ca ON p.category_id = ca.category_id
    GROUP BY s.store_id, s.name, p.product_id, p.name, ca.name
)
SELECT *
FROM product_revenue
WHERE product_rank = 1;
*/



-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
-- Return customers who have at least one PAID order in every store in the stores table.
-- Return: customer_id, customer_name.
-- Hint: Compare count(distinct store_id) per customer to (select count(*) from stores).

select 
	c.customer_id,
    c.customer_name
from customers 
where (
	select
    customer_id
    from customers
    where count(distinct store_id)
);
  



-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
-- For each customer, list their PAID orders in chronological order and compute:
--   prev_order_datetime (LAG),
--   minutes_since_prev (difference in minutes between current and previous order).
-- Return: customer_name, order_id, order_datetime, prev_order_datetime, minutes_since_prev.
-- Only show rows where prev_order_datetime is NOT NULL.
-- Sort by customer_name, order_datetime.

-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
-- Create a view named v_paid_order_lines that returns one row per PAID order item:
--   order_id, order_datetime, store_id, store_name,
--   customer_id, customer_name,
--   product_id, product_name, category_name,
--   quantity, unit_price (= products.price),
--   line_total (= quantity * products.price)
--
-- After creating the view, write a SELECT that uses the view to return:
--   store_name, category_name, revenue
-- where revenue is SUM(line_total),
-- sorted by revenue DESC.

-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
-- Create a view named v_paid_store_payments with:
--   store_id, store_name, payment_method, revenue
-- where revenue is total PAID revenue for that store/payment_method.
--
-- Then query the view to return:
--   store_name, payment_method, revenue,
--   store_total_revenue (window SUM over store),
--   pct_of_store_revenue (= revenue / store_total_revenue)
-- Sort by store_name, revenue DESC.

-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
-- Identify items where on_hand is low compared to recent demand:
-- Using a CTE, compute total_units_sold per store/product for PAID orders.
-- Then join inventory to that result and return rows where:
--   on_hand < total_units_sold
-- Return: store_name, product_name, on_hand, total_units_sold, units_gap (= total_units_sold - on_hand)
-- Sort by units_gap DESC.

