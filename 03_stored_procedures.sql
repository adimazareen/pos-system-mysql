-- =====================================================
-- POS SYSTEM - STORED PROCEDURES
-- =====================================================
-- File: 03_stored_procedures.sql
-- Description: Contains all stored procedures for POS operations

-- =====================================================

USE pos_system;

DELIMITER //

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Procedure to process a sale transaction
CREATE PROCEDURE ProcessSale(
    IN p_store_id INT,
    IN p_cashier_id INT,
    IN p_customer_id INT,
    IN p_payment_method VARCHAR(20),
    IN p_payment_reference VARCHAR(100),
    IN p_items JSON,
    OUT p_transaction_id INT,
    OUT p_total_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_transaction_number VARCHAR(50);
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tax_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tax_rate DECIMAL(5,2) DEFAULT 8.25;
    DECLARE v_loyalty_points INT DEFAULT 0;
    DECLARE v_item_count INT DEFAULT 0;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_line_total DECIMAL(12,2);
    DECLARE v_current_stock INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Generate transaction number
    SET v_transaction_number = CONCAT('TXN-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', 
                                     LPAD((SELECT COALESCE(MAX(SUBSTRING(transaction_number, -6)), 0) + 1 
                                           FROM sales_transactions 
                                           WHERE DATE(transaction_date) = CURDATE()), 6, '0'));
    
    -- Get item count
    SET v_item_count = JSON_LENGTH(p_items);
    
    -- Calculate subtotal and validate stock
    WHILE v_i < v_item_count DO
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id')));
        SET v_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity')));
        SET v_unit_price = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].unit_price')));
        
        -- Check stock availability
        SELECT stock_quantity INTO v_current_stock 
        FROM products 
        WHERE product_id = v_product_id;
        
        IF v_current_stock < v_quantity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for product';
        END IF;
        
        SET v_line_total = v_quantity * v_unit_price;
        SET v_subtotal = v_subtotal + v_line_total;
        SET v_i = v_i + 1;
    END WHILE;
    
    -- Calculate tax
    SET v_tax_amount = v_subtotal * (v_tax_rate / 100);
    SET p_total_amount = v_subtotal + v_tax_amount;
    
    -- Calculate loyalty points (1 point per dollar spent)
    SET v_loyalty_points = FLOOR(p_total_amount);
    
    -- Insert transaction
    INSERT INTO sales_transactions (
        transaction_number, store_id, cashier_id, customer_id, 
        subtotal, tax_rate, tax_amount, total_amount, 
        payment_method, payment_reference, loyalty_points_earned
    ) VALUES (
        v_transaction_number, p_store_id, p_cashier_id, p_customer_id,
        v_subtotal, v_tax_rate, v_tax_amount, p_total_amount,
        p_payment_method, p_payment_reference, v_loyalty_points
    );
    
    SET p_transaction_id = LAST_INSERT_ID();
    
    -- Insert sale items and update inventory
    SET v_i = 0;
    WHILE v_i < v_item_count DO
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id')));
        SET v_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity')));
        SET v_unit_price = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].unit_price')));
        SET v_line_total = v_quantity * v_unit_price;
        
        -- Insert sale item
        INSERT INTO sale_items (transaction_id, product_id, quantity, unit_price, line_total)
        VALUES (p_transaction_id, v_product_id, v_quantity, v_unit_price, v_line_total);
        
        -- Update product stock
        UPDATE products 
        SET stock_quantity = stock_quantity - v_quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = v_product_id;
        
        SET v_i = v_i + 1;
    END WHILE;
    
    -- Update customer loyalty points
    IF p_customer_id IS NOT NULL THEN
        UPDATE customers 
        SET loyalty_points = loyalty_points + v_loyalty_points,
            total_spent = total_spent + p_total_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = p_customer_id;
    END IF;
    
    COMMIT;
END //

-- Procedure to process returns
DROP PROCEDURE IF EXISTS ProcessReturn //
CREATE PROCEDURE ProcessReturn(
    IN p_original_transaction_id INT,
    IN p_cashier_id INT,
    IN p_return_items JSON,
    IN p_reason VARCHAR(255),
    OUT p_return_id INT,
    OUT p_return_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_return_number VARCHAR(50);
    DECLARE v_customer_id INT;
    DECLARE v_item_count INT DEFAULT 0;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_line_total DECIMAL(12,2);
    DECLARE v_original_quantity INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get customer ID
    SELECT customer_id INTO v_customer_id
    FROM sales_transactions
    WHERE transaction_id = p_original_transaction_id;

    -- Generate return number
    SET v_return_number = CONCAT('RTN-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', 
        LPAD(
            COALESCE((
                SELECT MAX(CAST(SUBSTRING(return_number, -6) AS UNSIGNED))
                FROM returns
                WHERE DATE(return_date) = CURDATE()
            ), 0) + 1, 6, '0')
    );

    -- Initialize
    SET v_item_count = JSON_LENGTH(p_return_items);
    SET p_return_amount = 0;

    -- Exit early if no items
    IF v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No items provided for return.';
    END IF;

    -- Loop through return items
    WHILE v_i < v_item_count DO
        SET v_product_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_return_items, CONCAT('$[', v_i, '].product_id'))) AS UNSIGNED);
        SET v_quantity = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_return_items, CONCAT('$[', v_i, '].quantity'))) AS UNSIGNED);

        -- Validate quantity and price exist
        SELECT quantity, unit_price INTO v_original_quantity, v_unit_price
        FROM sale_items
        WHERE transaction_id = p_original_transaction_id AND product_id = v_product_id;

        IF v_quantity > v_original_quantity THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Return quantity exceeds original purchase quantity';
        END IF;

        -- Calculate line total and accumulate
        SET v_line_total = v_quantity * v_unit_price;
        SET p_return_amount = p_return_amount + v_line_total;

        SET v_i = v_i + 1;
    END WHILE;

    -- Ensure return amount is valid
    IF p_return_amount IS NULL OR p_return_amount = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Return amount is invalid or zero';
    END IF;

    -- Insert return record
    INSERT INTO returns (
        return_number, original_transaction_id, cashier_id, customer_id,
        total_return_amount, reason
    ) VALUES (
        v_return_number, p_original_transaction_id, p_cashier_id, v_customer_id,
        p_return_amount, p_reason
    );

    SET p_return_id = LAST_INSERT_ID();

    -- Insert return items and restock
    SET v_i = 0;
    WHILE v_i < v_item_count DO
        SET v_product_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_return_items, CONCAT('$[', v_i, '].product_id'))) AS UNSIGNED);
        SET v_quantity = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_return_items, CONCAT('$[', v_i, '].quantity'))) AS UNSIGNED);

        SELECT unit_price INTO v_unit_price
        FROM sale_items
        WHERE transaction_id = p_original_transaction_id AND product_id = v_product_id;

        SET v_line_total = v_quantity * v_unit_price;

        INSERT INTO return_items (return_id, product_id, quantity, unit_price, line_total)
        VALUES (p_return_id, v_product_id, v_quantity, v_unit_price, v_line_total);

        -- Restock
        UPDATE products
        SET stock_quantity = stock_quantity + v_quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = v_product_id;

        SET v_i = v_i + 1;
    END WHILE;

    -- Update loyalty if needed
    IF v_customer_id IS NOT NULL THEN
        UPDATE customers 
        SET loyalty_points = GREATEST(0, loyalty_points - FLOOR(p_return_amount)),
            total_spent = GREATEST(0, total_spent - p_return_amount),
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = v_customer_id;
    END IF;

    -- Update transaction status
    UPDATE sales_transactions
    SET status = 'partial_refund'
    WHERE transaction_id = p_original_transaction_id;

    COMMIT;
END //

-- Procedure to generate receipt


DROP PROCEDURE IF EXISTS GenerateReceipt //
CREATE PROCEDURE GenerateReceipt(
    IN p_transaction_id INT
)
BEGIN
    DECLARE v_receipt_number VARCHAR(50);
    DECLARE v_receipt_data JSON;
    DECLARE v_items_json JSON;
    DECLARE v_receipt_exists INT DEFAULT 0;

    my_block: BEGIN

        -- Check if receipt already exists
        SELECT COUNT(*) INTO v_receipt_exists
        FROM receipts
        WHERE transaction_id = p_transaction_id;

        IF v_receipt_exists > 0 THEN
            SELECT receipt_data FROM receipts WHERE transaction_id = p_transaction_id;
            LEAVE my_block;
        END IF;

        -- Generate receipt number
        SET v_receipt_number = CONCAT('RCP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', 
                                      LPAD(p_transaction_id, 6, '0'));

        -- Build items array separately
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
        ) INTO v_items_json
        FROM sale_items si
        JOIN products p ON si.product_id = p.product_id
        WHERE si.transaction_id = p_transaction_id;

        -- Build full receipt JSON
        SELECT JSON_OBJECT(
            'receipt_number', v_receipt_number,
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
            'items', v_items_json,
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
        ) INTO v_receipt_data
        FROM sales_transactions st
        JOIN stores s ON st.store_id = s.store_id
        JOIN users u ON st.cashier_id = u.user_id
        LEFT JOIN customers c ON st.customer_id = c.customer_id
        WHERE st.transaction_id = p_transaction_id;

        -- Safety check: avoid NULL receipt data
        IF v_receipt_data IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Receipt JSON data could not be generated. Possibly missing store, user, or transaction info';
        END IF;

        -- Insert receipt
        INSERT INTO receipts (
            transaction_id,
            receipt_number,
            receipt_data
        ) VALUES (
            p_transaction_id,
            v_receipt_number,
            v_receipt_data
        );

        -- Return receipt
        SELECT v_receipt_data AS receipt_data;

    END my_block;

END //



-- Procedure to restock inventory
CREATE PROCEDURE RestockInventory(
    IN p_product_id INT,
    IN p_store_id INT,
    IN p_quantity INT,
    IN p_user_id INT,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_old_quantity INT;
    DECLARE v_new_quantity INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current stock
    SELECT stock_quantity INTO v_old_quantity
    FROM products
    WHERE product_id = p_product_id;
    
    -- Update stock
    SET v_new_quantity = v_old_quantity + p_quantity;
    
    UPDATE products 
    SET stock_quantity = v_new_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Log inventory change
    INSERT INTO inventory_logs (
        product_id, store_id, change_type, quantity_change,
        old_quantity, new_quantity, user_id, notes
    ) VALUES (
        p_product_id, p_store_id, 'restock', p_quantity,
        v_old_quantity, v_new_quantity, p_user_id, p_notes
    );
    
    COMMIT;
    
    SELECT CONCAT('Successfully restocked ', p_quantity, ' units. New stock level: ', v_new_quantity) as message;
END //

-- Procedure to apply discount

DROP PROCEDURE IF EXISTS ApplyDiscount //
CREATE PROCEDURE ApplyDiscount(
    IN p_transaction_id INT,
    IN p_discount_id INT,
    OUT p_discount_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_discount_type VARCHAR(20);
    DECLARE v_discount_value DECIMAL(10,2);
    DECLARE v_min_purchase DECIMAL(10,2);
    DECLARE v_max_discount DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_current_discount DECIMAL(12,2);
    DECLARE v_tax_amount DECIMAL(12,2);
    DECLARE v_discount_calc DECIMAL(12,2);
    DECLARE v_total_amount DECIMAL(12,2);

    -- Step 1: Get discount details
    SELECT discount_type, discount_value, min_purchase_amount, max_discount_amount
    INTO v_discount_type, v_discount_value, v_min_purchase, v_max_discount
    FROM discounts
    WHERE discount_id = p_discount_id 
      AND is_active = TRUE
      AND CURDATE() BETWEEN start_date AND end_date;

    -- Step 2: Get transaction subtotal, tax, and current discount
    SELECT 
        COALESCE(subtotal, 0), 
        COALESCE(tax_amount, 0), 
        COALESCE(discount_amount, 0)
    INTO 
        v_subtotal, 
        v_tax_amount, 
        v_current_discount
    FROM sales_transactions
    WHERE transaction_id = p_transaction_id;

    -- Step 3: Validate subtotal against minimum requirement
    IF v_subtotal < v_min_purchase THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Purchase amount does not meet minimum requirement for discount';
    END IF;

    -- Step 4: Calculate discount amount
    IF v_discount_type = 'percentage' THEN
        SET v_discount_calc = v_subtotal * (v_discount_value / 100);
    ELSE
        SET v_discount_calc = v_discount_value;
    END IF;

    -- Step 5: Apply maximum discount cap
    IF v_max_discount IS NOT NULL AND v_discount_calc > v_max_discount THEN
        SET v_discount_calc = v_max_discount;
    END IF;

    -- Step 6: Assign OUT param
    SET p_discount_amount = v_discount_calc;

    -- Step 7: Final total calculation (SAFE with COALESCE)
    SET v_total_amount = 
        COALESCE(v_subtotal, 0) + 
        COALESCE(v_tax_amount, 0) - 
        (COALESCE(v_current_discount, 0) + COALESCE(v_discount_calc, 0));

    -- Step 8: Final safety check
    IF v_total_amount IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Total amount calculation failed. One of the values is missing.';
    END IF;

    -- Step 9: Apply discount to transaction
    UPDATE sales_transactions
    SET 
        discount_amount = v_current_discount + v_discount_calc,
        total_amount = v_total_amount
    WHERE transaction_id = p_transaction_id;

    -- Step 10: Track discount usage
    UPDATE discounts
    SET usage_count = usage_count + 1
    WHERE discount_id = p_discount_id;

END //



-- Procedure to search products by barcode
CREATE PROCEDURE SearchProductByBarcode(
    IN p_barcode VARCHAR(50)
)
BEGIN
    SELECT 
        p.product_id,
        p.barcode,
        p.product_name,
        c.category_name,
        p.price,
        p.stock_quantity,
        p.unit_of_measure,
        p.attributes,
        CASE 
            WHEN p.stock_quantity = 0 THEN 'Out of Stock'
            WHEN p.stock_quantity <= p.min_stock_level THEN 'Low Stock'
            ELSE 'In Stock'
        END as stock_status
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    WHERE p.barcode = p_barcode AND p.is_active = TRUE;
END //

-- Procedure to get customer by phone
CREATE PROCEDURE GetCustomerByPhone(
    IN p_phone VARCHAR(20)
)
BEGIN
    SELECT 
        customer_id,
        customer_name,
        phone,
        email,
        loyalty_points,
        total_spent,
        preferences
    FROM customers
    WHERE phone = p_phone AND is_active = TRUE;
END //

-- Procedure to generate daily sales report
CREATE PROCEDURE GenerateDailySalesReport(
    IN p_store_id INT,
    IN p_date DATE
)
BEGIN
    SELECT 
        DATE(st.transaction_date) as sale_date,
        s.store_name,
        COUNT(st.transaction_id) as total_transactions,
        SUM(st.subtotal) as total_subtotal,
        SUM(st.discount_amount) as total_discounts,
        SUM(st.tax_amount) as total_tax,
        SUM(st.total_amount) as total_sales,
        AVG(st.total_amount) as average_transaction_value,
        COUNT(DISTINCT st.customer_id) as unique_customers,
        SUM(st.loyalty_points_earned) as total_loyalty_points_given
    FROM sales_transactions st
    JOIN stores s ON st.store_id = s.store_id
    WHERE st.status = 'completed'
      AND st.store_id = p_store_id
      AND DATE(st.transaction_date) = p_date
    GROUP BY DATE(st.transaction_date), s.store_id, s.store_name;
END //

-- Procedure to adjust inventory
CREATE PROCEDURE AdjustInventory(
    IN p_product_id INT,
    IN p_store_id INT,
    IN p_new_quantity INT,
    IN p_user_id INT,
    IN p_reason TEXT
)
BEGIN
    DECLARE v_old_quantity INT;
    DECLARE v_quantity_change INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current stock
    SELECT stock_quantity INTO v_old_quantity
    FROM products
    WHERE product_id = p_product_id;
    
    -- Calculate change
    SET v_quantity_change = p_new_quantity - v_old_quantity;
    
    -- Update stock
    UPDATE products 
    SET stock_quantity = p_new_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Log inventory change
    INSERT INTO inventory_logs (
        product_id, store_id, change_type, quantity_change,
        old_quantity, new_quantity, user_id, notes
    ) VALUES (
        p_product_id, p_store_id, 'adjustment', v_quantity_change,
        v_old_quantity, p_new_quantity, p_user_id, p_reason
    );
    
    COMMIT;
    
    SELECT CONCAT('Inventory adjusted. Old: ', v_old_quantity, ', New: ', p_new_quantity, ', Change: ', v_quantity_change) as message;
END //

-- Procedure to get top selling products
CREATE PROCEDURE GetTopSellingProducts(
    IN p_store_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_limit INT
)
BEGIN
    SELECT 
        p.product_id,
        p.barcode,
        p.product_name,
        c.category_name,
        SUM(si.quantity) as total_quantity_sold,
        SUM(si.line_total) as total_revenue,
        COUNT(DISTINCT si.transaction_id) as number_of_sales,
        AVG(si.unit_price) as average_selling_price
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    JOIN sale_items si ON p.product_id = si.product_id
    JOIN sales_transactions st ON si.transaction_id = st.transaction_id
    WHERE st.status = 'completed'
      AND st.store_id = p_store_id
      AND DATE(st.transaction_date) BETWEEN p_start_date AND p_end_date
    GROUP BY p.product_id, p.barcode, p.product_name, c.category_name
    ORDER BY total_quantity_sold DESC
    LIMIT p_limit;
END //

DELIMITER ;

-- Display success message
SELECT 'Stored procedures created successfully!' as Status;
