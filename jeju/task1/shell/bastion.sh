sudo chmod 777 /home/ec2-user
sudo chown ec2-user:ec2-user /home/ec2-user
cd /home/ec2-user
ls -ld $(pwd)  # 디렉터리 권한 확인
sudo chmod 777 $(pwd)  # 모든 사용자에게 쓰기 권한 부여

private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsc-prod-workload-sn-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsc-prod-workload-sn-c" --query "Subnets[].SubnetId[]" --output text)
sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='wsc-controlplan-sg'].GroupId" --output text)

sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml
sed -i "s|sg_id|$sg_id|g" cluster.yaml