resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Project_ELB"
    }
}

resource "aws_internet_gateway" "IG_Pub" {
    vpc_id = "${aws_vpc.main.id}"

    tags = {
        Name = "Ig_Pub"
    }
}

resource "aws_route_table" "Internet_Gateway" {
    vpc_id = "${aws_vpc.main.id}"

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IG_Pub.id}"
    }

    tags = {
        Name = "Internet_Gateway"
    }
}

resource "aws_subnet" "Pub_Network1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "eu-west-3a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public1"
    }
}

resource "aws_subnet" "Pub_Network2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-3b"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public2"
    }
}

resource "aws_route_table_association" "Public_route1" {
    subnet_id = "${aws_subnet.Pub_Network1.id}"
    route_table_id = "${aws_route_table.Internet_Gateway.id}"
}

resource "aws_route_table_association" "Public_route2" {
    subnet_id = "${aws_subnet.Pub_Network2.id}"
    route_table_id = "${aws_route_table.Internet_Gateway.id}"
}

resource "aws_security_group" "SG_WEB" {
    name = "SG_Public"
    description = "SG_Public"
    vpc_id = "${aws_vpc.main.id}"

    tags = {
        Name = "SG_Public"
    }
}

resource "aws_security_group_rule" "ingress_rules_Pub" {
    count = length(var.ingress_rules_Pub)

    type              = "ingress"
    from_port         = var.ingress_rules_Pub[count.index].from_port
    to_port           = var.ingress_rules_Pub[count.index].to_port
    protocol          = var.ingress_rules_Pub[count.index].protocol
    cidr_blocks       = [var.ingress_rules_Pub[count.index].cidr_block]
    description       = var.ingress_rules_Pub[count.index].description
    security_group_id = aws_security_group.SG_WEB.id
}

resource "aws_security_group_rule" "egress_rules_Pub" {
    count = length(var.ingress_rules_Pub)

    type              = "egress"
    from_port         = var.egress_rules_Pub[count.index].from_port
    to_port           = var.egress_rules_Pub[count.index].to_port
    protocol          = var.egress_rules_Pub[count.index].protocol
    cidr_blocks       = [var.egress_rules_Pub[count.index].cidr_block]
    description       = var.egress_rules_Pub[count.index].description
    security_group_id = aws_security_group.SG_WEB.id
}

resource "aws_instance" "EC2_WEB" {
    ami = "ami-0f7cd40eac2214b37"
    instance_type = "t2.micro"
    key_name = "AWS"
    vpc_security_group_ids = ["${aws_security_group.SG_WEB.id}"]
    subnet_id   = "${aws_subnet.Pub_Network1.id}"

    connection {
        type     = "ssh"
        user     = "ubuntu"
        host     = "${aws_instance.EC2_WEB.public_ip}"
        private_key = file("./AWS.pem")
  }

    provisioner "remote-exec" {
      inline = [
        "sudo apt update -y",
        "sudo apt install nginx -y",
        "sudo curl http://169.254.169.254/latest/meta-data/hostname | sudo tee /var/www/html/index.nginx-debian.html",
        "sudo service nginx start",
     ]
    }

    tags = {
      Name = "Server_Web1"
    }
}

resource "aws_instance" "EC2_WEB2" {
    ami = "ami-0f7cd40eac2214b37"
    instance_type = "t2.micro"
    key_name = "AWS"
    vpc_security_group_ids = ["${aws_security_group.SG_WEB.id}"]
    subnet_id   = "${aws_subnet.Pub_Network2.id}"

    connection {
        type     = "ssh"
        user     = "ubuntu"
        host     = "${aws_instance.EC2_WEB2.public_ip}"
        private_key = file("./AWS.pem")
  }

    provisioner "remote-exec" {
      inline = [
        "sudo apt update -y",
        "sudo apt install nginx -y",
        "sudo curl http://169.254.169.254/latest/meta-data/hostname | sudo tee /var/www/html/index.nginx-debian.html",
        "sudo service nginx start",
     ]
    }

    tags = {
      Name = "Server_Web2"
    }
}


resource "aws_lb_target_group" "front_end" {
    name = "tg-front-end"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_lb_target_group_attachment" "tg_group_attachment1" {
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
    target_id = "${aws_instance.EC2_WEB.id}"
    port = 80
}

resource "aws_lb_target_group_attachment" "tg_group_attachment2" {
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
    target_id = "${aws_instance.EC2_WEB2.id}"
    port = 80
}

resource "aws_lb" "Loadbalancer" {
    name = "Loadbalancer-Web"
    internal = false
    load_balancer_type = "application"
    security_groups = ["${aws_security_group.SG_WEB.id}"]
 
    subnets = [
        "${aws_subnet.Pub_Network1.id}",
        "${aws_subnet.Pub_Network2.id}",
    ]

    tags = {
        Name = "Loadbalancer_Web"
    }
}

resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.Loadbalancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.front_end.arn}"
    }
}
