# ## cat target_group_attachment.tf
# # Attach the target group for "test" ALB
# resource "aws_lb_target_group_attachment" "tg_attachment_test" {
#     target_group_arn = aws_lb_target_group.sample_tg["test"].arn
#     target_id        = "i-06686b5dcaea9fcc6"
#     port             = 80
# }
# # Attach the target group for "test1" ALB
# resource "aws_lb_target_group_attachment" "tg_attachment_test1" {
#     target_group_arn = aws_lb_target_group.sample_tg["test1"].arn
#     target_id        = "i-0f45928e015ecbab4" 
#     port             = 80
# }



terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.40"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}