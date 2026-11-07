-- 03_analysis.sql
-- Business questions: revenue, trend, categories, states, payments, delivery and reviews.

use olist_ecommerce;

-- how much revenue did the business make?
select count(distinct order_id) as total_orders, sum(price) as total_revenue,
round(sum(price) / count(distinct order_id), 2) as avg_order_value
from order_items;

-- monthly revenue trend
select date_format(o.order_purchase_timestamp, '%Y-%m') as month,
count(distinct o.order_id) as orders, round(sum(i.price), 2) as revenue
from orders o join order_items i 
on o.order_id = i.order_id
group by month order by month;

-- top product categories by revenue
select p.product_category_name as category, round(sum(i.price), 2) as revenue
from order_items i join products p on i.product_id = p.product_id
group by p.product_category_name order by revenue desc limit 10;

-- which states have the most orders?
select c.customer_state as state, count(*) as orders
from orders o join customers c on o.customer_id = c.customer_id
group by c.customer_state order by orders desc limit 10;

-- how do customers pay?
select payment_type, count(*) as payments, round(sum(payment_value), 2) as total_value
from order_payments group by payment_type order by total_value desc;

-- how many days does delivery take on average?
select avg(datediff(order_delivered_customer_date, order_purchase_timestamp)) as avg_days
from orders where order_status = 'delivered';

-- how many delivered orders arrived late?
select count(*) as late_orders from orders
where order_status = 'delivered'
and order_delivered_customer_date > order_estimated_delivery_date;

-- average review score for late orders
select avg(r.review_score) as avg_score_late
from orders o join order_reviews r 
on o.order_id = r.order_id
where o.order_delivered_customer_date > o.order_estimated_delivery_date;

-- average review score for on-time orders
select avg(r.review_score) as avg_score_on_time
from orders o join order_reviews r 
on o.order_id = r.order_id
where o.order_delivered_customer_date <= o.order_estimated_delivery_date;