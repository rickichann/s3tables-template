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

### 3. Set PowerShell Aliases (Windows Only)

If using PowerShell and commands aren't recognized:

```powershell
Set-Alias -Name aws -Value "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
Set-Alias -Name terraform -Value "C:\terraform\terraform.exe"
```

### 4. Create S3 Tables Bucket

The bucket must be created via AWS CLI due to a Terraform provider limitation:

```bash
aws s3tables create-table-bucket --name your-unique-bucket-name --region ap-southeast-3
```

### 5. Deploy Infrastructure

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
-- Create a table
CREATE TABLE sales_db.orders (
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    amount DECIMAL(10,2)
)
LOCATION 'arn:aws:s3tables:ap-southeast-3:ACCOUNT_ID:bucket/your-bucket-name/sales_db/orders'
TBLPROPERTIES ('table_type'='ICEBERG');

-- Insert data
INSERT INTO sales_db.orders VALUES (1, 100, DATE '2024-01-15', 99.99);

-- Query data
SELECT * FROM sales_db.orders;
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
