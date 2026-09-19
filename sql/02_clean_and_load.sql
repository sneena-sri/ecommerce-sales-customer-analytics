-- =========================================================
-- ECommerce Sales Customer Analytics
-- Schema: MySQL 8.0+
-- =========================================================

USE ecommerce_analytics;


DESCRIBE customers;
DESCRIBE products;
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE payments;
DESCRIBE shipping;
DESCRIBE returns;

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM shipping;
SELECT COUNT(*) FROM returns;

SELECT * FROM customers LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
SELECT * FROM payments LIMIT 5;
SELECT * FROM shipping LIMIT 5;
SELECT * FROM returns LIMIT 5;

SELECT COUNT(*)
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;