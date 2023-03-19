## cat variables.tf
variable "INSTANCE_COUNT_PER_AZ" {
    default = "2"
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
        eu-west-2 = "ami-03ac5a9b225e99b02" // amazon linux 2 old ami-0e34bbddc66def5ac
    }
}

data "aws_instances" "DIYCDN_POP_dublin_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "Name" = "cdn-pop-${var.AWS_REGION_NAME}"
  }

}

data "aws_instances" "DIYCDN_POP_ireland_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "Name" = "cdn-pop-ireland"
  }

}
