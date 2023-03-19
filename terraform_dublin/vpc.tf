# resource "aws_vpc" "DIYCDN_POP_vpc" {
#     id = var.vpc_id
# }

# data "aws_vpc" "DIYCDN_POP_vpc" {
#     id = var.vpc_id name DiyCDN.cloud.dublin.vpc
# }

# resource "aws_subnet" "dublin-public-subnet" {
#   vpc_id            = data.aws_vpc.DIYCDN_POP_vpc.id
#   availability_zone = "eu-west-2a"
#   cidr_block        = cidrsubnet(data.aws_vpc.DIYCDN_POP_vpc.cidr_block, 4, 1)
# }
