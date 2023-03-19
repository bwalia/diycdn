#!/bin/bash

if [ -z "$1" ];
then
  echo "private key is not set"
  exit 1
fi

if [ -z "$2" ];
then
  echo "docker image name id is not set"
  exit 1
fi

if [ -z "$3" ];
then
  echo "project id is not set"
  exit 1
fi


if [ -z "$4" ];
then
  echo "ssh key is not set"
  exit 1
fi

if [ -z "$5" ];
then
  echo "tls api cert is not set"
  exit 1
fi

if [ -z "$6" ];
then
  echo "tls api cert key is not set"
  exit 1
fi

if [ -z "$7" ];
then
  echo "api token sign key is not set"
  exit 1
fi

if [ -z "$8" ];
then
  echo "region name is not set"
  exit 1
fi

AWS_REGION_NAME=$8

echo "$5" > terraform_common/src/api_ssl_cert.crt
echo "$6" > terraform_common/src/api_ssl_cert.key
echo "$7" > terraform_common/src/api_sign.key
# | base64 -d

#echo "${EC2_SSH_PRIVATE_KEY}"
#docker system prune -f

if [[ "$3" == "cdn-pop-prod" ]]; then
touch terraform_common/public_keys/id_rsa
echo "$1" > terraform_common/public_keys/id_rsa
chmod 400 terraform_common/public_keys/id_rsa
#ssh-keygen -y -f terraform_dublin/public_keys/id_rsa > terraform_dublin/public_keys/id_rsa.pub
if [[ "$AWS_REGION_NAME" == "dublin" ]]; then
docker build -f terraform_common/docker/Dockerfile_dublin -t $2 . --no-cache
fi

if [[ "$AWS_REGION_NAME" == "london" ]]; then
docker build -f terraform_common/docker/Dockerfile_london -t $2 . --no-cache
fi

# docker build --build-arg some_variable_name=a_value -t $2 .
rm -Rf terraform_common/public_keys/id_rsa
fi

if [[ "$3" == "cdn-alb" ]]; then
touch terraform_alb/public_keys/id_rsa
echo "$1" > terraform_alb/public_keys/id_rsa
chmod 400 terraform_alb/public_keys/id_rsa
#ssh-keygen -y -f terraform_alb/public_keys/id_rsa > terraform_alb/public_keys/id_rsa.pub

docker build -f terraform_alb/docker/Dockerfile -t $2 . --no-cache
rm -Rf terraform_alb/public_keys/id_rsa
fi

if [[ "$3" == "syn-ec2" ]]; then
touch terraform/public_keys/id_rsa
echo "$1" > terraform/public_keys/id_rsa
chmod 400 terraform/public_keys/id_rsa
#ssh-keygen -y -f terraform/public_keys/id_rsa > terraform/public_keys/id_rsa.pub
docker build -f terraform/docker/Dockerfile -t $2 . --no-cache
rm -Rf terraform/public_keys/id_rsa
fi

