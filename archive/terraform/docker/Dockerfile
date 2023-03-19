FROM alpine:3.14

ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_DEFAULT_REGION=""
ENV AWS_PROFILE=""
ENV PROJECT_ID=""

ARG PROJECT_ID=""
ARG EC2_SSH_PUBLIC_KEY=""

ARG AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
ARG AWS_PROFILE=$AWS_PROFILE

ENV POP_NAME="cdn-pop"
ENV POP_CLOUD_PROVIDER="aws"
ENV POP_ACTION="create"

RUN apk add bash
RUN apk add aws-cli
RUN apk add git
RUN apk add terraform

RUN mkdir ~/.aws
RUN echo "[default]" >> ~/.aws/credentials
RUN echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
RUN echo "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
RUN echo "region=us-west-2" >> ~/.aws/credentials
RUN echo "output=json" >> ~/.aws/credentials

RUN mkdir -p ~/.ssh
RUN mkdir -p /root/.ssh

WORKDIR /

COPY terraform/ /

ENTRYPOINT ["bash", "docker/kickstart_terraform.sh"]