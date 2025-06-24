# POS System in MySQL - Complete Documentation

## Project Overview

This is a comprehensive Point of Sale (POS) system implemented entirely in MySQL 8.0+. The system supports all major POS operations including product management, sales processing, inventory tracking, customer management, discounts, returns, and comprehensive reporting - all through SQL queries, stored procedures, triggers, and views.

## Features Implemented

### Core Features ✅

1. **Product Catalog Management** - Complete product information with categories, pricing, and stock levels
2. **Barcode Lookup** - Efficient product retrieval using barcode scanning
3. **Inventory Tracking** - Real-time stock updates with comprehensive logging
4. **Sales Transactions** - Full transaction processing with itemized sales
5. **Receipt Generation** - JSON-based receipt storage and generation
6. **User Roles** - Role-based access control (admin, manager, cashier)
7. **Discounts and Promotions** - Flexible discount system with conditions
8. **Sales Reporting** - Comprehensive reporting views and procedures

### Bonus Features ✅

1. **Product Returns and Refunds** - Complete return processing system
2. **Loyalty Points System** - Customer loyalty program with points tracking
3. **Multi-store Inventory Management** - Support for multiple store locations
4. **Audit Logs** - Complete audit trail for all database operations
5. **Automated Low-stock Alerts** - Trigger-based inventory alerts

## File Structure

```
POS_system_in_sql/
├── 01_database_schema.sql     # Database creation and table structures
├── 02_sample_data.sql         # Sample data for testing (max 10 entries per table)
├── 03_stored_procedures.sql   # All stored procedures for business logic
├── 04_triggers.sql           # Automated triggers for data integrity
├── 05_sample_queries.sql     # Demonstration queries and testing
├── pos_system_fixes.sql      # Final version with corrections and full testing
└── README.md                 # This documentation file
```

## Installation Instructions

### Prerequisites

* MySQL 8.0 or above
* Sufficient privileges to create databases and execute stored procedures

### Setup Steps

1. **Execute files in order:**

   ```sql
   -- Step 1: Create database and schema
   SOURCE 01_database_schema.sql;

   -- Step 2: Insert sample data
   SOURCE 02_sample_data.sql;

   -- Step 3: Create stored procedures
   SOURCE 03_stored_procedures.sql;

   -- Step 4: Create triggers
   SOURCE 04_triggers.sql;

   -- Step 5: Run final fixes and tests
   SOURCE pos_system_fixes.sql;
   ```

2. **Verify installation:**

   ```sql
   USE pos_system;
   SHOW TABLES;
   SHOW PROCEDURE STATUS WHERE Db = 'pos_system';
   ```

## Database Schema

### Core Tables

* **categories** - Product categories
* **stores** - Store locations and settings
* **users** - System users with role-based access
* **products** - Product catalog with JSON attributes
* **customers** - Customer information and loyalty data
* **discounts** - Promotion and discount rules
* **sales\_transactions** - Sales transaction records
* **sale\_items** - Individual items in transactions
* **receipts** - JSON-based receipt storage
* **returns** - Return transaction records
* **return\_items** - Individual returned items
* **inventory\_logs** - Complete inventory change history
* **audit\_logs** - System audit trail

### Key Views

* **daily\_sales\_report** - Daily sales summaries
* **product\_sales\_performance** - Product performance metrics
* **low\_stock\_alerts** - Products needing restocking
* **customer\_purchase\_summary** - Customer buying patterns
* **cashier\_performance** - Staff performance metrics

## Usage Examples

### 1. Process a Sale

```sql
SET @items = JSON_ARRAY(
    JSON_OBJECT('product_id', 1, 'quantity', 2, 'unit_price', 1.99),
    JSON_OBJECT('product_id', 4, 'quantity', 1, 'unit_price', 2.49)
);
CALL ProcessSale(1, 3, 1, 'credit_card', 'CC-12345', @items, @transaction_id, @total);
```

### 2. Search Product by Barcode

```sql
CALL SearchProductByBarcode('1234567890123');
```

### 3. Process a Return

```sql
SET @return_items = JSON_ARRAY(
    JSON_OBJECT('product_id', 1, 'quantity', 1)
);
CALL ProcessReturn(1, 3, @return_items, 'Defective item', @return_id, @amount);
```

### 4. Generate Reports

```sql
CALL GenerateDailySalesReport(1, CURDATE());
CALL GetTopSellingProducts(1, '2025-06-01', '2025-06-30', 10);
SELECT * FROM low_stock_alerts;
```

### 5. Restock Inventory

```sql
CALL RestockInventory(1, 1, 50, 2, 'Weekly delivery');
```

## JSON Data Structures

### Product Attributes

```json
{
  "weight": "500ml",
  "brand": "Coca Cola",
  "calories": 140,
  "caffeine": "34mg"
}
```

### Customer Preferences

```json
{
  "preferred_categories": ["Beverages", "Snacks"],
  "email_receipts": true,
  "birthday_offers": true
}
```

### Receipt Data

```json
{
  "receipt_number": "RCP-20250620-000001",
  "store_info": {
    "store_name": "Main Store",
    "address": "123 Main Street"
  },
  "items": [...],
  "payment_details": {...}
}
```

## Key Stored Procedures

| Procedure                    | Purpose                               |
| ---------------------------- | ------------------------------------- |
| `ProcessSale()`              | Complete sales transaction processing |
| `ProcessReturn()`            | Handle product returns and refunds    |
| `GenerateReceipt()`          | Create and store receipt data         |
| `RestockInventory()`         | Add inventory with logging            |
| `ApplyDiscount()`            | Apply promotional discounts           |
| `SearchProductByBarcode()`   | Quick product lookup                  |
| `GetCustomerByPhone()`       | Customer identification               |
| `GenerateDailySalesReport()` | Daily sales analytics                 |
| `GetTopSellingProducts()`    | Product performance analysis          |
| `AdjustInventory()`          | Manual inventory adjustments          |

## Automated Triggers

* **Inventory Logging** - Automatically logs all stock changes
* **Low Stock Alerts** - Triggers alerts when stock drops below minimum
* **Audit Trail** - Logs all data modifications
* **Stock Validation** - Prevents overselling
* **Customer Updates** - Maintains customer totals and loyalty points
* **Data Integrity** - Prevents deletion of referenced records

## Technical Specifications

* **Database Engine:** InnoDB for ACID compliance
* **Character Set:** UTF8MB4 for full Unicode support
* **JSON Support:** MySQL 8.0+ native JSON functions
* **Normalization:** 3NF (Third Normal Form) compliance
* **Referential Integrity:** Foreign key constraints throughout
* **Data Types:** Optimized for storage and performance
* **Indexing:** Strategic covering and composite indexes

## Testing and Validation

The `05_sample_queries.sql` and `pos_system_fixes.sql` files demonstrate:

* All core POS operations
* Advanced reporting capabilities
* JSON data manipulation
* Data integrity checks
* Performance analytics
* Business intelligence queries

## Conclusion

This POS system demonstrates the power of MySQL 8.0+ for building comprehensive business applications using only SQL. The system provides:

✅ **Complete POS Functionality** - All core and bonus features implemented
✅ **Production-Ready Design** - Proper normalization, indexing, and constraints
✅ **Comprehensive Testing** - Extensive sample queries and scenarios
✅ **Detailed Documentation** - Clear instructions and examples
✅ **Extensible Architecture** - Easy to modify and enhance
✅ **Business Rule Enforcement** - Automated data integrity and validation
✅ **Rich Reporting** - Multiple views and analytical capabilities
✅ **Audit Trail** - Complete change tracking and logging

---

**Project Information:**
**Project:** POS System in MySQL
**Version:** 1.0.1
**Date:** June 24, 2025
**Database:** MySQL 8.0+
**License:** Educational Use

**Files Summary:**

* `01_database_schema.sql` - 13 tables, 8 views, comprehensive indexing
* `02_sample_data.sql` - Sample data (max 10 entries per table)
* `03_stored_procedures.sql` - 10+ business logic procedures
* `04_triggers.sql` - 10+ automated data integrity triggers
* `05_sample_queries.sql` - 20+ demonstration queries
* `pos_system_fixes.sql` - Fixed procedures and comprehensive testing
* `README.md` - Complete documentation and usage guide
