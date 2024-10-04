terraform {
    required_version = ">= 1.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.46.0"
        }
    }
}

provider "aws" {}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    name = "yewon-vpc"
    cidr = "10.0.0.0/16"

    azs = ["ap-northeast-1a", "ap-northeast-1c"]
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
}

resource "aws_security_group" "yewon_alb_sg" {
    name = "yewon-alb-sg"
    description = "yewon-alb-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "yewon_ec2_sg" {
    name = "yewon-ec2-sg"
    description = "yewon-ec2-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.yewon_alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "yewon_ec2" {
    for_each = toset (["1", "2"])   #

    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    subnet_id = module.vpc.private_subnets[tonumber(each.key) % 2]  #
    vpc_security_group_ids = [aws_security_group.yewon_ec2_sg.id]
    # heatlh check 및 nginx 페이지 오류, bastion 만들어서 서버 접속 필요
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo amazon-linux-extras install nginx1 -y 
                sudo systemctl enable nginx
                sudo systemctl start nginx
                EOF
}

data "aws_ami" "amazon_linux" {
    most_recent = true # 가장 최근 리소스
    owners = ["137112412989"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_lb_target_group" "yewon_alb_tg" {
    name = "yewon-alb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "yewon_alb_tg_attachment" {
    for_each = aws_instance.yewon_ec2   #
    target_group_arn = aws_lb_target_group.yewon_alb_tg.arn
    target_id = each.value.id   #
    port = 80
    depends_on = [aws_instance.yewon_ec2, aws_lb_target_group.yewon_alb_tg]
}

resource "aws_lb" "yewon_alb" {
    name = "yewon-alb"
    internal = false

    load_balancer_type = "application"
    subnets = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
    security_groups = [aws_security_group.yewon_alb_sg.id]
}

resource "aws_lb_listener" "yewon_alb_listener" {
    load_balancer_arn = aws_lb.yewon_alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            status_code = 403
        }
    }
}

resource "aws_lb_listener_rule" "yewon_alb_listener_rule" {
    listener_arn = aws_lb_listener.yewon_alb_listener.arn
    priority = 1

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.yewon_alb_tg.arn
    }
    condition {
        path_pattern {
            values = ["*"]
        }
    }
}


## 백엔드용 S3 bucket
resource "aws_s3_bucket" "yewon_tfstate_bucket" {
    bucket_prefix = "yewon-terraform-state"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "yewon_tfstate_versioning" {
    bucket = aws_s3_bucket.yewon_tfstate_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

## State locking 을 위한 DynamoDB
resource "aws_dynamodb_table" "yewon_table" {
    name = "yewon-terraform-lock"
    hash_key = "LockID"
    billing_mode = "PAY_PER_REQUEST"
    attribute {
        name = "LockID"
        type = "S"
    }
}
