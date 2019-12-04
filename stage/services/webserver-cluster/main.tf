#Provider is who is provider you are using e.g aws

provider "aws" {
    region = "us-east-2"
}

/* 

Syntax for creating a resource in Terraform is: 

resource "<PROVIDER>_<TYPE>" "<NAME>" {
    [CONFIG ...]
} 

PROVIDER = name of provider (e.g aws)
TYPE = type of resource created in provider (e.g my_instance)
CONFIG = consists of one or more arguments specific to the resource 

*/

resource "aws_instance" "example" {
    ami           = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello again, Shisho" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
        Name = "terraform-example"
    }

}

resource "aws_launch_configuration" "example" { 
    image_id = "ami-0c55b159cbfafe1f0" 
    instance_type = "t2.micro" 
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello once more, Shisho" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

# Required when using a launch configuration with an autoscaling group.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
    
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn 
    port = 8080
    protocol = "HTTP"

    #By default, returns a 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids


  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"


  min_size = 2
  max_size = 10

  tag {
      key = "Name"
      value = "terraform-asg-example"
      propagate_at_launch = true
  }
}


resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        field = "path-pattern"
        values = ["*"]
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    # Allow inbound HTTP requests
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    # Allow all outbound requests
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}


resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 

data "aws_vpc" "default" {
    default = true
}

#Looks up subnet IDs of a VPC somewhere
data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}




#Use and refer to Terraform documentation frequently