-- =========================================================
-- ECommerce Sales Customer Analytics
-- Schema: MySQL 8.0+
-- =========================================================

CREATE DATABASE IF NOT EXISTS ecommerce_analytics;

USE ecommerce_analytics;

-- Drop tables if re-running (order matters due to FKs)
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS shipping;
DROP TABLE IF EXISTS returns;

-- ---------------------------------------------------------
-- customers
-- ---------------------------------------------------------
CREATE TABLE customers (
	customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(20) NOT NULL,
    signup_date DATE NOT NULL,
    segment ENUM('Small Business','Consumer','Corporate') NOT NULL,
    city VARCHAR(15),
    region VARCHAR(10),
    acquisition_channel VARCHAR(25)
);

-- ---------------------------------------------------------
-- products
-- ---------------------------------------------------------
CREATE TABLE products (
	product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(30) NOT NULL,
    category VARCHAR(20),
    subcategory VARCHAR(20),
    unit_cost DECIMAL(10,2) NOT NULL,
    list_price DECIMAL(10,2) NOT NULL,
    product_tier ENUM('Premium','Standard','Value') NOT NULL
);

-- ---------------------------------------------------------
-- orders
-- ---------------------------------------------------------
CREATE TABLE orders (
	order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE NOT NULL,
    sales_channel VARCHAR(20),
    payment_method VARCHAR(15) NOT NULL,
    order_status VARCHAR(15) NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

-- ---------------------------------------------------------
-- order_items
-- ---------------------------------------------------------
CREATE TABLE order_items (
	order_item_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    discount_pct DECIMAL(10,2) NOT NULL,
    gross_sales	DECIMAL(10,2) NOT NULL,
    net_sales DECIMAL(10,2) NOT NULL,
	profit DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_orderitems_orderid FOREIGN KEY(order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_orderitems_product FOREIGN KEY(product_id) REFERENCES products(product_id)
);

-- ---------------------------------------------------------
-- payments
-- ---------------------------------------------------------
CREATE TABLE payments (
	order_id VARCHAR(10) PRIMARY KEY,
    payment_method VARCHAR(15) NOT NULL,
    payment_status ENUM('Failed','Paid','Refunded') NOT NULL,
	transaction_date DATE NOT NULL,
	order_amount DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_payment_orderid FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- ---------------------------------------------------------
-- shipping
-- ---------------------------------------------------------
CREATE TABLE shipping (
	order_id VARCHAR(10) PRIMARY KEY,
    shipping_mode VARCHAR(20) NOT NULL,
    dispatch_date DATE NOT NULL,
    delivery_date DATE NOT NULL,
    shipping_cost DECIMAL(10,2),
    CONSTRAINT fk_shipping_orderid FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- ---------------------------------------------------------
-- returns
-- ---------------------------------------------------------
CREATE TABLE returns (
	order_id VARCHAR(10) PRIMARY KEY,
    return_date DATE,
    return_reason VARCHAR(50),
    refund_amount DECIMAL(10,2),
    CONSTRAINT fk_returns_orderid FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

