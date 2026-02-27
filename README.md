# S3 Tables with Apache Iceberg - Terraform

Infrastructure as Code (IaC) for creating AWS S3 Tables with Apache Iceberg format using Terraform.

## Overview

This project provisions AWS S3 Tables infrastructure including:
- S3 Table Bucket for storing Iceberg tables
- Namespaces (logical databases)
- AWS Glue Data Catalog integration for Athena queries

## Prerequisites

Before you begin, ensure you have:

- **AWS Credentials** with permissions for:
  - `s3tables:*`
  - `glue:*`
  - `sts:GetCallerIdentity`

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd s3tables-template
```

### 2. Configure Variables

Create a `terraform.tfvars` file (not tracked in git):

```hcl
aws_region        = "ap-southeast-3"
table_bucket_name = "your-unique-bucket-name"

namespaces = {
  "sales_db"      = {}
  "marketing_db"  = {}
  "analytics_db"  = {}
}
```


### 3. Create S3 Tables Bucket

The bucket must be created via AWS CLI due to a Terraform provider limitation:

```bash
aws s3tables create-table-bucket --name your-unique-bucket-name --region ap-southeast-3
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted to confirm.

## Architecture

```
S3 Table Bucket (sandbox-bucket-fresh)
├── Namespace: sales_db
├── Namespace: marketing_db
└── Namespace: analytics_db

AWS Glue Data Catalog
├── Database: sales_db
├── Database: marketing_db
└── Database: analytics_db
```

## Configuration

### Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `aws_region` | string | AWS region for resources | `us-east-1` |
| `table_bucket_name` | string | Unique name for S3 table bucket | Required |
| `namespaces` | map | Map of namespace names to create | `{}` |

### Outputs

| Output | Description |
|--------|-------------|
| `table_bucket_arn` | ARN of the S3 table bucket |
| `namespaces` | Map of created namespace names |
| `glue_databases` | Map of created Glue database names |

## Usage with AWS Athena

After deployment, you can query your S3 Tables using AWS Athena:

1. Open AWS Athena Console
2. Select your database (e.g., `sales_db`)
3. Create tables and query data using standard SQL

Example:

```sql
--Use the following statement to create a table in your S3 Table bucket.
CREATE TABLE `sales_db`.daily_sales (
sale_date date, 
product_category string, 
sales_amount double)
PARTITIONED BY (month(sale_date))
TBLPROPERTIES ('table_type' = 'iceberg')

/*
Next steps 1) Use the following SQL statement to insert data to your table.
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

2) Use the following SQL statement to run a sample analytics query.
SELECT 
product_category,
COUNT(*) as units_sold,
SUM(sales_amount) as total_revenue,
AVG(sales_amount) as average_price
FROM daily_sales
WHERE sale_date BETWEEN DATE '2024-02-01' and DATE '2024-02-29'
GROUP BY product_category
ORDER BY total_revenue DESC;
*/

```

## Troubleshooting

### Issue: "aws" or "terraform" not recognized

**Solution:** Set PowerShell aliases or restart your computer after installation to refresh PATH.

### Issue: Glue Database already exists

**Solution:** Import existing databases or delete them first:

```bash
aws glue delete-database --name sales_db --region ap-southeast-3
```

### Issue: Table bucket already exists

**Solution:** Use a different bucket name or delete the existing one:

```bash
aws s3tables delete-table-bucket \
  --table-bucket-arn "arn:aws:s3tables:REGION:ACCOUNT_ID:bucket/BUCKET_NAME" \
  --region REGION
```

## Clean Up

To destroy all resources:

```bash
# Destroy Terraform-managed resources
terraform destroy

# Delete the S3 table bucket (get ARN from terraform output)
aws s3tables delete-table-bucket \
  --table-bucket-arn "arn:aws:s3tables:ap-southeast-3:YOUR_ACCOUNT_ID:bucket/your-bucket-name" \
  --region ap-southeast-3
```

## Project Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── terraform.tfvars     # Variable values (not in git)
├── .gitignore          # Git ignore rules
└── README.md           # This file
```



## Resources

- [AWS S3 Tables Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables.html)

