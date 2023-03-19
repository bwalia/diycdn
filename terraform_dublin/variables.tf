## cat variables.tf
variable "vpc_id" {
  default = "vpc-0ebd697f77a0586a8"
  description = "DiyCDN dublin VPC ID"
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
    default = "eu-west-1"   
}

variable "AVAILABILITY_ZONE_A" {    
    default = "eu-west-1a"
}

variable "AVAILABILITY_ZONE_B" {    
    default = "eu-west-1b"
}

variable "DIYCDN_POP_NAME" {    
    default = "cdn-pop"
}

variable "AWS_REGION_NAME" {    
    default = "dublin"
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
        eu-west-1 = "ami-096b8af59aae5081c" // amazon linux 2 eu-west-1
    }
}

variable "POP_SUBNET_A_DUBLIN" {
  type = string
  default = "subnet-06e6be1125a991c0d"
}

variable "POP_SUBNET_B_DUBLIN" {
  type = string
  default = "subnet-05d1879920f9f342a"
}

variable "DIYCDN_POP_SG" {
default = "sg-08e1042f5e462002f"
}

variable "DIYCDN_POP_SG_NAME" {
default = "DiyCDN.cloud.dublin.sg.linux"
}

variable "DIYCDN_POP_EC2_KEYPAIR" {
default = "nginx_openresty"
}

data "aws_instances" "DIYCDN_POP_dublin_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "POP" = "cdn-pop-dublin"
  }

}

data "aws_instances" "DIYCDN_POP_ireland_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "POP" = "cdn-pop-ireland"
  }

}
