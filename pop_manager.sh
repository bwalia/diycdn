#!/bin/bash

# ./pop_manager.sh "user_access_private_access_key" "create|destroy" "user_access_public_access_key" "sslcert" "sslcertkey" "opsapikey" "instancetype"

set -x
POP_ACTION=$2

if [ -z ${POP_ACTION} ];
then
  POP_ACTION="create"
fi

if [ -z ${POP_ACTION} ];
then
  POP_ACTION="create"
fi

if test -z "$POP_ACTION" 
then
      echo "\$POP_ACTION is empty"
      POP_ACTION="create"
else
      echo "\$POP_ACTION is NOT empty"
fi

if [ -z ${PROJECT_ID} ];
then
  PROJECT_ID="cdn-pop-prod"
fi

if test -z "$PROJECT_ID" 
then
      echo "\$PROJECT_ID is empty"
      PROJECT_ID="cdn-pop-prod"
else
      echo "\$PROJECT_ID is NOT empty"
fi

if [ -z ${DOCKER_IMAGE_ID} ];
then
  DOCKER_IMAGE_ID="terraform_runner"
fi

if test -z "$DOCKER_IMAGE_ID" 
then
      echo "\$DOCKER_IMAGE_ID is empty"
      DOCKER_IMAGE_ID="terraform_runner"
else
      echo "\$DOCKER_IMAGE_ID is NOT empty"
fi

if [[ "$PROJECT_ID" == "cdn-pop-prod" ]]; then
      DOCKER_IMAGE_ID="terraform_runner_pop"

else
if [[ "$PROJECT_ID" == "cdn-alb" ]]; then
      DOCKER_IMAGE_ID="terraform_runner_alb"
else
      DOCKER_IMAGE_ID="terraform_runner"
fi
fi

if [ -z ${POP_ENV} ];
then
  POP_ENV="prod"
fi

if [ -z ${POP_REGION} ];
then
  POP_REGION="eu-west-2"
fi

if [ -z ${POP_STATE_BUCKET} ];
then
  POP_STATE_BUCKET="cdn-cloud-tf-state"
fi

if [ -z "$3" ];
then
  echo "ssh key is not set"
  exit 1
fi

if [ -z "$4" ];
then
  echo "tls api cert is not set"
  exit 1
fi

if [ -z "$5" ];
then
  echo "tls api cert key is not set"
  exit 1
fi

if [ -z "$6" ];
then
  echo "api token sign key is not set"
  exit 1
fi

if [ -z "$7" ];
then
  echo "ec2 instance type is not set"
  EC2_INSTANCE_TYPE="t2.nano"
else
  EC2_INSTANCE_TYPE=$7
fi

if [ -z "$8" ];
then
  echo "ec2 instance count is not set default is 2"
  EC2_INSTANCE_COUNT_PER_AZ="1"
else
  EC2_INSTANCE_COUNT_PER_AZ=$8
fi

if [ -z "$9" ];
then
  echo "aws region name is not set default is london"
  AWS_REGION_NAME="london"
else
  AWS_REGION_NAME=$9
fi

if [ "$AWS_REGION_NAME" == "dublin" ]; then
  POP_REGION="eu-west-1"
fi

if [ "$AWS_REGION_NAME" == "london" ]; then
  POP_REGION="eu-west-2"
fi

DOCKER_IMAGE_NAME="$DOCKER_IMAGE_ID"_"$AWS_REGION_NAME"

bash docker-build-and-run.sh "$1" "$DOCKER_IMAGE_NAME" "$PROJECT_ID" "$3" "$4" "$5" "$6" "$AWS_REGION_NAME"

docker run \
-e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
-e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
-e "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" \
-e "AWS_PROFILE=${AWS_PROFILE}" \
-e "POP_ENV=${POP_ENV}" \
-e "PROJECT_ID=${PROJECT_ID}" \
-e "POP_ACTION=${POP_ACTION}" \
-e "POP_STATE_BUCKET=${POP_STATE_BUCKET}" \
-e "AWS_PROFILE=default" \
-e "AWS_DEFAULT_REGION=${POP_REGION}" \
-e "EC2_INSTANCE_TYPE=${EC2_INSTANCE_TYPE}" \
-e "EC2_INSTANCE_COUNT_PER_AZ=${EC2_INSTANCE_COUNT_PER_AZ}" \
-e "AWS_REGION_NAME=${AWS_REGION_NAME}" \
-v "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
-v "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
-v "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" \
-v "AWS_PROFILE=${AWS_PROFILE}" \
-v "PROJECT_ID=${PROJECT_ID}" \
-v "POP_ENV=${POP_ENV}" \
-v "POP_ACTION=${POP_ACTION}" \
-v "POP_STATE_BUCKET=${POP_STATE_BUCKET}" \
-v "AWS_PROFILE=default" \
-v "AWS_DEFAULT_REGION=${POP_REGION}" \
-v "EC2_INSTANCE_COUNT_PER_AZ=${EC2_INSTANCE_COUNT_PER_AZ}" \
-v "EC2_INSTANCE_TYPE=${EC2_INSTANCE_TYPE}" \
-v "AWS_REGION_NAME=${AWS_REGION_NAME}" $DOCKER_IMAGE_NAME
