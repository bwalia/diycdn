#!/bin/bash
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
  PROJECT_ID="cdn-pop"
fi

if test -z "$PROJECT_ID" 
then
      echo "\$PROJECT_ID is empty"
      PROJECT_ID="cdn-pop"
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
      DOCKER_IMAGE_ID="synalbcrudmanager"
else
      DOCKER_IMAGE_ID="terraform_runner"
fi
fi


./docker-build-and-run.sh "$1" "$DOCKER_IMAGE_ID" "$PROJECT_ID"

#echo 
# export PATH=$PATH:/Users/balinderwalia/Documents/Work/4D/4Dv18_Applications/aws/Resources/kube/
# docker run -v "~/.ssh/:/root/.ssh/ -v "~/.aws/:/root/.aws/" -e "POP_ENV=test" -e "POP_ACTION=create" -e "POP_STATE_BUCKET=cdn-cloud-tf-state" -e "AWS_PROFILE=default" -e "AWS_DEFAULT_REGION=eu-west-2 bwalia/tf-DiyCDN

docker run \
-e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
-e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
-e "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" \
-e "AWS_PROFILE=${AWS_PROFILE}" \
-e "POP_ENV=test" \
-e "PROJECT_ID=${PROJECT_ID}" \
-e "POP_ACTION=${POP_ACTION}" \
-e "POP_STATE_BUCKET=cdn-cloud-tf-state" \
-e "AWS_PROFILE=default" \
-e "AWS_DEFAULT_REGION=eu-west-2" \
-v "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
-v "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
-v "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" \
-v "AWS_PROFILE=${AWS_PROFILE}" \
-v "PROJECT_ID=${PROJECT_ID}" \
-v "POP_ENV=test" \
-v "POP_ACTION=${POP_ACTION}" \
-v "POP_STATE_BUCKET=cdn-cloud-tf-state" \
-v "AWS_PROFILE=default" \
-v "AWS_DEFAULT_REGION=eu-west-2" $DOCKER_IMAGE_ID
