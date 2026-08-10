--IMPORT DATA

CREATE TABLE customers (
    customer_id BIGINT,
    customer_name VARCHAR(150),
    email VARCHAR(200),
    phone VARCHAR(30),
    address TEXT,
    area VARCHAR(100),
    pincode VARCHAR(10),
    registration_date DATE,
    customer_segment VARCHAR(50),
    total_orders INTEGER,
    avg_order_value NUMERIC(12,2)
);

select * from customers;

CREATE TABLE products (
    product_id BIGINT,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(150),
    price NUMERIC(12,2),
    mrp NUMERIC(12,2),
    margin_percentage NUMERIC(10,2),
    shelf_life_days INTEGER,
    min_stock_level INTEGER,
    max_stock_level INTEGER
);

CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    order_date TIMESTAMP,
    promised_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    delivery_status VARCHAR(50),
    order_total NUMERIC(12,2),
    payment_method VARCHAR(50),
    delivery_partner_id BIGINT,
    store_id BIGINT
);

select * from orders;

CREATE TABLE order_items (
    order_id BIGINT,
    product_id BIGINT,
    quantity INTEGER,
    unit_price NUMERIC(12,2)
);

select * from order_items;

CREATE TABLE delivery_performance (
    order_id BIGINT,
    delivery_partner_id BIGINT,
    promised_time TIMESTAMP,
    actual_time TIMESTAMP,
    delivery_time_minutes NUMERIC(10,2),
    distance_km NUMERIC(10,2),
    delivery_status VARCHAR(50),
    reasons_if_delayed VARCHAR(200)
);

select * from delivery_performance;

CREATE TABLE customer_feedback (
    feedback_id BIGINT,
    order_id BIGINT,
    customer_id BIGINT,
    rating INTEGER,
    feedback_text TEXT,
    feedback_category VARCHAR(100),
    sentiment VARCHAR(50),
    feedback_date DATE
);

select * from customer_feedback;

CREATE TABLE marketing_performance (
    campaign_id BIGINT,
    campaign_name VARCHAR(150),
    campaign_date DATE,
    target_audience VARCHAR(100),
    channel VARCHAR(50),
    impressions INTEGER,
    clicks INTEGER,
    conversions INTEGER,
    spend NUMERIC(14,2),
    revenue_generated NUMERIC(14,2),
    roas NUMERIC(10,2)
);

select * from marketing_performance;

CREATE TABLE inventory (
    product_id BIGINT,
    inventory_date_text VARCHAR(20),
    stock_received INTEGER,
    damaged_stock INTEGER
);

select * from inventory;

CREATE TABLE inventory_new (
    product_id BIGINT,
    inventory_month_text VARCHAR(20),
    stock_received INTEGER,
    damaged_stock INTEGER
);

select * from inventory_new;

CREATE TABLE products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    brand VARCHAR(100),
    price NUMERIC(10,2),
    mrp NUMERIC(10,2),
    margin_percentage NUMERIC(5,2),
    shelf_life_days INT,
    min_stock_level INT,
    max_stock_level INT
);

select * from products;

-- Check row counts
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'delivery_performance', COUNT(*) FROM delivery_performance
UNION ALL
SELECT 'customer_feedback', COUNT(*) FROM customer_feedback
UNION ALL
SELECT 'marketing_performance', COUNT(*) FROM marketing_performance
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory;

-- Check duplicate IDs
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check missing values
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_name,
    COUNT(*) FILTER (WHERE area IS NULL) AS missing_area
FROM customers;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_total IS NULL) AS missing_total
FROM orders;

-- Check broken relationships
SELECT COUNT(*) AS invalid_customer_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS invalid_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS invalid_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Add  foreign keys

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

--EXPLORATORY DATA ANLAYSIS

-- SECTION A: OVERALL KPIs

-- 1. Total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- 2. Total products
SELECT COUNT(*) AS total_products
FROM products;

-- 3. Total orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- 4. Total revenue
SELECT ROUND(SUM(order_total), 2) AS total_revenue
FROM orders;

-- 5. Average order value
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM orders;

-- 6. Total quantity sold
SELECT SUM(quantity) AS total_quantity_sold
FROM order_items;

-- 7. Total unique customers who placed orders
SELECT COUNT(DISTINCT customer_id) AS active_customers
FROM orders;

-- 8. Order date range
SELECT
    MIN(order_date)::date AS first_order_date,
    MAX(order_date)::date AS last_order_date
FROM orders;


-- SECTION B: SALES ANALYSIS

-- 9. Daily revenue
SELECT
    order_date::date AS order_day,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY order_date::date
ORDER BY order_day;

-- 10. Monthly revenue
SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- 11. Revenue by year
SELECT
    EXTRACT(YEAR FROM order_date)::int AS order_year,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;

-- 12. Revenue by day of week
SELECT
    TO_CHAR(order_date, 'Day') AS day_name,
    EXTRACT(DOW FROM order_date) AS day_number,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(DOW FROM order_date)
ORDER BY day_number;

-- 13. Revenue by hour
SELECT
    EXTRACT(HOUR FROM order_date)::int AS order_hour,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY EXTRACT(HOUR FROM order_date)
ORDER BY order_hour;

-- 14. Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue,
    ROUND(AVG(order_total), 2) AS avg_order_value
FROM orders
GROUP BY payment_method
ORDER BY revenue DESC;

-- 15. Revenue by delivery status
SELECT
    delivery_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_total), 2) AS revenue
FROM orders
GROUP BY delivery_status
ORDER BY revenue DESC;

-- 16. Top 10 highest-value orders
SELECT
    order_id,
    customer_id,
    order_date,
    order_total,
    payment_method
FROM orders
ORDER BY order_total DESC
LIMIT 10;

-- 17. Average daily revenue
WITH daily_sales AS (
    SELECT
        order_date::date AS order_day,
        SUM(order_total) AS daily_revenue
    FROM orders
    GROUP BY order_date::date
)
SELECT ROUND(AVG(daily_revenue), 2) AS average_daily_revenue
FROM daily_sales;

-- SECTION C: CUSTOMER ANALYSIS
-- 18. Top 10 customers by spending
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_total), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 19. Top 10 customers by number of orders
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC
LIMIT 10;

-- 20. Revenue by customer segment
SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_total), 2) AS revenue,
    ROUND(AVG(o.order_total), 2) AS avg_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY revenue DESC;

-- 21. Revenue by area
SELECT
    c.area,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_total), 2) AS revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.area
ORDER BY revenue DESC;

-- 22. Repeat customers
SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;

-- 23. Customers who never placed an order
SELECT
    c.customer_id,
    c.customer_name,
    c.area
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 24. Customer lifetime value
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_total), 2) AS customer_lifetime_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY customer_lifetime_value DESC;

-- 25. New customer registrations by month
SELECT
    DATE_TRUNC('month', registration_date)::date AS registration_month,
    COUNT(*) AS new_customers
FROM customers
GROUP BY DATE_TRUNC('month', registration_date)
ORDER BY registration_month;

-- SECTION D: PRODUCT ANALYSIS
-- 26. Top 10 products by quantity sold
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC
LIMIT 10;

-- 27. Top 10 products by revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS product_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY product_revenue DESC
LIMIT 10;

-- 28. Revenue by category
SELECT
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- 29. Revenue by brand
SELECT
    p.brand,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.brand
ORDER BY revenue DESC;

-- 30. Average product price by category
SELECT
    category,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(AVG(mrp), 2) AS average_mrp
FROM products
GROUP BY category
ORDER BY average_price DESC;

-- 31. Products with highest margin percentage
SELECT
    product_id,
    product_name,
    category,
    brand,
    price,
    mrp,
    margin_percentage
FROM products
ORDER BY margin_percentage DESC
LIMIT 10;


-- SECTION E: DELIVERY ANALYSIS

-- 32. Average delivery time
SELECT
    ROUND(AVG(delivery_time_minutes), 2) AS average_delivery_minutes
FROM delivery_performance;

-- 33. Delivery status distribution
SELECT
    delivery_status,
    COUNT(*) AS total_deliveries,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM delivery_performance
GROUP BY delivery_status
ORDER BY total_deliveries DESC;

-- 34. On-time delivery percentage
SELECT
    COUNT(*) AS total_deliveries,
    COUNT(*) FILTER (
        WHERE actual_time <= promised_time
    ) AS on_time_deliveries,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE actual_time <= promised_time
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_percentage
FROM delivery_performance;

-- 35. Top delay reasons
SELECT
    reasons_if_delayed,
    COUNT(*) AS delay_count
FROM delivery_performance
WHERE reasons_if_delayed IS NOT NULL
  AND TRIM(reasons_if_delayed) <> ''
GROUP BY reasons_if_delayed
ORDER BY delay_count DESC;

-- 36. Average delivery time by distance group
SELECT
    CASE
        WHEN distance_km < 2 THEN 'Under 2 KM'
        WHEN distance_km < 5 THEN '2-5 KM'
        ELSE 'Above 5 KM'
    END AS distance_group,
    COUNT(*) AS deliveries,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_minutes
FROM delivery_performance
GROUP BY distance_group
ORDER BY avg_delivery_minutes;

-- 37. Delivery partner performance
SELECT
    delivery_partner_id,
    COUNT(*) AS total_deliveries,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_minutes,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE actual_time <= promised_time
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_percentage
FROM delivery_performance
GROUP BY delivery_partner_id
ORDER BY on_time_percentage DESC, avg_delivery_minutes;

-- SECTION F: FEEDBACK ANALYSIS


--38. Average customer rating
SELECT ROUND(AVG(rating), 2) AS average_rating
FROM customer_feedback;

-- 39. Rating distribution
SELECT
    rating,
    COUNT(*) AS feedback_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM customer_feedback
GROUP BY rating
ORDER BY rating DESC;

-- 40. Sentiment distribution
SELECT
    sentiment,
    COUNT(*) AS feedback_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM customer_feedback
GROUP BY sentiment
ORDER BY feedback_count DESC;

-- 41. Feedback categories with lowest ratings
SELECT
    feedback_category,
    COUNT(*) AS total_feedback,
    ROUND(AVG(rating), 2) AS average_rating
FROM customer_feedback
GROUP BY feedback_category
ORDER BY average_rating ASC, total_feedback DESC;

-- =========================
-- SECTION G: INVENTORY ANALYSIS
-- =========================

-- 42. Total stock received and damaged
SELECT
    SUM(stock_received) AS total_stock_received,
    SUM(damaged_stock) AS total_damaged_stock,
    ROUND(
        100.0 * SUM(damaged_stock)
        / NULLIF(SUM(stock_received), 0),
        2
    ) AS damage_percentage
FROM inventory;

-- 43. Products with highest damaged stock
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(i.stock_received) AS stock_received,
    SUM(i.damaged_stock) AS damaged_stock,
    ROUND(
        100.0 * SUM(i.damaged_stock)
        / NULLIF(SUM(i.stock_received), 0),
        2
    ) AS damage_percentage
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY damaged_stock DESC
LIMIT 10;


-- SECTION H: MARKETING ANALYSIS


-- 44. Marketing performance by channel
SELECT
    channel,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(conversions) AS conversions,
    ROUND(SUM(spend), 2) AS total_spend,
    ROUND(SUM(revenue_generated), 2) AS revenue_generated,
    ROUND(
        100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0),
        2
    ) AS ctr_percentage,
    ROUND(
        100.0 * SUM(conversions) / NULLIF(SUM(clicks), 0),
        2
    ) AS conversion_rate,
    ROUND(
        SUM(revenue_generated) / NULLIF(SUM(spend), 0),
        2
    ) AS calculated_roas
FROM marketing_performance
GROUP BY channel
ORDER BY calculated_roas DESC;

-- 45. Top 10 campaigns by ROAS
SELECT
    campaign_id,
    campaign_name,
    channel,
    impressions,
    clicks,
    conversions,
    spend,
    revenue_generated,
    ROUND(
        revenue_generated / NULLIF(spend, 0),
        2
    ) AS calculated_roas
FROM marketing_performance
ORDER BY calculated_roas DESC
LIMIT 10;

select current_database();


	/* BUSINESS INSIGHTS
	
	1. Strong Overall Sales Performance: 
	   The business generated approximately ₹11.01 million in total revenue from 5,000 orders**, with an average order value 
	   of around ₹2,201.86. This indicates a relatively strong customer spending level per transaction.
	
	2. Regular Customers Generate the Highest Revenue: 
	   The Regular customer segment contributed the highest revenue at approximately ₹2.89 million, followed by New customers at ₹2.80 million. 
	   However, New customers recorded the highest average order value of approximately ₹2,287.93, showing good revenue potential from newly acquired customers.
	
	3. Delivery Performance Has Significant Improvement Potential:
	   Approximately 69.4% of orders were delivered on time, while 20.74% were slightly delayed and 9.86% were significantly delayed. 
	   This means around 30.6% of all deliveries experienced some level of delay, which can negatively affect customer satisfaction and repeat purchases.
	
	4. Traffic Is the Major Delivery Challenge:
	   Among delayed orders, traffic was recorded as the primary reason for delay. Slightly delayed orders averaged approximately 10.5 minutes late,
	   while significantly delayed orders averaged about 22.8 minutes late suggesting that route planning and delivery-partner efficiency are important 
	   operational improvement areas.
	
	5. Customer Satisfaction Is Moderate:
	   The overall average customer rating was approximately 3.34 out of 5. Only around 32.4% of feedback was positive, while approximately 32.84% was 
	   negative and 34.76% was neutral. Product Quality recorded the lowest average rating among the major feedback categories, indicating an opportunity
	   to improve product consistency.
	
	6. Dairy & Breakfast Is the Leading Product Category:
	   Based on order-item sales, Dairy & Breakfast generated the highest product revenue at approximately ₹639K, followed by Pharmacy at approximately 
	   ₹592K and Fruits & Vegetables at approximately ₹559K. These categories represent important revenue-driving areas for the business.
	
	7. Card Is the Leading Payment Method:
	   Card payments generated approximately ₹2.87 million in revenue, the highest among the available payment methods. However, revenue was
	   reasonably balanced across Card, Cash, Wallet and UPI, indicating that customers actively use multiple payment options.
	
	8. Marketing Generates Positive Returns but Can Be Optimized:
	   The marketing dataset recorded approximately ₹16.32 million in total campaign spend and ₹32.19 million in attributed revenue, producing an overall 
	   calculated ROAS of approximately 1.97. Email produced the strongest channel-level calculated ROAS at roughly **2.05**, while the Referral Program 
	   was the strongest campaign at approximately 2.03 ROAS.
	
	9. New Users Are an Attractive Marketing Segment:
	   Marketing campaigns targeting New Users generated approximately ₹8.14 million in revenue and achieved the highest audience-level calculated ROAS of
	   about 1.99. This suggests that customer acquisition campaigns are contributing effectively to revenue generation.
	
	10. Inventory Data Shows a Major Operational and Data-Quality Concern:
	    The inventory table reports approximately 147,526 units received and 80,268 units damaged, implying a very high reported damage rate of approximately 
		54.4%. Household Care shows the highest category-level reported damage rate at about 68.2%. Some product records even show damaged stock exceeding 
		received stock, indicating that inventory processes or source-data validation should be investigated before these figures are used for financial 
		decision-making.
	
	## BUSINESS RECOMMENDATIONS
	
	Blinkit should focus on improving delivery efficiency because nearly one-third of orders experience some level of delay. better route optimization, 
	delivery-partner allocation and traffic-based delivery planning can help increase the on-time delivery rate and improve the customer experience.
	
	the company should develop stronger retention campaigns for new and regular customers. new customers already show the highest average order value, so 
	personalized offers, loyalty rewards and repeat-purchase incentives can help convert them into long-term regular or premium customers.
	
	more attention should be given to product quality because it has the lowest average feedback rating. supplier quality checks, packaging improvements, expiry 
	monitoring and customer complaint analysis should be strengthened to increase positive ratings and reduce negative feedback.
	
	dairy & breakfast, pharmacy and fruits & vegetables should receive strong inventory availability and merchandising support because they are leading
	revenue-generating categories. high-performing products within these categories should be prioritized to avoid stock-outs.
	
	marketing budgets should be gradually shifted toward campaigns and channels with stronger measured returns, particularly email and referral program 
	campaigns. campaigns with weaker roas should be tested and optimized rather than receiving equal budget allocation.
	
	the inventory dataset should be audited before making stock-loss decisions. validation rules should be introduced to prevent impossible values such as
	damaged quantity exceeding received quantity. once data quality is corrected, blinkit should investigate categories with genuinely high damage rates and 
	improve warehouse handling, storage conditions and supplier quality control.
	
	overall, the analysis shows that blinkit has strong revenue generation and customer spending, but the biggest opportunities lie in **improving delivery 
	reliability, customer satisfaction, marketing efficiency and inventory control. */
	
	

