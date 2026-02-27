# S3 Tables Snapshot Rollback - Documented Notebook

## Cell 1: Configure Spark Session for S3 Tables
**Purpose:** Sets up Spark with Iceberg and S3 Tables support
- Loads required JAR packages for Iceberg runtime and S3 Tables catalog
- Configures S3 Tables catalog to connect to your bucket
- Sets S3 Tables as the default catalog so you don't need to prefix table names

```python
%%configure -f
{
  "conf": {
    "spark.jars.packages": "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.6.1,software.amazon.s3tables:s3-tables-catalog-for-iceberg-runtime:0.1.8",
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.s3tables": "org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.s3tables.catalog-impl": "software.amazon.s3tables.iceberg.S3TablesCatalog",
    "spark.sql.catalog.s3tables.warehouse": "arn:aws:s3tables:ap-southeast-3:339712808680:bucket/sandbox-bucket-fresh",
    "spark.sql.defaultCatalog": "s3tables"
  }
}
```

---

## Cell 2: List All Databases (Namespaces)
**Purpose:** Shows all available databases in your S3 Tables bucket
**Expected Output:** sales_db, marketing_db, analytics_db

```python
%%sql
SHOW DATABASES
```

---

## Cell 3: List Tables in sales_db
**Purpose:** Displays all tables within the sales_db database
**Expected Output:** daily_sales table

```python
%%sql
SHOW TABLES IN sales_db
```

---

## Cell 4: Query Current Data
**Purpose:** Retrieves all records from the daily_sales table
**What it shows:** The current state of the table (latest version)

```python
%%sql
SELECT * FROM sales_db.daily_sales
```

---

## Cell 5: View Table Snapshots History
**Purpose:** Lists all snapshots (versions) of the table with timestamps
**What is a snapshot?** Each snapshot represents a point-in-time version of the table
- Every INSERT, UPDATE, DELETE creates a new snapshot
- Snapshots are ordered by most recent first
- You can use snapshot IDs for time-travel queries or rollback

```python
%%sql
SELECT * FROM sales_db.daily_sales.snapshots ORDER BY committed_at DESC
```

**Output columns:**
- `snapshot_id`: Unique identifier for this version
- `committed_at`: Timestamp when this version was created
- `parent_id`: Previous snapshot ID
- `operation`: Type of operation (append, overwrite, delete)

---

## Cell 6: Query Data from Specific Snapshot (Time Travel)
**Purpose:** Reads data as it existed at snapshot 6202631609281300944
**Use case:** View historical data without modifying the current table
- Useful for auditing or comparing changes
- Does NOT change the current table state
- Other users still see the latest data

```python
%%sql
SELECT * FROM sales_db.daily_sales VERSION AS OF 6202631609281300944
```

---

## Cell 7: Rollback Table to Previous Snapshot
**Purpose:** Restores the table to snapshot 6202631609281300944
**⚠️ WARNING:** This changes the current table state for ALL users
**When to use:**
- Undo accidental data deletion
- Revert bad data updates
- Restore to a known good state

**What happens:**
- Current table pointer moves to the specified snapshot
- No data is physically deleted (old snapshots remain)
- All users will now see data from the rollback snapshot

```python
%%sql
CALL s3tables.system.rollback_to_snapshot(
    table => 'sales_db.daily_sales',
    snapshot_id => 6202631609281300944
)
```

---

## Cell 8: Verify Rollback
**Purpose:** Query the table after rollback to confirm data has been restored
**What to check:** Compare this output with Cell 6 (should be identical)

```python
%%sql
SELECT * FROM sales_db.daily_sales
```

---

## Key Concepts

### Snapshots
- **Immutable versions** of your table at specific points in time
- Created automatically on every write operation
- Enable time-travel queries and rollback capabilities

### Time Travel
- Query historical data using `VERSION AS OF snapshot_id`
- Read-only operation, doesn't affect current table
- Useful for auditing and data recovery

### Rollback
- Changes the current table state to a previous snapshot
- Affects all users querying the table
- Reversible (you can rollback to any snapshot)

---

## Common Use Cases

### 1. Undo Accidental Delete
```sql
-- View snapshots before the delete
SELECT * FROM sales_db.daily_sales.snapshots ORDER BY committed_at DESC;

-- Rollback to snapshot before delete
CALL s3tables.system.rollback_to_snapshot(
    table => 'sales_db.daily_sales',
    snapshot_id => <snapshot_id_before_delete>
);
```

### 2. Compare Data Between Versions
```sql
-- Current data
SELECT COUNT(*) as current_count FROM sales_db.daily_sales;

-- Historical data
SELECT COUNT(*) as historical_count 
FROM sales_db.daily_sales VERSION AS OF <snapshot_id>;
```

### 3. Audit Changes
```sql
-- See what changed between snapshots
SELECT * FROM sales_db.daily_sales VERSION AS OF <old_snapshot>
EXCEPT
SELECT * FROM sales_db.daily_sales VERSION AS OF <new_snapshot>;
```

---

## Troubleshooting

### Issue: Snapshot ID not found
**Solution:** Run Cell 5 to get valid snapshot IDs

### Issue: Rollback fails with permission error
**Solution:** Ensure your EMR role has `s3tables:UpdateTable` permission

### Issue: Can't see snapshots
**Solution:** Table must be an Iceberg table with snapshot history

---

## Best Practices

1. **Always check snapshots** before rollback (Cell 5)
2. **Test with time-travel** first (Cell 6) before rollback
3. **Document why** you're doing a rollback
4. **Communicate** with team before rollback in production
5. **Keep snapshot retention** policy to avoid losing history

---

## Additional Resources

- [Apache Iceberg Snapshots](https://iceberg.apache.org/docs/latest/branching/)
- [AWS S3 Tables Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables.html)
- [Iceberg Time Travel](https://iceberg.apache.org/docs/latest/spark-queries/#time-travel)
