resource "aws_security_group" "DIYCDN_POP_sg" {
    vpc_id = aws_vpc.DIYCDN_POP_vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the NGINX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        //If you do not add this rule, you can not reach the Config API to push tenant configs  
    ingress {
        from_port = 8888
        to_port = 8888
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        //If you do not add this rule, you can not reach the Config API to push tenant configs  
    ingress {
        from_port = 8333
        to_port = 8333
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        //If you do not add this rule, you can not reach the Config API to push tenant configs  
    ingress {
        from_port = 3333
        to_port = 3333
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port = 10443
        to_port = 10443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        HTTP = "Allowed",
        SSH = "Allowed"
        API = "Allowed"
    }

    
}

// Define EC2 instance to be built
resource "aws_instance" "DIYCDN_POP_dublin" {

    ami = lookup(var.AMI, var.AWS_REGION)
    instance_type = "t3a.micro"
    count = var.INSTANCE_COUNT_PER_AZ
    # VPC
    subnet_id = aws_subnet.dublin-public-subnet.id
    # Security Group
    vpc_security_group_ids = [aws_security_group.DIYCDN_POP_sg.id]
    # the Public SSH key
    key_name = aws_key_pair.cdn-pop-pub-key-pair.id

    # upload sources to target machine
    provisioner "file" {
        source = "src"
        destination = "/tmp/src"
    }

     # upload bash scripts to target machine
    provisioner "file" {
        source = "scripts"
        destination = "/tmp/scripts"
    }

    provisioner "file" {
        source = "templates/redis.service"
        destination = "/tmp/redis.service"
    }
    
    provisioner "file" {
        source = "templates/services-manager.service"
        destination = "/tmp/services-manager.service"
    }

    provisioner "file" {
        source = "templates/openresty.service"
        destination = "/tmp/openresty.service"
    }

    provisioner "file" {
        source = "nginx/nginx.conf"
        destination = "/tmp/nginx.conf"
    }

    provisioner "file" {
        source = "redis/redis.conf"
        destination = "/tmp/redis.conf"
    }


    provisioner "file" {
        source = "nginx"
        destination = "/tmp/nginx"
    }

    provisioner "file" {
        source = "templates/php-fpm-5.service"
        destination = "/tmp/php-fpm-5.service"
    }

    provisioner "file" {
        source = "php/php-fpm-5.conf"
        destination = "/tmp/php-fpm.conf"
    }

    provisioner "file" {
        source = "varnish"
        destination = "/tmp/varnish"
    }

    provisioner "file" {
        source = "templates/varnish.service"
        destination = "/tmp/varnish.service"
    }

    # Install update yum packages by executing bash script
    # services manager go app installation by executing bash script
    # Nginx/Openresty installation by executing bash script
    provisioner "remote-exec" {
        inline = [
             "chmod +x /tmp/scripts/kickstart.sh",
             "sudo /bin/bash /tmp/scripts/kickstart.sh"
        ]
    }    

    connection {
        host = self.public_ip
        user = var.EC2_USER
        private_key = file(var.PRIVATE_KEY_PATH)
    }

    tags = {
        Name = join("-",[var.DIYCDN_POP_NAME, var.AWS_REGION_NAME])
        Region = var.AWS_REGION_NAME
        Env = var.POP_ENV
    }

    provisioner "local-exec" {
        command = "echo ${self.public_dns}"
    }

    provisioner "local-exec" {
        command = "echo ${self.public_ip}"
    }
    
    provisioner "local-exec" {
        command = "echo ${self.private_ip}"
        # command = "echo ${self.public_ip} >> public_ips.txt"
        # command = "echo ${self.private_ip} >> private_ips.txt"
    }

    provisioner "local-exec" {
        command = "echo ${self.public_ip} >> public_ips.txt"
    }


}

# Sends your public key to the instance
resource "aws_key_pair" "cdn-pop-pub-key-pair" {
    key_name = "cdn-pop-pub-key-pair"
    public_key = file(var.PUBLIC_KEY_PATH)
}
