name: CDN PoP Manager

on:
  push:
    branches: [ dummy ]
  pull_request:
    branches: [ feature/* ]
  workflow_dispatch:
    inputs:
      pop_action:
        type: choice
        description: 'Please choose the CDN PoP CRUD Action'
        default: 'create'
        required: true
        options:
        - create
        - destroy
        - Choose

      AWS_REGION_NAME:
        type: choice
        description: 'Please choose the AWS Region name'
        default: 'london'
        required: true
        options:
        - london
        - dublin
        - Choose

      ec2_instance_type:
        type: choice
        description: 'Please choose the EC2 Instance type'
        default: 't2.nano'
        required: true
        options:
        - t2.nano
        - t2.small
        - t2.medium
        - t3.medium
        - t3a.medium
        - Choose

      # ec2_instance_count_per_az:
      #   type: choice
      #   description: 'Please choose the no of EC2 Instances per AZ in the POP'
      #   default: '2'
      #   required: true
      #   options:
      #   - '1'
      #   - '2'
      #   - '3'
      #   - '4'
      #   - '5'
      #   - '6'
      #   - Choose

env:
  AWS_ACCOUNT_NO: ${{ secrets.AWS_ACCOUNT_NO }}
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_DEFAULT_REGION: ${{ secrets.AWS_DEFAULT_REGION }}
  EC2_SSH_PRIVATE_KEY: ${{ secrets.EC2_SSH_PRIVATE_KEY }}
  EC2_SSH_PUBLIC_KEY: ${{ secrets.EC2_SSH_PUBLIC_KEY }}

  AWS_EC2_SSH_PRIVATE_KEY: ${{ secrets.AWS_EC2_SSH_PRIVATE_KEY }}
  AWS_EC2_SSH_PUBLIC_KEY: ${{ secrets.AWS_EC2_SSH_PUBLIC_KEY }}

  CDN_CLOUD_WILDCARD_CRT: ${{ secrets.CDN_CLOUD_WILDCARD_CRT }}
  CDN_CLOUD_WILDCARD_KEY: ${{ secrets.CDN_CLOUD_WILDCARD_KEY }}
  CDN_OPSAPI_SIGN_KEY: ${{ secrets.CDN_OPSAPI_SIGN_KEY }}

  CDN_POP_ACTION: ${{ github.event.inputs.pop_action }}
  EC2_INSTANCE_TYPE: ${{ github.event.inputs.ec2_instance_type }}
  EC2_INSTANCE_COUNT_PER_AZ: 1
  # ${{ github.event.inputs.EC2_INSTANCE_COUNT_PER_AZ }}
  AWS_REGION_NAME: ${{ github.event.inputs.AWS_REGION_NAME }}

jobs:
  # *** This workflow contains a single job called "build" ***
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Create, Update or Destroy CDN PoP
        run: chmod +x ./pop_manager.sh && ./pop_manager.sh "${{ env.AWS_EC2_SSH_PRIVATE_KEY }}" "${{ env.CDN_POP_ACTION }}" "${{ env.AWS_EC2_SSH_PUBLIC_KEY }}" "${{ env.CDN_CLOUD_WILDCARD_CRT }}" "${{ env.CDN_CLOUD_WILDCARD_KEY }}" "${{ env.CDN_OPSAPI_SIGN_KEY }}" "${{ env.EC2_INSTANCE_TYPE }}" "${{ env.EC2_INSTANCE_COUNT_PER_AZ }}" "${{ env.AWS_REGION_NAME }}"

      - name: Slack Notification for Workstation CRM release 
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_CHANNEL: general
          SLACK_COLOR: ${{ job.status }}
          SLACK_ICON: https://github.com/rtCamp.png?size=48
          SLACK_MESSAGE: 'Post Content :rocket:'
          SLACK_TITLE: Post Title
          SLACK_USERNAME: rtCamp
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
