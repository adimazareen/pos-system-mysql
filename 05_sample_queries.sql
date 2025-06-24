-- =====================================================
-- POS SYSTEM - SAMPLE QUERIES AND TESTING
-- =====================================================
-- File: 05_sample_queries.sql
-- Description: Demonstrates all POS system features with sample queries
-- =====================================================

USE pos_system;

-- =====================================================
-- CORE FEATURE DEMONSTRATIONS
-- =====================================================

-- 1. BARCODE LOOKUP DEMONSTRATION
SELECT '=== 1. BARCODE LOOKUP DEMONSTRATION ===' as Section;
CALL SearchProductByBarcode('1234567890123');

-- 2. PRODUCT CATALOG MANAGEMENT
SELECT '=== 2. PRODUCT CATALOG MANAGEMENT ===' as Section;
SELECT 
    p.product_id,
    p.barcode,
    p.product_name,
    c.category_name,
    p.price,
    p.stock_quantity,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'Out of Stock'
        WHEN p.stock_quantity <= p.min_stock_level THEN 'Low Stock'
        ELSE 'In Stock'
    END as stock_status
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.is_active = TRUE
ORDER BY c.category_name, p.product_name
LIMIT 10;

-- 3. PROCESS A SAMPLE SALE
SELECT '=== 3. PROCESS A SAMPLE SALE ===' as Section;
SET @transaction_id = 0;
SET @total_amount = 0;
SET @items_json = JSON_ARRAY(
    JSON_OBJECT('product_id', 1, 'quantity', 2, 'unit_price', 1.99),
    JSON_OBJECT('product_id', 4, 'quantity', 1, 'unit_price', 2.49),
    JSON_OBJECT('product_id', 6, 'quantity', 1, 'unit_price', 3.29)
);

CALL ProcessSale(1, 3, 1, 'credit_card', 'CC-12345', @items_json, @transaction_id, @total_amount);
SELECT CONCAT('Sale processed! Transaction ID: ', @transaction_id, ', Total: $', @total_amount) as Result;

-- 4. GENERATE RECEIPT FOR THE SALE
SELECT '=== 4. GENERATE RECEIPT ===' as Section;
SELECT * FROM sales_transactions WHERE transaction_id = @transaction_id;

SELECT JSON_OBJECT(
    'receipt_number', CONCAT('RCP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(1, 6, '0')),
    'store_info', JSON_OBJECT(
        'store_name', s.store_name,
        'address', s.address,
        'phone', s.phone,
        'email', s.email
    ),
    'transaction_info', JSON_OBJECT(
        'transaction_id', st.transaction_id,
        'transaction_number', st.transaction_number,
        'date', DATE_FORMAT(st.transaction_date, '%Y-%m-%d'),
        'time', TIME_FORMAT(st.transaction_date, '%H:%i:%s'),
        'cashier', u.full_name,
        'customer_id', st.customer_id,
        'customer_name', COALESCE(c.customer_name, 'Walk-in Customer')
    ),
    'items', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'product_id', si.product_id,
                'product_name', p.product_name,
                'barcode', p.barcode,
                'quantity', si.quantity,
                'unit_price', si.unit_price,
                'discount', si.discount_amount,
                'line_total', si.line_total
            )
        )
        FROM sale_items si
        JOIN products p ON si.product_id = p.product_id
        WHERE si.transaction_id = st.transaction_id
    ),
    'payment_details', JSON_OBJECT(
        'subtotal', st.subtotal,
        'discount_total', st.discount_amount,
        'tax_rate', st.tax_rate,
        'tax_amount', st.tax_amount,
        'total_amount', st.total_amount,
        'payment_method', st.payment_method,
        'payment_reference', st.payment_reference
    ),
    'loyalty_info', CASE 
        WHEN st.customer_id IS NOT NULL THEN
            JSON_OBJECT(
                'points_earned', st.loyalty_points_earned,
                'points_used', st.loyalty_points_used,
                'total_points', c.loyalty_points
            )
        ELSE NULL
    END,
    'footer_info', JSON_OBJECT(
        'thank_you_message', 'Thank you for shopping with us!',
        'return_policy', 'Returns accepted within 30 days with receipt'
    )
) AS receipt_preview
FROM sales_transactions st
JOIN stores s ON st.store_id = s.store_id
JOIN users u ON st.cashier_id = u.user_id
LEFT JOIN customers c ON st.customer_id = c.customer_id
WHERE st.transaction_id = 1;

SELECT 
    st.transaction_id,
    st.transaction_number,
    st.store_id,
    s.store_name,
    st.cashier_id,
    u.full_name,
    st.customer_id,
    c.customer_name
FROM sales_transactions st
LEFT JOIN stores s ON st.store_id = s.store_id
LEFT JOIN users u ON st.cashier_id = u.user_id
LEFT JOIN customers c ON st.customer_id = c.customer_id
WHERE st.transaction_id = @transaction_id;

CALL GenerateReceipt(1);

SET @transaction_id = 1;
CALL GenerateReceipt(@transaction_id);


SELECT * 
FROM sales_transactions
ORDER BY transaction_id DESC
LIMIT 10;


SELECT * FROM sales_transactions WHERE transaction_id = @transaction_id;

-- 5. INVENTORY TRACKING DEMONSTRATION
SELECT '=== 5. INVENTORY TRACKING ===' as Section;
SELECT 
    p.product_name,
    il.change_type,
    il.quantity_change,
    il.old_quantity,
    il.new_quantity,
    il.timestamp,
    u.full_name as user_name
FROM inventory_logs il
JOIN products p ON il.product_id = p.product_id
JOIN users u ON il.user_id = u.user_id
ORDER BY il.timestamp DESC
LIMIT 10;

-- 6. CUSTOMER LOOKUP BY PHONE
SELECT '=== 6. CUSTOMER LOOKUP ===' as Section;
CALL GetCustomerByPhone('+1-555-1001');

-- 7. APPLY DISCOUNT DEMONSTRATION
SELECT '=== 7. APPLY DISCOUNT ===' as Section;

SELECT transaction_id, subtotal, tax_amount, discount_amount
FROM sales_transactions
WHERE transaction_id = @transaction_id;

SET @discount_amount = 0;
CALL ApplyDiscount(@transaction_id, 1, @discount_amount);
SELECT @discount_amount;

-- Declare and run
SET @transaction_id = 1;
SET @discount_amount = 0;
CALL ApplyDiscount(@transaction_id, 1, @discount_amount);
SELECT @discount_amount;


SELECT CONCAT('Discount applied: $', @discount_amount) as Result;

-- 8. RESTOCK INVENTORY
SELECT '=== 8. RESTOCK INVENTORY ===' as Section;
CALL RestockInventory(1, 1, 50, 2, 'Weekly restock delivery');

-- 9. PROCESS A RETURN
SELECT '=== 9. PROCESS A RETURN ===' as Section;
SET @return_id = 0;
SET @return_amount = 0;
SET @return_items = JSON_ARRAY(
    JSON_OBJECT('product_id', 1, 'quantity', 1)
);

SELECT @transaction_id;

SELECT * FROM sale_items WHERE transaction_id = @transaction_id;
SELECT * FROM products WHERE product_id = 1; -- or product in @return_items
SELECT @return_amount;

SELECT 
    si.product_id, 
    si.quantity AS original_qty, 
    si.unit_price, 
    si.line_total
FROM sale_items si
WHERE transaction_id = @transaction_id;

SELECT @return_items;

SET @return_items = JSON_ARRAY(
    JSON_OBJECT('product_id', 2, 'quantity', 1)
);

SELECT * FROM sale_items
WHERE transaction_id = @transaction_id;

SELECT DISTINCT transaction_id FROM sale_items;
SELECT * FROM sale_items WHERE transaction_id = 6;

SET @transaction_id = 6;
SET @return_items = JSON_ARRAY(
    JSON_OBJECT('product_id', 4, 'quantity', 1)
);


CALL ProcessReturn(@transaction_id, 3, @return_items, 'Customer changed mind', @return_id, @return_amount);
SELECT CONCAT('Return processed! Return ID: ', @return_id, ', Amount: $', @return_amount) as Result;

-- =====================================================
-- REPORTING DEMONSTRATIONS
-- =====================================================

-- 10. DAILY SALES REPORT
SELECT '=== 10. DAILY SALES REPORT ===' as Section;
CALL GenerateDailySalesReport(1, CURDATE());

-- 11. PRODUCT SALES PERFORMANCE
SELECT '=== 11. PRODUCT SALES PERFORMANCE ===' as Section;
SELECT * FROM product_sales_performance ORDER BY total_sales DESC LIMIT 5;


-- 12. LOW STOCK ALERTS
SELECT '=== 12. LOW STOCK ALERTS ===' as Section;
SELECT * FROM low_stock_alerts
LIMIT 5;

-- 13. CUSTOMER PURCHASE SUMMARY
SELECT '=== 13. CUSTOMER PURCHASE SUMMARY ===' as Section;
SELECT * FROM customer_purchase_summary
ORDER BY total_spent DESC
LIMIT 5;

-- 14. TOP SELLING PRODUCTS
SELECT '=== 14. TOP SELLING PRODUCTS ===' as Section;
CALL GetTopSellingProducts(1, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE(), 5);

-- 15. CASHIER PERFORMANCE
SELECT '=== 15. CASHIER PERFORMANCE ===' as Section;
CREATE OR REPLACE VIEW cashier_performance AS
SELECT 
    u.user_id AS cashier_id,
    u.full_name AS cashier_name,
    DATE(st.transaction_date) AS work_date,
    COUNT(st.transaction_id) AS total_transactions,
    SUM(st.total_amount) AS total_sales_amount
FROM sales_transactions st
JOIN users u ON st.cashier_id = u.user_id
GROUP BY u.user_id, u.full_name, DATE(st.transaction_date);


-- =====================================================
-- ADVANCED QUERIES AND ANALYTICS
-- =====================================================

-- 16. SALES BY CATEGORY
SELECT '=== 16. SALES BY CATEGORY ===' as Section;
SELECT 
    c.category_name,
    COUNT(si.sale_item_id) as items_sold,
    SUM(si.quantity) as total_quantity,
    SUM(si.line_total) as total_revenue,
    AVG(si.unit_price) as avg_price
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN sale_items si ON p.product_id = si.product_id
JOIN sales_transactions st ON si.transaction_id = st.transaction_id
WHERE st.status = 'completed'
  AND DATE(st.transaction_date) = CURDATE()
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;

-- 17. HOURLY SALES PATTERN
SELECT '=== 17. HOURLY SALES PATTERN ===' as Section;
SELECT 
    HOUR(transaction_date) as hour_of_day,
    COUNT(*) as transactions,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_transaction
FROM sales_transactions
WHERE DATE(transaction_date) = CURDATE()
  AND status = 'completed'
GROUP BY HOUR(transaction_date)
ORDER BY hour_of_day;

-- 18. PAYMENT METHOD ANALYSIS
SELECT '=== 18. PAYMENT METHOD ANALYSIS ===' as Section;
SELECT 
    payment_method,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_amount,
    AVG(total_amount) as avg_transaction_value,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sales_transactions WHERE status = 'completed')), 2) as percentage
FROM sales_transactions
WHERE status = 'completed'
  AND DATE(transaction_date) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY payment_method
ORDER BY transaction_count DESC;

-- 19. LOYALTY PROGRAM EFFECTIVENESS
SELECT '=== 19. LOYALTY PROGRAM EFFECTIVENESS ===' as Section;
SELECT 
    CASE 
        WHEN customer_id IS NOT NULL THEN 'Loyalty Customer'
        ELSE 'Walk-in Customer'
    END as customer_type,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value,
    SUM(loyalty_points_earned) as total_points_given
FROM sales_transactions
WHERE status = 'completed'
  AND DATE(transaction_date) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY CASE WHEN customer_id IS NOT NULL THEN 'Loyalty Customer' ELSE 'Walk-in Customer' END;

-- 20. INVENTORY TURNOVER ANALYSIS
SELECT '=== 20. INVENTORY TURNOVER ANALYSIS ===' as Section;
SELECT 
    p.product_name,
    p.stock_quantity as current_stock,
    COALESCE(SUM(si.quantity), 0) as sold_last_30_days,
    CASE 
        WHEN p.stock_quantity > 0 THEN ROUND(COALESCE(SUM(si.quantity), 0) / p.stock_quantity, 2)
        ELSE 0
    END as turnover_ratio,
    CASE 
        WHEN COALESCE(SUM(si.quantity), 0) = 0 THEN 'No Sales'
        WHEN p.stock_quantity / COALESCE(SUM(si.quantity), 1) * 30 > 90 THEN 'Slow Moving'
        WHEN p.stock_quantity / COALESCE(SUM(si.quantity), 1) * 30 < 30 THEN 'Fast Moving'
        ELSE 'Normal'
    END as movement_category
FROM products p
LEFT JOIN sale_items si ON p.product_id = si.product_id
LEFT JOIN sales_transactions st ON si.transaction_id = st.transaction_id 
    AND st.status = 'completed'
    AND st.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY turnover_ratio DESC
LIMIT 10;

-- Display completion message
SELECT '=== POS SYSTEM TESTING COMPLETED SUCCESSFULLY! ===' as Status;
SELECT 'All core features have been demonstrated and tested.' as Message;
