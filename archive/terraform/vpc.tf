resource "aws_vpc" "DIYCDN_POP_vpc" {
    cidr_block = "192.168.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags = {
        Name = "DIYCDN_POP_vpc"
    }
}

resource "aws_internet_gateway" "DIYCDN_POP_igw" {
  vpc_id = aws_vpc.DIYCDN_POP_vpc.id
  tags = {
    "Environment" = "DIYCDN_POP_vpc"
  }
}

resource "aws_route_table" "DIYCDN_POP_route_public" {
    vpc_id = aws_vpc.DIYCDN_POP_vpc.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.DIYCDN_POP_igw.id 
    }
    
    tags = {
        Name = "DIYCDN_POP_route_public"
    }
}


resource "aws_route_table_association" "DIYCDN_POP_route_assoc_public" {
    subnet_id = aws_subnet.dublin-public-subnet.id
    route_table_id = aws_route_table.DIYCDN_POP_route_public.id
}


resource "aws_subnet" "dublin-public-subnet" {
    vpc_id = aws_vpc.DIYCDN_POP_vpc.id
    cidr_block = "192.168.0.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-2a"
    tags = {
        Name = "dublin-public-subnet"
    }
}
