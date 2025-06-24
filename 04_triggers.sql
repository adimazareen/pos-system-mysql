-- =====================================================
-- POS SYSTEM - TRIGGERS
-- =====================================================
-- File: 04_triggers.sql
-- Description: Contains all triggers for automated operations
-- =====================================================

USE pos_system;

DELIMITER //

-- =====================================================
-- TRIGGERS FOR AUTOMATED OPERATIONS
-- =====================================================

-- Trigger for inventory logging on sales
CREATE TRIGGER tr_sale_inventory_log
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    DECLARE v_store_id INT;
    DECLARE v_cashier_id INT;
    DECLARE v_old_stock INT;
    DECLARE v_new_stock INT;
    
    -- Get store and cashier info
    SELECT store_id, cashier_id INTO v_store_id, v_cashier_id
    FROM sales_transactions
    WHERE transaction_id = NEW.transaction_id;
    
    -- Get stock levels
    SELECT stock_quantity INTO v_new_stock
    FROM products
    WHERE product_id = NEW.product_id;
    
    SET v_old_stock = v_new_stock + NEW.quantity;
    
    -- Log inventory change
    INSERT INTO inventory_logs (
        product_id, store_id, change_type, quantity_change,
        old_quantity, new_quantity, reference_id, reference_type, user_id
    ) VALUES (
        NEW.product_id, v_store_id, 'sale', -NEW.quantity,
        v_old_stock, v_new_stock, NEW.transaction_id, 'sale', v_cashier_id
    );
END //

-- Trigger for low stock alerts
CREATE TRIGGER tr_low_stock_alert
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity <= NEW.min_stock_level AND OLD.stock_quantity > OLD.min_stock_level THEN
        INSERT INTO audit_logs (table_name, operation, record_id, new_values)
        VALUES ('products', 'UPDATE', NEW.product_id, 
               JSON_OBJECT('alert_type', 'low_stock', 
                          'product_name', NEW.product_name,
                          'current_stock', NEW.stock_quantity,
                          'min_level', NEW.min_stock_level,
                          'alert_time', NOW()));
    END IF;
END //

-- Trigger for audit logging on products
CREATE TRIGGER tr_audit_products_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, old_values, new_values)
    VALUES ('products', 'UPDATE', NEW.product_id,
           JSON_OBJECT('product_name', OLD.product_name, 'price', OLD.price, 
                      'stock_quantity', OLD.stock_quantity, 'updated_at', OLD.updated_at),
           JSON_OBJECT('product_name', NEW.product_name, 'price', NEW.price, 
                      'stock_quantity', NEW.stock_quantity, 'updated_at', NEW.updated_at));
END //

-- Trigger for audit logging on sales transactions
CREATE TRIGGER tr_audit_sales_insert
AFTER INSERT ON sales_transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, new_values, user_id)
    VALUES ('sales_transactions', 'INSERT', NEW.transaction_id,
           JSON_OBJECT('transaction_number', NEW.transaction_number, 
                      'total_amount', NEW.total_amount, 
                      'payment_method', NEW.payment_method,
                      'customer_id', NEW.customer_id), NEW.cashier_id);
END //

-- Trigger for audit logging on returns
CREATE TRIGGER tr_audit_returns_insert
AFTER INSERT ON returns
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, new_values, user_id)
    VALUES ('returns', 'INSERT', NEW.return_id,
           JSON_OBJECT('return_number', NEW.return_number, 
                      'total_return_amount', NEW.total_return_amount, 
                      'original_transaction_id', NEW.original_transaction_id,
                      'reason', NEW.reason), NEW.cashier_id);
END //

-- Trigger to auto-generate receipt number sequence
CREATE TRIGGER tr_auto_receipt_number
BEFORE INSERT ON receipts
FOR EACH ROW
BEGIN
    IF NEW.receipt_number IS NULL OR NEW.receipt_number = '' THEN
        SET NEW.receipt_number = CONCAT('RCP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', 
                                       LPAD(NEW.transaction_id, 6, '0'));
    END IF;
END //

-- Trigger to validate stock levels before sale
CREATE TRIGGER tr_validate_stock_before_sale
BEFORE INSERT ON sale_items
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_product_name VARCHAR(200);
    DECLARE v_error_message TEXT;
    
    SELECT stock_quantity, product_name 
    INTO v_current_stock, v_product_name
    FROM products
    WHERE product_id = NEW.product_id;
    
    IF v_current_stock < NEW.quantity THEN
        SET v_error_message = CONCAT('Insufficient stock for product: ', v_product_name, 
                                     '. Available: ', v_current_stock, ', Requested: ', NEW.quantity);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
END //



-- Trigger to update customer total spent on completed transactions
CREATE TRIGGER tr_update_customer_total_spent
AFTER INSERT ON sales_transactions
FOR EACH ROW
BEGIN
    IF NEW.customer_id IS NOT NULL AND NEW.status = 'completed' THEN
        UPDATE customers 
        SET total_spent = total_spent + NEW.total_amount,
            loyalty_points = loyalty_points + NEW.loyalty_points_earned,
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
    END IF;
END //

-- Trigger to log return inventory changes
CREATE TRIGGER tr_return_inventory_log
AFTER INSERT ON return_items
FOR EACH ROW
BEGIN
    DECLARE v_store_id INT;
    DECLARE v_cashier_id INT;
    DECLARE v_old_stock INT;
    DECLARE v_new_stock INT;
    
    -- Get store and cashier info from the return
    SELECT 
        st.store_id, 
        r.cashier_id,
        p.stock_quantity 
    INTO v_store_id, v_cashier_id, v_new_stock
    FROM returns r
    JOIN sales_transactions st ON r.original_transaction_id = st.transaction_id
    JOIN products p ON p.product_id = NEW.product_id
    WHERE r.return_id = NEW.return_id;
    
    SET v_old_stock = v_new_stock - NEW.quantity;
    
    -- Log inventory change
    INSERT INTO inventory_logs (
        product_id, store_id, change_type, quantity_change,
        old_quantity, new_quantity, reference_id, reference_type, user_id
    ) VALUES (
        NEW.product_id, v_store_id, 'return', NEW.quantity,
        v_old_stock, v_new_stock, NEW.return_id, 'return', v_cashier_id
    );
END //

-- Trigger to prevent deletion of products with transaction history
CREATE TRIGGER tr_prevent_product_deletion
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    DECLARE v_transaction_count INT;
    
    SELECT COUNT(*) INTO v_transaction_count
    FROM sale_items
    WHERE product_id = OLD.product_id;
    
    IF v_transaction_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete product with transaction history. Set is_active = FALSE instead.';
    END IF;
END //

DELIMITER ;

-- Display success message
SELECT 'Triggers created successfully!' as Status;
