variable "ingress_rules_Pub" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default = [
       {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "SSH"
        },
        {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "HTTP"
        }
    ]
}

variable "egress_rules_Pub" {
    type = list(object({
      from_port = number
      to_port = number
      protocol = string
      cidr_block = string
      description = string
    }))
    default = [
        {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "HTTP"
        },
        {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_block  = "0.0.0.0/0"
        description = "ICMP"
        }
    ]
}
