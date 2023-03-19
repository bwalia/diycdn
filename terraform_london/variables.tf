## cat variables.tf
variable "vpc_id" {
  default = "vpc-b86529d1"
  description = "DiyCDN London VPC ID"
  type        = string
}
# output "vpc_id" {
#   value = aws_vpc.production_vpc.id
# }
variable "INSTANCE_COUNT_PER_AZ" {
    default = "1"
}

variable "INSTANCE_TYPE" {
    default = "t2.nano"
}

variable "POP_ENV" {
    default = "test"   
}

variable "AWS_PROFILE" {  
    default = "default"   
}

variable "AWS_REGION" {  
    default = "eu-west-2"   
}

variable "AVAILABILITY_ZONE_A" {    
    default = "eu-west-2a"
}

variable "AVAILABILITY_ZONE_B" {    
    default = "eu-west-2b"
}


variable "DIYCDN_POP_NAME" {    
    default = "cdn-pop"
}

variable "AWS_REGION_NAME" {    
    default = "london"
}


variable "PUBLIC_KEY_PATH" {
type = string
default = "~/.ssh/id_rsa.pub"

}

variable "PRIVATE_KEY_PATH" {
type = string
default = "~/.ssh/id_rsa"

}

variable "EC2_USER" {
  type = string
  default = "ec2-user"
}

variable "AMI" {
    type = map
    
    default = {
        eu-west-2 = "ami-03ac5a9b225e99b02" // amazon linux 2 old ami-0e34bbddc66def5ac
    }
}

variable "POP_SUBNET_A_LONDON" {
  type = string
  default = "subnet-c5b3cdbe"
}

variable "POP_SUBNET_B_LONDON" {
  type = string
  default = "subnet-441c9709"
}

variable "DIYCDN_POP_SG" {
default = "terraform-20210919154732231800000001"
}

variable "DIYCDN_POP_SG_NAME" {
default = "diycdn.cloud.london.sg.linux"
}

variable "DIYCDN_POP_EC2_KEYPAIR" {
default = "nginx_openresty"
}

data "aws_instances" "DIYCDN_POP_london_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "POP" = "cdn-pop-london"
  }

}

data "aws_instances" "DIYCDN_POP_ireland_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "POP" = "cdn-pop-england"
  }

}
