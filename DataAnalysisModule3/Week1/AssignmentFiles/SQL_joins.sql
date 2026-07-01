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

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
