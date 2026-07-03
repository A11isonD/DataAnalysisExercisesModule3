USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select p.name, c.name, p.price
from products p
inner join categories c
	on p.category_id = c.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.  COME BACK TO THIS ONE!!!!
select 
	order_items.order_id, 
    order_items.quantity, 
    orders.order_datetime, 
    orders.store_id, 
    products.product_name,
    products.price,
    stores.store_name, 
    quantity * products.price 
from order_items oi
join orders o
	on oi.order_id = o.order_id
join order_items oi
	on p.product_id = oi.product_id
join stores s
	on o.store_id = s.store_id
where line_total = quantity * products.price
order by order_datetime, order_id;



-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).

SELECT 
	concat (c.first_name, ' ', c.last_name) as customer_name,
    s.name AS store_name,
    o.order_datetime,
    SUM(oi.quantity * p.price) AS order_total
FROM customers c
JOIN orders o 
    ON o.customer_id = c.customer_id
JOIN stores s 
    ON s.store_id = o.store_id
JOIN order_items oi 
    ON oi.order_id = o.order_id
JOIN products p 
    ON p.product_id = oi.product_id
WHERE o.status = 'paid'
GROUP BY 
    customer_name,
    s.name,
    oi.quantity,
	p.price,
    o.order_datetime
ORDER BY o.order_datetime DESC;
    

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select 
	c.first_name,
    c.last_name,
    c.city,
    c.state
from customers c
left join orders o
	on o.customer_id = c.customer_id
where o.order_id is null; 

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
select
	s.name as store_name,
    p.name as product_name,
    sum(oi.quantity) over (
		partition by s.store_id
        ) as total_units
from stores s
join orders o on s.store_id = o.store_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.status = 'paid'; 

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select 
	s.name as store_name,
    p.name as product_name,
    on_hand
from inventory i
join stores s on i.store_id = s.store_id
join products p on i.product_id = p.product_id
where on_hand < 12;
    
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
select 
	concat (first_name, ' ', last_name) as manager_name,
    hire_date
from employees
where title = 'Manager';

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
with total_paid_revenue as (
	select 
		p.product_id,
		p.name as product_name,
		sum(oi.quantity * p.price) as total_revenue
	from products p
    join order_items oi on p.product_id = oi.product_id
    group by p.product_id, p.name
),
avg_revenue as (
	select
		avg(oi.quantity * p.price) as avg_paid_product_revenue
	from products p
    join order_items oi on p.product_id = oi.product_id
)
select 
	tpr.product_name,
    tpr.total_revenue
from total_paid_revenue tpr
join avg_revenue ar
where tpr.total_revenue > ar.avg_paid_product_revenue; 



-- Q9) Churn-ish check: list customers with their last PAID order date - limit 1, desc
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
select 
	concat (c.first_name, ' ', c.last_name) as customer_name,
	max(o.order_datetime) as last_paid_order
from customers c
left join orders o on c.customer_id = o.customer_id
where 
	o.status = 'paid' 
	or o.status is null
group by c.first_name, c.last_name
order by last_paid_order desc;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
select 
	sum(oi.quantity) as total_units,
	sum(oi.quantity * p.price) as total_revenue,
    s.name as store_name,
    ca.name as category_name
from order_items oi
join products p on p.product_id = oi.product_id
join categories ca on ca.category_id = p.category_id
join orders o on oi.order_id = o.order_id
join stores s on o.store_id = s.store_id
where o.status = 'paid'
group by store_name, category_name;


