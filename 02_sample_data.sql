-- =====================================================
-- POS SYSTEM - SAMPLE DATA
-- =====================================================
-- File: 02_sample_data.sql
-- Description: Inserts sample data for testing all features
-- =====================================================

USE pos_system;

-- =====================================================
-- SAMPLE DATA INSERTION (Max 10 entries per table)
-- =====================================================

-- Insert Categories
INSERT INTO categories (category_name, description) VALUES
('Beverages', 'Soft drinks, juices, water, and other beverages'),
('Snacks', 'Chips, crackers, nuts, and other snack items'),
('Dairy', 'Milk, cheese, yogurt, and dairy products'),
('Bakery', 'Bread, cakes, pastries, and baked goods'),
('Household', 'Cleaning supplies and household items'),
('Electronics', 'Small electronics and accessories'),
('Health & Beauty', 'Personal care and beauty products'),
('Frozen Foods', 'Frozen meals, ice cream, and frozen items');

-- Insert Stores
INSERT INTO stores (store_name, address, phone, email, settings) VALUES
('Main Store', '123 Main Street, Downtown, City 12345', '+1-555-0123', 'main@posstore.com', 
 JSON_OBJECT(
    'business_hours', JSON_OBJECT(
        'monday', JSON_OBJECT('open', '08:00', 'close', '22:00'),
        'tuesday', JSON_OBJECT('open', '08:00', 'close', '22:00'),
        'wednesday', JSON_OBJECT('open', '08:00', 'close', '22:00'),
        'thursday', JSON_OBJECT('open', '08:00', 'close', '22:00'),
        'friday', JSON_OBJECT('open', '08:00', 'close', '23:00'),
        'saturday', JSON_OBJECT('open', '09:00', 'close', '23:00'),
        'sunday', JSON_OBJECT('open', '10:00', 'close', '21:00')
    ),
    'tax_settings', JSON_OBJECT('default_tax_rate', 8.25),
    'receipt_settings', JSON_OBJECT('show_barcode', true, 'footer_message', 'Thank you for shopping with us!')
 )),
('Branch Store', '456 Oak Avenue, Suburb, City 67890', '+1-555-0456', 'branch@posstore.com', 
 JSON_OBJECT(
    'business_hours', JSON_OBJECT(
        'monday', JSON_OBJECT('open', '09:00', 'close', '21:00'),
        'tuesday', JSON_OBJECT('open', '09:00', 'close', '21:00'),
        'wednesday', JSON_OBJECT('open', '09:00', 'close', '21:00'),
        'thursday', JSON_OBJECT('open', '09:00', 'close', '21:00'),
        'friday', JSON_OBJECT('open', '09:00', 'close', '22:00'),
        'saturday', JSON_OBJECT('open', '10:00', 'close', '22:00'),
        'sunday', JSON_OBJECT('open', '11:00', 'close', '20:00')
    ),
    'tax_settings', JSON_OBJECT('default_tax_rate', 8.25)
 ));

-- Insert Users
INSERT INTO users (username, password_hash, role, full_name, email, phone, store_id) VALUES
('admin', SHA2('admin123', 256), 'admin', 'System Administrator', 'admin@posstore.com', '+1-555-0100', 1),
('manager1', SHA2('manager123', 256), 'manager', 'John Manager', 'john.manager@posstore.com', '+1-555-0101', 1),
('cashier1', SHA2('cashier123', 256), 'cashier', 'Alice Cashier', 'alice.cashier@posstore.com', '+1-555-0102', 1),
('cashier2', SHA2('cashier123', 256), 'cashier', 'Bob Cashier', 'bob.cashier@posstore.com', '+1-555-0103', 1),
('manager2', SHA2('manager123', 256), 'manager', 'Sarah Manager', 'sarah.manager@posstore.com', '+1-555-0201', 2),
('cashier3', SHA2('cashier123', 256), 'cashier', 'Charlie Cashier', 'charlie.cashier@posstore.com', '+1-555-0202', 2);

-- Update store managers
UPDATE stores SET manager_id = 2 WHERE store_id = 1;
UPDATE stores SET manager_id = 5 WHERE store_id = 2;

-- Insert Products
INSERT INTO products (barcode, product_name, category_id, price, cost_price, stock_quantity, min_stock_level, max_stock_level, attributes) VALUES
('1234567890123', 'Coca Cola 500ml', 1, 1.99, 1.20, 100, 20, 200, 
 JSON_OBJECT('weight', '500ml', 'brand', 'Coca Cola', 'calories', 140)),
('2345678901234', 'Pepsi 500ml', 1, 1.89, 1.15, 80, 20, 200, 
 JSON_OBJECT('weight', '500ml', 'brand', 'Pepsi', 'calories', 150)),
('3456789012345', 'Bottled Water 1L', 1, 0.99, 0.45, 200, 50, 300, 
 JSON_OBJECT('weight', '1L', 'brand', 'Pure Water', 'calories', 0)),
('4567890123456', 'Potato Chips 150g', 2, 2.49, 1.50, 60, 15, 100, 
 JSON_OBJECT('weight', '150g', 'brand', 'Crispy Chips', 'calories', 550)),
('5678901234567', 'Chocolate Bar 100g', 2, 1.79, 1.00, 40, 10, 80, 
 JSON_OBJECT('weight', '100g', 'brand', 'Sweet Chocolate', 'calories', 534)),
('6789012345678', 'Whole Milk 1L', 3, 3.29, 2.20, 30, 10, 60, 
 JSON_OBJECT('weight', '1L', 'brand', 'Fresh Dairy', 'expiry_days', 7)),
('7890123456789', 'Cheddar Cheese 200g', 3, 4.99, 3.50, 25, 8, 50, 
 JSON_OBJECT('weight', '200g', 'brand', 'Quality Cheese', 'expiry_days', 14)),
('8901234567890', 'White Bread Loaf', 4, 2.50, 1.80, 45, 12, 80, 
 JSON_OBJECT('brand', 'Fresh Bakery', 'slices', 20, 'expiry_days', 3)),
('9012345678901', 'Croissants 4-pack', 4, 3.99, 2.50, 20, 5, 40, 
 JSON_OBJECT('brand', 'French Bakery', 'count', 4, 'expiry_days', 2)),
('0123456789012', 'Dish Soap 500ml', 5, 3.49, 2.00, 35, 8, 70, 
 JSON_OBJECT('weight', '500ml', 'brand', 'Clean Pro', 'type', 'liquid'));

-- Insert Customers
INSERT INTO customers (customer_name, phone, email, date_of_birth, loyalty_points, total_spent, preferences) VALUES
('Jane Smith', '+1-555-1001', 'jane.smith@email.com', '1985-03-15', 150, 245.67, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Beverages', 'Snacks'), 'email_receipts', true)),
('Mike Johnson', '+1-555-1002', 'mike.johnson@email.com', '1978-11-22', 75, 123.45, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Dairy', 'Bakery'), 'email_receipts', false)),
('Sarah Davis', '+1-555-1003', 'sarah.davis@email.com', '1992-07-08', 220, 456.78, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Health & Beauty', 'Household'), 'email_receipts', true)),
('Robert Wilson', '+1-555-1004', 'robert.wilson@email.com', '1980-12-03', 95, 189.32, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Electronics', 'Snacks'), 'email_receipts', true)),
('Emily Brown', '+1-555-1005', 'emily.brown@email.com', '1988-05-20', 310, 578.90, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Frozen Foods', 'Beverages'), 'email_receipts', true)),
('David Miller', '+1-555-1006', 'david.miller@email.com', '1975-09-14', 45, 87.65, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Dairy', 'Bakery'), 'email_receipts', false)),
('Lisa Anderson', '+1-555-1007', 'lisa.anderson@email.com', '1990-01-25', 180, 324.56, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Health & Beauty'), 'email_receipts', true)),
('Tom Garcia', '+1-555-1008', 'tom.garcia@email.com', '1983-06-12', 65, 98.43, 
 JSON_OBJECT('preferred_categories', JSON_ARRAY('Household', 'Electronics'), 'email_receipts', true));

-- Insert Discounts
INSERT INTO discounts (discount_name, discount_type, discount_value, min_purchase_amount, max_discount_amount, start_date, end_date, applicable_categories, conditions) VALUES
('Summer Sale 10%', 'percentage', 10.00, 20.00, 50.00, '2025-06-01', '2025-08-31', 
 JSON_ARRAY('Beverages', 'Snacks'), 
 JSON_OBJECT('weekends_only', false, 'first_time_customer', false)),
('Dairy Discount', 'fixed', 1.00, 10.00, NULL, '2025-06-15', '2025-07-15', 
 JSON_ARRAY('Dairy'), 
 JSON_OBJECT('loyalty_members_only', false)),
('Buy More Save More', 'percentage', 15.00, 50.00, 75.00, '2025-06-01', '2025-12-31', 
 JSON_ARRAY(), 
 JSON_OBJECT('bulk_purchase', true, 'min_items', 5)),
('Weekend Special', 'percentage', 5.00, 0.00, 25.00, '2025-06-21', '2025-06-22', 
 JSON_ARRAY('Bakery'), 
 JSON_OBJECT('weekend_only', true)),
('Electronics Deal', 'fixed', 5.00, 25.00, NULL, '2025-06-01', '2025-07-31', 
 JSON_ARRAY('Electronics'), 
 JSON_OBJECT('new_customer_only', false)),
('Health & Beauty Combo', 'percentage', 20.00, 30.00, 40.00, '2025-06-10', '2025-07-10', 
 JSON_ARRAY('Health & Beauty'), 
 JSON_OBJECT('combo_items', 2)),
('Student Discount', 'percentage', 10.00, 0.00, 20.00, '2025-06-01', '2025-12-31', 
 JSON_ARRAY(), 
 JSON_OBJECT('student_id_required', true)),
('Senior Citizen Special', 'percentage', 8.00, 0.00, 30.00, '2025-06-01', '2025-12-31', 
 JSON_ARRAY(), 
 JSON_OBJECT('age_verification', true, 'min_age', 65));

-- Insert some sample transactions for testing
INSERT INTO sales_transactions (transaction_number, store_id, cashier_id, customer_id, subtotal, tax_rate, tax_amount, total_amount, payment_method, loyalty_points_earned) VALUES
('TXN-20250620-000001', 1, 3, 1, 8.47, 8.25, 0.70, 9.17, 'credit_card', 9),
('TXN-20250620-000002', 1, 4, 2, 15.28, 8.25, 1.26, 16.54, 'cash', 17),
('TXN-20250620-000003', 2, 6, NULL, 5.98, 8.25, 0.49, 6.47, 'debit_card', 0),
('TXN-20250620-000004', 1, 3, 3, 23.45, 8.25, 1.93, 25.38, 'mobile_payment', 25),
('TXN-20250620-000005', 2, 6, 4, 12.76, 8.25, 1.05, 13.81, 'credit_card', 14);

-- Insert sample sale items
INSERT INTO sale_items (transaction_id, product_id, quantity, unit_price, line_total) VALUES
-- Transaction 1
(1, 1, 2, 1.99, 3.98),
(1, 4, 1, 2.49, 2.49),
(1, 5, 1, 1.79, 1.79),
-- Transaction 2
(2, 6, 1, 3.29, 3.29),
(2, 7, 1, 4.99, 4.99),
(2, 8, 1, 2.50, 2.50),
(2, 9, 1, 3.99, 3.99),
-- Transaction 3
(3, 2, 3, 1.89, 5.67),
-- Transaction 4
(4, 1, 1, 1.99, 1.99),
(4, 4, 2, 2.49, 4.98),
(4, 6, 2, 3.29, 6.58),
(4, 10, 3, 3.49, 10.47),
-- Transaction 5
(5, 5, 2, 1.79, 3.58),
(5, 8, 1, 2.50, 2.50),
(5, 9, 1, 3.99, 3.99);

COMMIT;

-- Display summary of inserted data
SELECT 'Sample data insertion completed successfully!' as Status;
SELECT 
    'Categories' as TableName, COUNT(*) as RecordCount FROM categories
UNION ALL
SELECT 'Stores', COUNT(*) FROM stores
UNION ALL
SELECT 'Users', COUNT(*) FROM users
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Discounts', COUNT(*) FROM discounts
UNION ALL
SELECT 'Sales Transactions', COUNT(*) FROM sales_transactions
UNION ALL
SELECT 'Sale Items', COUNT(*) FROM sale_items;

