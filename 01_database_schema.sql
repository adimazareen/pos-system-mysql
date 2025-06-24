-- =====================================================
-- POS SYSTEM - DATABASE SCHEMA
-- =====================================================
-- File: 01_database_schema.sql
-- Description: Creates database and all table structures
-- =====================================================

-- Drop database if exists and create new one
-- DROP DATABASE IF EXISTS pos_system;
-- CREATE DATABASE pos_system 
-- CHARACTER SET utf8mb4 
-- COLLATE utf8mb4_unicode_ci;

USE pos_system;

-- =====================================================
-- CORE TABLES CREATION
-- =====================================================

-- Categories Table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category_name (category_name),
    INDEX idx_category_active (is_active)
) ENGINE=InnoDB;

-- Stores Table
CREATE TABLE stores (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    manager_id INT,
    settings JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_store_name (store_name),
    INDEX idx_store_active (is_active)
) ENGINE=InnoDB;

-- Users Table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('cashier', 'manager', 'admin') NOT NULL DEFAULT 'cashier',
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    store_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_role (role),
    INDEX idx_user_active (is_active),
    INDEX idx_user_store (store_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Add foreign key constraint for store manager
ALTER TABLE stores 
ADD CONSTRAINT fk_store_manager 
FOREIGN KEY (manager_id) REFERENCES users(user_id) ON DELETE SET NULL;

-- Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    cost_price DECIMAL(10,2) DEFAULT 0 CHECK (cost_price >= 0),
    stock_quantity INT DEFAULT 0 CHECK (stock_quantity >= 0),
    min_stock_level INT DEFAULT 5 CHECK (min_stock_level >= 0),
    max_stock_level INT DEFAULT 1000,
    unit_of_measure VARCHAR(20) DEFAULT 'piece',
    attributes JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX idx_barcode (barcode),
    INDEX idx_product_name (product_name),
    INDEX idx_product_category (category_id),
    INDEX idx_product_price (price),
    INDEX idx_stock_quantity (stock_quantity),
    INDEX idx_product_active (is_active),
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    address TEXT,
    date_of_birth DATE,
    loyalty_points INT DEFAULT 0 CHECK (loyalty_points >= 0),
    total_spent DECIMAL(12,2) DEFAULT 0 CHECK (total_spent >= 0),
    preferences JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_customer_phone (phone),
    INDEX idx_customer_email (email),
    INDEX idx_customer_name (customer_name),
    INDEX idx_loyalty_points (loyalty_points)
) ENGINE=InnoDB;

-- Discounts Table
CREATE TABLE discounts (
    discount_id INT AUTO_INCREMENT PRIMARY KEY,
    discount_name VARCHAR(100) NOT NULL,
    discount_type ENUM('percentage', 'fixed') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
    min_purchase_amount DECIMAL(10,2) DEFAULT 0,
    max_discount_amount DECIMAL(10,2) DEFAULT NULL,
    applicable_categories JSON,
    conditions JSON,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INT DEFAULT 0,
    max_usage INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_discount_dates (start_date, end_date),
    INDEX idx_discount_active (is_active),
    INDEX idx_discount_type (discount_type),
    CHECK (end_date >= start_date)
) ENGINE=InnoDB;

-- Sales Transactions Table
CREATE TABLE sales_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_number VARCHAR(50) NOT NULL UNIQUE,
    store_id INT NOT NULL,
    cashier_id INT NOT NULL,
    customer_id INT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    discount_amount DECIMAL(12,2) DEFAULT 0 CHECK (discount_amount >= 0),
    tax_rate DECIMAL(5,2) DEFAULT 0 CHECK (tax_rate >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    payment_method ENUM('cash', 'credit_card', 'debit_card', 'mobile_payment', 'loyalty_points') NOT NULL,
    payment_reference VARCHAR(100),
    status ENUM('pending', 'completed', 'cancelled', 'refunded', 'partial_refund') DEFAULT 'completed',
    loyalty_points_earned INT DEFAULT 0,
    loyalty_points_used INT DEFAULT 0,
    notes TEXT,
    
    UNIQUE INDEX idx_transaction_number (transaction_number),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_cashier (cashier_id),
    INDEX idx_customer (customer_id),
    INDEX idx_store (store_id),
    INDEX idx_status (status),
    INDEX idx_payment_method (payment_method),
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE RESTRICT,
    FOREIGN KEY (cashier_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Sale Items Table
CREATE TABLE sale_items (
    sale_item_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
    
    INDEX idx_transaction (transaction_id),
    INDEX idx_product (product_id),
    FOREIGN KEY (transaction_id) REFERENCES sales_transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Receipts Table
CREATE TABLE receipts (
    receipt_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL UNIQUE,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    receipt_data JSON NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    printed_at TIMESTAMP NULL,
    email_sent_at TIMESTAMP NULL,
    
    INDEX idx_receipt_number (receipt_number),
    INDEX idx_generated_at (generated_at),
    FOREIGN KEY (transaction_id) REFERENCES sales_transactions(transaction_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Returns Table
CREATE TABLE returns (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    return_number VARCHAR(50) NOT NULL UNIQUE,
    original_transaction_id INT NOT NULL,
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cashier_id INT NOT NULL,
    customer_id INT,
    total_return_amount DECIMAL(12,2) NOT NULL CHECK (total_return_amount >= 0),
    reason VARCHAR(255),
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'completed',
    notes TEXT,
    
    UNIQUE INDEX idx_return_number (return_number),
    INDEX idx_return_date (return_date),
    INDEX idx_original_transaction (original_transaction_id),
    INDEX idx_return_cashier (cashier_id),
    FOREIGN KEY (original_transaction_id) REFERENCES sales_transactions(transaction_id) ON DELETE RESTRICT,
    FOREIGN KEY (cashier_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Return Items Table
CREATE TABLE return_items (
    return_item_id INT AUTO_INCREMENT PRIMARY KEY,
    return_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
    
    INDEX idx_return (return_id),
    INDEX idx_return_product (product_id),
    FOREIGN KEY (return_id) REFERENCES returns(return_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Inventory Logs Table
CREATE TABLE inventory_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    change_type ENUM('sale', 'return', 'restock', 'adjustment', 'damaged', 'expired') NOT NULL,
    quantity_change INT NOT NULL,
    old_quantity INT NOT NULL,
    new_quantity INT NOT NULL,
    reference_id INT,
    reference_type ENUM('sale', 'return', 'restock', 'adjustment'),
    user_id INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    INDEX idx_product_log (product_id),
    INDEX idx_store_log (store_id),
    INDEX idx_change_type (change_type),
    INDEX idx_timestamp (timestamp),
    INDEX idx_user_log (user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Audit Logs Table
CREATE TABLE audit_logs (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_table_name (table_name),
    INDEX idx_operation (operation),
    INDEX idx_timestamp (timestamp),
    INDEX idx_user_audit (user_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- VIEWS FOR REPORTING
-- =====================================================

-- Daily Sales Report View
CREATE VIEW daily_sales_report AS
SELECT 
    DATE(st.transaction_date) as sale_date,
    s.store_name,
    COUNT(st.transaction_id) as total_transactions,
    SUM(st.subtotal) as total_subtotal,
    SUM(st.discount_amount) as total_discounts,
    SUM(st.tax_amount) as total_tax,
    SUM(st.total_amount) as total_sales,
    AVG(st.total_amount) as average_transaction_value,
    COUNT(DISTINCT st.customer_id) as unique_customers
FROM sales_transactions st
JOIN stores s ON st.store_id = s.store_id
WHERE st.status = 'completed'
GROUP BY DATE(st.transaction_date), s.store_id, s.store_name
ORDER BY sale_date DESC, s.store_name;

-- Product Sales Performance View
CREATE VIEW product_sales_performance AS
SELECT 
    p.product_id,
    p.barcode,
    p.product_name,
    c.category_name,
    COUNT(si.sale_item_id) as times_sold,
    SUM(si.quantity) as total_quantity_sold,
    SUM(si.line_total) as total_revenue,
    AVG(si.unit_price) as average_selling_price,
    p.cost_price,
    SUM(si.line_total) - (SUM(si.quantity) * p.cost_price) as total_profit,
    p.stock_quantity as current_stock,
    CASE 
        WHEN p.stock_quantity <= p.min_stock_level THEN 'Low Stock'
        WHEN p.stock_quantity = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END as stock_status
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN sale_items si ON p.product_id = si.product_id
LEFT JOIN sales_transactions st ON si.transaction_id = st.transaction_id 
    AND st.status = 'completed'
GROUP BY p.product_id, p.barcode, p.product_name, c.category_name, 
         p.cost_price, p.stock_quantity, p.min_stock_level
ORDER BY total_revenue DESC;

-- Low Stock Alert View
CREATE VIEW low_stock_alerts AS
SELECT 
    p.product_id,
    p.barcode,
    p.product_name,
    c.category_name,
    p.stock_quantity,
    p.min_stock_level,
    p.max_stock_level,
    (p.max_stock_level - p.stock_quantity) as suggested_reorder_quantity,
    p.cost_price,
    (p.max_stock_level - p.stock_quantity) * p.cost_price as estimated_reorder_cost,
    p.updated_at as last_updated
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.stock_quantity <= p.min_stock_level 
  AND p.is_active = TRUE
ORDER BY (p.stock_quantity / NULLIF(p.min_stock_level, 0)) ASC;

-- Customer Purchase Summary View
CREATE VIEW customer_purchase_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.phone,
    c.email,
    c.loyalty_points,
    c.total_spent,
    COUNT(st.transaction_id) as total_transactions,
    AVG(st.total_amount) as average_purchase_amount,
    MAX(st.transaction_date) as last_purchase_date,
    DATEDIFF(CURDATE(), MAX(st.transaction_date)) as days_since_last_purchase
FROM customers c
LEFT JOIN sales_transactions st ON c.customer_id = st.customer_id
    AND st.status = 'completed'
GROUP BY c.customer_id, c.customer_name, c.phone, c.email, 
         c.loyalty_points, c.total_spent
ORDER BY c.total_spent DESC;

-- Cashier Performance View
CREATE VIEW cashier_performance AS
SELECT 
    u.user_id,
    u.full_name as cashier_name,
    s.store_name,
    DATE(st.transaction_date) as work_date,
    COUNT(st.transaction_id) as transactions_processed,
    SUM(st.total_amount) as total_sales_amount,
    AVG(st.total_amount) as average_transaction_value,
    COUNT(DISTINCT st.customer_id) as unique_customers_served
FROM users u
JOIN sales_transactions st ON u.user_id = st.cashier_id
JOIN stores s ON u.store_id = s.store_id
WHERE u.role = 'cashier' AND st.status = 'completed'
GROUP BY u.user_id, u.full_name, s.store_name, DATE(st.transaction_date)
ORDER BY work_date DESC, total_sales_amount DESC;

-- Monthly Sales Trend View
CREATE VIEW monthly_sales_trend AS
SELECT 
    YEAR(st.transaction_date) as sale_year,
    MONTH(st.transaction_date) as sale_month,
    MONTHNAME(st.transaction_date) as month_name,
    s.store_name,
    COUNT(st.transaction_id) as total_transactions,
    SUM(st.total_amount) as total_sales,
    AVG(st.total_amount) as average_transaction_value,
    COUNT(DISTINCT st.customer_id) as unique_customers
FROM sales_transactions st
JOIN stores s ON st.store_id = s.store_id
WHERE st.status = 'completed'
GROUP BY YEAR(st.transaction_date), MONTH(st.transaction_date), 
         MONTHNAME(st.transaction_date), s.store_name
ORDER BY sale_year DESC, sale_month DESC, s.store_name;

-- Top Selling Products View
CREATE VIEW top_selling_products AS
SELECT 
    p.product_id,
    p.barcode,
    p.product_name,
    c.category_name,
    SUM(si.quantity) as total_quantity_sold,
    SUM(si.line_total) as total_revenue,
    COUNT(DISTINCT si.transaction_id) as number_of_sales,
    AVG(si.unit_price) as average_selling_price,
    (SUM(si.line_total) - (SUM(si.quantity) * p.cost_price)) as total_profit_margin
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN sale_items si ON p.product_id = si.product_id
JOIN sales_transactions st ON si.transaction_id = st.transaction_id
WHERE st.status = 'completed'
  AND st.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.product_id, p.barcode, p.product_name, c.category_name, p.cost_price
ORDER BY total_quantity_sold DESC
LIMIT 20;

-- Returns Analysis View
CREATE VIEW returns_analysis AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(ri.return_item_id) as return_frequency,
    SUM(ri.quantity) as total_returned_quantity,
    SUM(ri.line_total) as total_return_amount,
    AVG(ri.line_total) as average_return_value,
    GROUP_CONCAT(DISTINCT r.reason SEPARATOR '; ') as common_reasons
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN return_items ri ON p.product_id = ri.product_id
JOIN returns r ON ri.return_id = r.return_id
WHERE r.status = 'completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY return_frequency DESC;

COMMIT;
