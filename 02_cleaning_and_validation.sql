-- 02_cleaning_and_validation.sql
-- Duplicate checks, primary keys, missing values, data quality and referential integrity checks.

USE olist_ecommerce;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
SELECT * FROM customers LIMIT 5;

-- CHECKING FOR DUPLICATES
select order_id , count(*) as cnt from orders group by order_id having cnt>1;
select customer_id , count(*) as cnt from customers group by customer_id having cnt>1;
select product_id, count(*) as cnt from products group by product_id having cnt>1;
select seller_id, count(*) as cnt from sellers group by seller_id having cnt>1;
select review_id, count(*) AS cnt from order_reviews group by review_id having cnt > 1;
select order_id, order_item_id, count(*) as cnt from order_items 
group by order_id, order_item_id having cnt > 1;
select order_id, payment_sequential, count(*) as cnt from order_payments
group by order_id, payment_sequential having cnt > 1;
select product_category_name, count(*) as cnt from category_translation 
group by product_category_name having cnt > 1;
-- 7 of 8 tables are clean, and only order_reviews has repeated review_id values

-- we are checking how many id repeat in order_reviews
-- below is a derived table
select count(*) as repeated_review_ids
from (select review_id from order_reviews group by review_id having count(*) > 1) t;

select * from order_reviews;
select review_id, order_id, count(*) AS cnt from order_reviews group by review_id,order_id having cnt > 1;
-- this pair is unique

-- we add pk now
alter table orders add primary key (order_id);
alter table customers add primary key (customer_id);
alter table products add primary key (product_id);
alter table sellers add primary key (seller_id);
alter table order_items add primary key (order_id, order_item_id);
alter table order_payments add primary key (order_id, payment_sequential);
alter table order_reviews add primary key (review_id, order_id);
alter table category_translation add primary key (product_category_name);

-- This query checks that all 8 primary keys were created
select table_name, group_concat(column_name order by seq_in_index) as key_columns
from information_schema.statistics
where table_schema = 'olist_ecommerce' and index_name = 'PRIMARY'
group by table_name;

-- checking missing values
-- missing dates orders table 
select * from orders;
select count(*) as total_orders,
sum(order_approved_at is null) as no_approval_date,
sum(order_delivered_carrier_date is null) as no_carrier_date,
sum(order_delivered_customer_date is null) as no_delivery_date
from orders;

-- How many orders are in each status?
select order_status, count(*) as cnt from orders
group by order_status order by cnt desc;

-- Which statuses have no delivery date?
select order_status, count(*) as cnt
from orders where order_delivered_customer_date is null
group by order_status order by cnt desc;

-- Other columns in orders
select sum(customer_id is null or customer_id = '') as no_customer,
sum(order_status is null or order_status = '') as no_status,
sum(order_purchase_timestamp is null) as no_purchase_date
from orders;

-- customers
select * from customers;
select sum(customer_unique_id is null or customer_unique_id = '') as no_unique_id,
sum(customer_city is null or customer_city = '') as no_city,
sum(customer_state is null or customer_state = '') as no_state
from customers;

-- sellers
select * from sellers;
select sum(seller_city is null or seller_city = '') as no_city,
sum(seller_state is null or seller_state = '') as no_state from sellers;

-- products
select * from products;
select count(*) as total_products, sum(product_category_name is null or product_category_name = '') as no_category,
sum(product_weight_g is null) as no_weight,
sum(product_photos_qty is null) as no_photos from products;

-- order_items
select * from order_items;
select sum(product_id is null or product_id = '') as no_product, sum(seller_id is null or seller_id = '') as no_seller,
sum(price is null) as no_price, sum(freight_value is null) as no_freight from order_items;

-- order_payments
select * from order_payments;
select sum(payment_type is null or payment_type = '') as no_payment_type,
sum(payment_value is null) as no_value from order_payments;

-- order_reviews
select * from order_reviews;
select count(*) as total_reviews,sum(review_score is null) as no_score,
sum(review_comment_title is null or review_comment_title = '') as no_title,
sum(review_comment_message is null or review_comment_message = '') as no_message
from order_reviews;

-- label blank categories in products table
set sql_safe_updates = 0;
update products
set product_category_name = 'unknown'
where product_category_name is null or product_category_name = '';

select count(*) as still_blank
from products
where product_category_name is null or product_category_name = '';

select count(*) as delivered_no_date from orders
where order_status = 'delivered'
and order_delivered_customer_date is null;
-- It counts the orders whose status says delivered but whose delivery date is blank

select order_id, order_purchase_timestamp, order_delivered_carrier_date,
order_delivered_customer_date, order_estimated_delivery_date
from orders where order_status = 'delivered'
and order_delivered_customer_date is null;

-- orders that are not marked delivered but still have a delivery date.
-- reverse check 
select order_status, count(*) as cnt from orders
where order_delivered_customer_date is not null
and order_status <> 'delivered' group by order_status;

-- dates in an impossible order
select count(*) as delivered_before_purchase
from orders
where order_delivered_customer_date < order_purchase_timestamp;

-- Items whose order is missing from orders
select count(*) as orphan_items
from order_items
where order_id not in (select order_id from orders);

-- the same check for payments
select count(*) as orphan_payments
from order_payments
where order_id not in (select order_id from orders);

-- the same check for reviews
select count(*) as orphan_reviews
from order_reviews
where order_id not in (select order_id from orders);

-- the same check for customers
select count(*) as orphan_orders
from orders
where customer_id not in (select customer_id from customers);

-- the same check for products
select count(*) as orphan_products
from order_items
where product_id not in (select product_id from products);

-- the same check for sellers
select count(*) as orphan_sellers
from order_items
where seller_id not in (select seller_id from sellers);