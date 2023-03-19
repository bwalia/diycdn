# ## cat variables.tf
# # Declare the ALB names required for creation
# # Here, we are creating two ALBs "test" and "test1"
# variable "alb_names" {
#    type = map
#    default = { for alb_names in ["test", "test1" ] : alb_names =>     alb_names }
# }
# # Map used for providing details for health-check
# # You can use the values based on your requirements
# variable "health_check" {
#    type = map(string)
#    default = {
#       "timeout"  = "10"
#       "interval" = "20"
#       "path"     = "/"
#       "port"     = "80"
#       "unhealthy_threshold" = "2"
#       "healthy_threshold" = "3"
#     }
# }
# # Mention the security names to be used
# # Make sure the SG provided is having access to HTTP and HTTPs
# variable "security_grp" {
#     type = list
#     default = ["sg-053d8XXXXX01a"]
# }
# # Mention the subnets
# variable "subnets" {
#     type = list
#     default = ["subnet-054153c6019a1f600"]
# }
# ##