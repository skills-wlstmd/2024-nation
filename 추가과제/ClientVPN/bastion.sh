# VPC ID 가져오기
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=day2-my" --query "Vpcs[].VpcId[]" --region ap-northeast-2 --output text)

# Private Hosted Zone 생성
hosted_zone_id=$(aws route53 create-hosted-zone --name "day2.local" --vpc VPCRegion=ap-northeast-2,VPCId=$vpc_id --caller-reference "$(date +%s)" --query "HostedZone.Id" --output text)

# Aurora Endpoint 가져오기
aurora_endpoint=$(aws rds describe-db-clusters --query "DBClusters[?DBClusterIdentifier=='day2-my-pg'].Endpoint" --output text)

# CNAME 레코드 생성
aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "db.day2.local",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "'"$aurora_endpoint"'"
          }
        ]
      }
    }
  ]
}'

psql -U day2_root -d day2 -h db.day2.local -p 5432

