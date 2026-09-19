-- =========================================================
-- ECommerce Sales Customer Analytics
-- Schema: MySQL 8.0+
-- =========================================================

USE ecommerce_analytics;

# 1. Completed orders, units, revenue and profit
SELECT
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(oi.quantity) AS total_units,
    SUM(oi.net_sales) AS total_revenue,
    SUM(oi.profit) AS total_profit
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed';

# 2. Monthly revenue/profit/orders
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    SUM(oi.net_sales) AS revenue,
    SUM(oi.profit) AS profit,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY orders_count DESC;

# 3. Month-over-month revenue growth
WITH revenue_growth AS (
	SELECT
		DATE_FORMAT(order_date,'%Y-%m') AS order_month,
		SUM(net_sales) AS revenue
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY order_month
)
SELECT
	order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month) AS prev_sales,
    revenue - LAG(revenue) OVER (ORDER BY order_month) AS mon_mon_sales,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month))*100,2) AS mon_growth_pct
FROM revenue_growth
GROUP BY order_month,revenue
ORDER BY mon_growth_pct DESC;

# 4.Top 10 products by revenue
SELECT
	p.product_id,
    p.product_name,
    SUM(oi.net_sales) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

# 5. Top categories by revenue and profit
SELECT
	p.category,
    SUM(oi.net_sales) AS total_revenue,
    SUM(oi.profit) AS total_profit
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

# 6.High revenue but low margin products
SELECT
	product_id,
    total_revenue,
    total_profit,
    ROUND((total_profit / total_revenue)*100,2) AS profit_margin
FROM (
SELECT
	p.product_id,
    SUM(oi.net_sales) AS total_revenue,
    SUM(oi.profit) AS total_profit
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id) AS t
ORDER BY total_revenue DESC, profit_margin ASC;

#7. Average order value
SELECT
    SUM(net_sales) AS total_revenue,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(net_sales)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM order_items;

# 8. Top 20 customers by revenue
SELECT
	c.customer_id,
    c.customer_name,
    SUM(oi.net_sales) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC
LIMIT 20;

# 9. Repeat customers
SELECT
	c.customer_id,
    COUNT(o.order_id) AS orders_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING COUNT(o.order_id) > 1
ORDER BY orders_count DESC;

# 10. New vs returning customer revenue by month
WITH customer_revenue AS (
	SELECT
		o.order_id,
        DATE_FORMAT(o.order_date,'%Y-%m') as order_month,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS rnk
	FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)

SELECT
    cr.order_month,
    CASE WHEN cr.rnk=1 THEN 'New' ELSE 'Returning' END AS customer_type,
    SUM(oi.net_sales) AS total_revenue
FROM customer_revenue cr
JOIN order_items oi ON cr.order_id = oi.order_id
GROUP BY cr.order_month, CASE WHEN cr.rnk=1 THEN 'New' ELSE 'Returning' END;
        
# 11. Product rank within category
SELECT
	product_id,
    product_name,
    category,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY unit_cost) AS product_rnk
FROM products;

# 12. Return rate by category
SELECT
	p.category,
    COUNT(DISTINCT r.order_id) AS return_orders,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND((COUNT(DISTINCT r.order_id) / COUNT(DISTINCT oi.order_id)),2) AS return_rate_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN returns r ON oi.order_id = r.order_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

# 13. Top return reasons
SELECT
	return_reason,
    COUNT(return_reason) AS reason_count
FROM returns
GROUP BY return_reason
ORDER BY reason_count DESC;

# 14. Payment failure rate by method
SELECT
	payment_method,
	COUNT(DISTINCT order_id) AS total_orders,
    COUNT(CASE WHEN payment_status='Failed' THEN 1 END) AS failed_count,
    ROUND(
		COUNT(CASE WHEN payment_status='Failed' THEN 1 END) *100 /COUNT(DISTINCT order_id),2
	) AS failed_rate_pct
FROM payments
GROUP BY payment_method
ORDER BY failed_rate_pct DESC;

# 15. Average delivery days by mode/region
SELECT
	s.shipping_mode,
    c.region,
    ROUND(AVG(DATEDIFF(delivery_date,dispatch_date)),2) AS avg_delivery_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN shipping s ON o.order_id = s.order_id
GROUP BY s.shipping_mode, c.region
ORDER BY avg_delivery_days DESC;

# 16. Customers above average revenue
WITH revenue AS (
	SELECT
		c.customer_id,
        SUM(oi.net_sales) AS total_revenue
	FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
)
SELECT
	customer_id,
    total_revenue
FROM revenue
WHERE total_revenue > (SELECT AVG(total_revenue) FROM revenue)
ORDER BY total_revenue DESC;

# 17. Customers with no recent order
SELECT
	c.customer_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
WHERE o.order_id IS NULL;

# 18. Reusable customer sales VIEW
CREATE VIEW customer_sales AS
SELECT
	c.customer_id,
    c.customer_name,
    SUM(oi.net_sales) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name;

SELECT * FROM customer_sales;

# 19. Top 20% customers by revenue
WITH customer_revenue AS (
	SELECT
		c.customer_id,
        SUM(oi.net_sales) AS total_revenue
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
),
rank_revenue AS (
	SELECT
		customer_id,
        total_revenue,
        NTILE(5) OVER (ORDER BY total_revenue DESC) AS revenue_rnk
	FROM customer_revenue
)

SELECT
	customer_id,
    total_revenue
FROM rank_revenue
WHERE revenue_rnk=1
ORDER BY total_revenue DESC;

# 20. Profit contribution by product
WITH product_profit AS (
	SELECT
		p.product_id,
        p.product_name,
        SUM(oi.profit) AS total_profit
	FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT
	product_id,
    product_name,
    total_profit,
    ROUND(total_profit*100 / SUM(total_profit) OVER (),2) AS profit_contribution_pct
FROM product_profit
ORDER BY profit_contribution_pct DESC;