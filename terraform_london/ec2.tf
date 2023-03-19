variable "ec2_setup" {
    type = map(string)

    default = {
    publicip = true
  }

}
provider "aws" {
  region = var.AWS_REGION
}

# data "aws_subnets" "london_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [var.vpc_id]
#   }
# }

# data "aws_subnet" "london_subnet" {
#   for_each = toset(data.aws_subnets.london_subnets.ids)
#   id       = each.value
# }

resource "aws_instance" "cdn-pop-london-a" {
  subnet_id      = var.POP_SUBNET_A_LONDON
  ami = lookup(var.AMI, var.AWS_REGION)
  instance_type = var.INSTANCE_TYPE
  availability_zone = var.AVAILABILITY_ZONE_A

  associate_public_ip_address = lookup(var.ec2_setup, "publicip")
  key_name = "nginx_openresty_london"

  vpc_security_group_ids = [var.DIYCDN_POP_SG]

  root_block_device {
    delete_on_termination = true
    #iops = 150
    volume_size = 20
    volume_type = "gp2"
  }

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

    # provisioner "file" {
    #     source = "templates/php-fpm-5.service"
    #     destination = "/tmp/php-fpm-5.service"
    # }

    # provisioner "file" {
    #     source = "php/php-fpm-5.conf"
    #     destination = "/tmp/php-fpm.conf"
    # }

    # provisioner "file" {
    #     source = "varnish"
    #     destination = "/tmp/varnish"
    # }

    # provisioner "file" {
    #     source = "templates/varnish.service"
    #     destination = "/tmp/varnish.service"
    # }

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
    PoP = "${var.DIYCDN_POP_NAME}-${var.AWS_REGION_NAME}-${var.POP_ENV}"
    Name ="${var.DIYCDN_POP_NAME}-${var.AWS_REGION_NAME}-${var.POP_ENV}-a"
    Environment = var.POP_ENV
    OS = "AMAZON LINUX 2"
    Tool = "Terraform"
  }
}
output "ec2_a_public_ip" {
  value = aws_instance.cdn-pop-london-a.public_ip
}

output "ec2_a_public_dns" {
  value = aws_instance.cdn-pop-london-a.public_dns
}


# # second instance in a pop

resource "aws_instance" "cdn-pop-london-b" {
  subnet_id      = var.POP_SUBNET_B_LONDON
  ami = lookup(var.AMI, var.AWS_REGION)
  instance_type = var.INSTANCE_TYPE
  availability_zone = var.AVAILABILITY_ZONE_B
  associate_public_ip_address = lookup(var.ec2_setup, "publicip")
  key_name = "nginx_openresty_london"

  vpc_security_group_ids = [var.DIYCDN_POP_SG]

  root_block_device {
    delete_on_termination = true
    #iops = 150
    volume_size = 20
    volume_type = "gp2"
  }

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

    # provisioner "file" {
    #     source = "templates/php-fpm-5.service"
    #     destination = "/tmp/php-fpm-5.service"
    # }

    # provisioner "file" {
    #     source = "php/php-fpm-5.conf"
    #     destination = "/tmp/php-fpm.conf"
    # }

    # provisioner "file" {
    #     source = "varnish"
    #     destination = "/tmp/varnish"
    # }

    # provisioner "file" {
    #     source = "templates/varnish.service"
    #     destination = "/tmp/varnish.service"
    # }

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
    POP = "${var.DIYCDN_POP_NAME}-${var.AWS_REGION_NAME}-${var.POP_ENV}"
    Name ="${var.DIYCDN_POP_NAME}-${var.AWS_REGION_NAME}-${var.POP_ENV}-b"
    Environment = var.POP_ENV
    OS = "AMAZON LINUX 2"
    Tool = "Terraform"
  }
}

output "ec2_b_public_ip" {
  value = aws_instance.cdn-pop-london-b.public_ip
}

output "ec2_b_public_dns" {
  value = aws_instance.cdn-pop-london-b.public_dns
}



# output "subnet_cidr_blocks" {
#   value = [for s in data.aws_subnet.london_subnet : s.cidr_block]
# }

data "aws_key_pair" "nginx_openresty_london" {
  key_name = "nginx_openresty_london"
  include_public_key = true
  #public_key = file(var.PUBLIC_KEY_PATH)
}


# data "aws_key_pair" "pop_key_pair_preset" {
#   key_name           = "nginx_openresty_london"
#   include_public_key = true

#   #filter {
#     # name   = "tag:Component"
#     # values = ["web"]
#   #}
# }

# output "fingerprint" {
#   value = data.aws_key_pair.nginx_openresty_london.fingerprint
# }

# output "name" {
#   value = data.aws_key_pair.nginx_openresty_london.key_name
# }

# output "id" {
#   value = data.aws_key_pair.nginx_openresty_london.id
# }

