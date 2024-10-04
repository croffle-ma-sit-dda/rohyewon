
resource "aws_security_group" "yewon_bastion_sg" {
    name = "${var.project}-bastion-sg"
    description = "${var.project}-bastion-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 22
        to_port = 22
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

module "yewon-bastion-key_pair" {
    source = "terraform-aws-modules/key-pair/aws"
    version = "2.0.2"
    key_name = "${var.project}-key-pair"
    create_private_key = true
}

resource "aws_instance" "yewon_bastion_ec2" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"

    subnet_id = var.subnet_id
    associate_public_ip_address = true

    key_name = module.yewon-bastion-key_pair.key_pair_name
    vpc_security_group_ids = [aws_security_group.yewon_bastion_sg.id]

    root_block_device {
        volume_type = "gp2"
        volume_size = 8
    }
}

data "aws_ami" "amazon_linux" {
    most_recent = true  # 가장 최근 이미지
    owners = ["137112412989"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}
