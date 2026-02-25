-- ========================================
-- ICEBERG SCHEMA EVOLUTION TEST
-- ========================================

-- Step 1: Create initial table
CREATE TABLE sales_db.daily_sales (
    sale_date date,
    product_category string,
    sales_amount double
)
PARTITIONED BY (month(sale_date))
TBLPROPERTIES ('table_type' = 'iceberg');

-- Step 2: Insert initial data
INSERT INTO daily_sales
VALUES
(DATE '2024-01-15', 'Laptop', 900.00),
(DATE '2024-01-15', 'Monitor', 250.00),
(DATE '2024-01-16', 'Laptop', 1350.00),
(DATE '2024-02-01', 'Monitor', 300.00),
(DATE '2024-02-01', 'Keyboard', 60.00),
(DATE '2024-02-02', 'Mouse', 25.00),
(DATE '2024-02-02', 'Laptop', 1050.00),
(DATE '2024-02-03', 'Laptop', 1200.00),
(DATE '2024-02-03', 'Monitor', 375.00);

-- Step 3: Query initial data
SELECT * FROM daily_sales;

-- ========================================
-- SCHEMA EVOLUTION EXAMPLES
-- ========================================

-- Example 1: ADD NEW COLUMNS
-- Add customer_id and store_location columns
ALTER TABLE daily_sales 
ADD COLUMNS (
    customer_id bigint,
    store_location string
);

-- Insert data with new schema
INSERT INTO daily_sales
VALUES
(DATE '2024-03-01', 'Laptop', 1100.00, 12345, 'New York'),
(DATE '2024-03-01', 'Mouse', 30.00, 12346, 'Los Angeles'),
(DATE '2024-03-02', 'Keyboard', 75.00, 12347, 'Chicago');

-- Query: Old data will have NULL for new columns
SELECT * FROM daily_sales ORDER BY sale_date;

-- Example 2: RENAME COLUMN
-- Rename sales_amount to revenue
ALTER TABLE daily_sales 
RENAME COLUMN sales_amount TO revenue;

-- Query with new column name
SELECT sale_date, product_category, revenue, customer_id, store_location
FROM daily_sales
ORDER BY sale_date DESC
LIMIT 5;

-- Example 3: CHANGE COLUMN TYPE (Widening)
-- Change customer_id from bigint to string (for alphanumeric IDs)
ALTER TABLE daily_sales 
ALTER COLUMN customer_id TYPE string;

-- Insert with string customer_id
INSERT INTO daily_sales
VALUES
(DATE '2024-03-03', 'Monitor', 400.00, 'CUST-001', 'Boston'),
(DATE '2024-03-03', 'Laptop', 1250.00, 'CUST-002', 'Seattle');

-- Example 4: ADD COLUMN WITH COMMENT
ALTER TABLE daily_sales 
ADD COLUMNS (
    discount_applied double COMMENT 'Discount percentage applied to sale'
);

-- Insert with discount
INSERT INTO daily_sales
VALUES
(DATE '2024-03-04', 'Laptop', 950.00, 'CUST-003', 'Miami', 0.15),
(DATE '2024-03-04', 'Keyboard', 55.00, 'CUST-004', 'Denver', 0.10);

-- Example 5: DROP COLUMN (if needed)
-- Note: Dropping columns doesn't delete data, just hides it
ALTER TABLE daily_sales 
DROP COLUMN discount_applied;

-- ========================================
-- ANALYTICS QUERIES AFTER EVOLUTION
-- ========================================

-- Query 1: Sales by location (new column)
SELECT 
    store_location,
    COUNT(*) as total_sales,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_revenue
FROM daily_sales
WHERE store_location IS NOT NULL
GROUP BY store_location
ORDER BY total_revenue DESC;

-- Query 2: Sales by product with customer info
SELECT 
    product_category,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(*) as total_transactions,
    SUM(revenue) as total_revenue
FROM daily_sales
WHERE customer_id IS NOT NULL
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Query 3: Time series with all data (old and new schema)
SELECT 
    DATE_TRUNC('month', sale_date) as month,
    product_category,
    COUNT(*) as units_sold,
    SUM(revenue) as monthly_revenue,
    COUNT(customer_id) as sales_with_customer_info
FROM daily_sales
GROUP BY DATE_TRUNC('month', sale_date), product_category
ORDER BY month, monthly_revenue DESC;

-- ========================================
-- VIEW TABLE SCHEMA HISTORY
-- ========================================

-- Check current schema
DESCRIBE daily_sales;

-- View table properties
SHOW TBLPROPERTIES daily_sales;

-- ========================================
-- KEY TAKEAWAYS
-- ========================================

/*
1. ADD COLUMNS: New columns appear as NULL in old records
2. RENAME COLUMNS: Existing data is preserved, just accessed with new name
3. CHANGE TYPE: Only widening conversions are safe (int -> bigint, float -> double)
4. DROP COLUMNS: Data is hidden but not deleted (can be recovered)
5. NO DOWNTIME: All changes happen without rewriting existing data
6. BACKWARD COMPATIBLE: Old queries still work (if columns exist)
*/
