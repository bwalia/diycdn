#!/bin/bash
set -x
exit 1































aws sts get-caller-identity

#terraform taint module.server.aws_key_pair.pub_key
terraform init
#terraform import vpc.id $VPC_ID

# mkdir ~/.ssh/
# cat $PUBLIC_SSH_KEY > ~/.ssh/id_rsa.pub
# cat /root/.aws/credentials

if [ -z ${POP_ACTION} ];
then
  echo "POP_ACTION env var is required and it is not provided."
  exit 1
fi

if [ -z ${POP_STATE_BUCKET} ];
then
  echo "POP_STATE_BUCKET env var is required and it is not provided."
  exit 1
fi

if [ -z ${POP_ENV} ];
then
  POP_ENV=prod
fi

if [ -z ${AWS_PROFILE} ];
then
  AWS_PROFILE=default
fi

if [ -z ${PROJECT_ID} ];
then
  PROJECT_ID=cdn-pop-prod
fi

if [ -z ${AWS_DEFAULT_REGION} ];
then
  AWS_DEFAULT_REGION=eu-west-2
fi

if [ -z ${EC2_INSTANCE_TYPE} ];
then
  EC2_INSTANCE_TYPE="t2.nano"
fi

cp -r /public_keys/* ~/.ssh/

#ls -alt ~/.ssh/

# echo "Private key:"
# cat ~/.ssh/id_rsa
# echo "Public key:"
# cat ~/.ssh/id_rsa.pub


# if [[ "$PROJECT_ID" == "cdn-pop-prod" ]]; then
# terraform import aws_vpc.aws_london_existing_vpc vpc-0ebd697f77a0586a8
# else
# fi
#if [[ "$PROJECT_ID" == "xxxx" ]]; then

if [ "$POP_ACTION" = "create" ]; then
aws s3 cp s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate terraform.tfstate --region eu-west-2
#terraform plan
terraform apply -var="POP_ENV=$POP_ENV" -var="AWS_PROFILE=$AWS_PROFILE" -var="AWS_REGION=$AWS_DEFAULT_REGION" -var="INSTANCE_TYPE=$EC2_INSTANCE_TYPE" --auto-approve
aws s3 cp terraform.tfstate s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate --region eu-west-2

terraform output --raw ec2_a_public_ip > /tmp/ec2_a_public_ip.txt
terraform output --raw ec2_b_public_ip > /tmp/ec2_b_public_ip.txt

env_ec2_a_public_ip=$(cat /tmp/ec2_a_public_ip.txt)
env_ec2_b_public_ip=$(cat /tmp/ec2_b_public_ip.txt)
export env_ec2_a_public_ip=$(cat /tmp/ec2_a_public_ip.txt)
export env_ec2_b_public_ip=$(cat /tmp/ec2_b_public_ip.txt)

cp docker/aws_route53_zone_template.json /tmp/aws_route53_zone.json
# Route53 DNS with the new IP address for Nginx Server A
#sed -i -e "s/cdn-pop-london-prod-X.DiyCDN.cloud./cdn-pop-london-prod-a.DiyCDN.cloud./;/0.0.0.0/$env_ec2_a_public_ip/g" /tmp/aws_route53_zone.json
find="0.0.0.0"
replace=$env_ec2_a_public_ip
sed -i "s/$find/$replace/g" /tmp/aws_route53_zone.json
#
find="cdn-pop-london-prod-X.DiyCDN.cloud."
replace="cdn-pop-london-prod-a.DiyCDN.cloud."
sed -i "s/$find/$replace/g" /tmp/aws_route53_zone.json
#sed -i 's//cdn-pop-london-prod-a.DiyCDN.cloud./;/0.0.0.0/$env_ec2_a_public_ip/g' 
cat /tmp/aws_route53_zone.json
aws route53 change-resource-record-sets --hosted-zone-id Z2UC9MSHC6JR6K --change-batch file://tmp/aws_route53_zone.json

# Route53 DNS with the new IP address for Nginx Server B
cp docker/aws_route53_zone_template.json /tmp/aws_route53_zone.json
find="0.0.0.0"
replace=$env_ec2_b_public_ip
sed -i "s/$find/$replace/g" /tmp/aws_route53_zone.json
#
find="cdn-pop-london-prod-X.DiyCDN.cloud."
replace="cdn-pop-london-prod-b.DiyCDN.cloud."
sed -i "s/$find/$replace/g" /tmp/aws_route53_zone.json
#sed -i 's//cdn-pop-london-prod-a.DiyCDN.cloud./;/0.0.0.0/$env_ec2_a_public_ip/g' 
cat /tmp/aws_route53_zone.json
aws route53 change-resource-record-sets --hosted-zone-id Z2UC9MSHC6JR6K --change-batch file://tmp/aws_route53_zone.json
fi

if [ "$POP_ACTION" = "destroy" ]; then
aws s3 cp s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate terraform.tfstate --region eu-west-2
#terraform plan
terraform destroy -var="POP_ENV=$POP_ENV" -var="AWS_PROFILE=$AWS_PROFILE" -var="AWS_REGION=$AWS_DEFAULT_REGION" --auto-approve
aws s3 cp terraform.tfstate s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate --region eu-west-2
fi
#fi