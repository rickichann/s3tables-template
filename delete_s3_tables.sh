# Set variables

REGION="ap-xxxxxxxxx-xx"

BUCKET_ARN="arn:aws:s3tables:<region>:<account-id>:bucket/<table-bucket-name>"

# Delete all tables in all namespaces

for namespace in $(aws s3tables list-namespaces --region $REGION --table-bucket-arn $BUCKET_ARN --query 'namespaces[].namespace[]' --output text); do

  for table in $(aws s3tables list-tables --region $REGION --table-bucket-arn $BUCKET_ARN --namespace $namespace --query 'tables[].name' --output text); do

    echo "Deleting table: $namespace.$table"

    aws s3tables delete-table --region $REGION --table-bucket-arn $BUCKET_ARN --namespace $namespace --name $table

  done

done

# Delete all namespaces

for namespace in $(aws s3tables list-namespaces --region $REGION --table-bucket-arn $BUCKET_ARN --query 'namespaces[].namespace[]' --output text); do

  echo "Deleting namespace: $namespace"

  aws s3tables delete-namespace --region $REGION --table-bucket-arn $BUCKET_ARN --namespace $namespace

done

# Delete the bucket

aws s3tables delete-table-bucket --region $REGION --table-bucket-arn $BUCKET_ARN