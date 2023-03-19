aws sts get-caller-identity

# whoami

# pwd

# ls -alh /root/
# ls -alh /root/.ssh/

# cat /root/.ssh/id_rsa
# cat /root/.ssh/id_rsa.pub

#terraform taint module.server.aws_key_pair.pub_key
terraform init

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
  POP_ENV=test
fi

if [ -z ${AWS_PROFILE} ];
then
  AWS_PROFILE=default
fi

if [ -z ${PROJECT_ID} ];
then
  PROJECT_ID=syn-devops
fi

if [ -z ${AWS_DEFAULT_REGION} ];
then
  AWS_DEFAULT_REGION=eu-west-2
fi

cp -r /public_keys/* ~/.ssh/

if [ "$POP_ACTION" = "create" ]; then
aws s3 cp s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate terraform.tfstate
#terraform plan
terraform apply -var="POP_ENV=$POP_ENV" -var="AWS_PROFILE=$AWS_PROFILE" -var="AWS_REGION=$AWS_DEFAULT_REGION" --auto-approve
aws s3 cp terraform.tfstate s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate
fi

if [ "$POP_ACTION" = "destroy" ]; then
aws s3 cp s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate terraform.tfstate
#terraform plan
terraform destroy -var="POP_ENV=$POP_ENV" -var="AWS_PROFILE=$AWS_PROFILE" -var="AWS_REGION=$AWS_DEFAULT_REGION" --auto-approve
aws s3 cp terraform.tfstate s3://$POP_STATE_BUCKET/$PROJECT_ID/$POP_ENV/terraform.tfstate
fi
