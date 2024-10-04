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

module "module_instance" {
    source = "../modules"
    project = "yewon"
    vpc_id = module.vpc.vpc_id
    subnet_id = module.vpc.public_subnets[0]
}


output "instance" {
    value = module.module_instance
    sensitive = true
}