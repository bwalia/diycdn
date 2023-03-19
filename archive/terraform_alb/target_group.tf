# ## cat target_group.tf
# # It will create the target group for each mentioned ALB
# resource "aws_lb_target_group" "sample_tg" {
#    for_each           = var.alb_names
#    name               = each.value
#    target_type        = "instance"
#    port               = 80
#    protocol           = "HTTP"
#    vpc_id             = "vpc-058c69271be4f1631"
#    health_check {
#       healthy_threshold   = var.health_check["healthy_threshold"]
#       interval            = var.health_check["interval"]
#       unhealthy_threshold = var.health_check["unhealthy_threshold"]
#       timeout             = var.health_check["timeout"]
#       path                = var.health_check["path"]
#       port                = var.health_check["port"]
#   }
# }
