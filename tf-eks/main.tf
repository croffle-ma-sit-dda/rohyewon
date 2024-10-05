terraform {
    required_version = ">= 1.1.4"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 4.0.0"
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "~> 2.10.0"
        }
    }
}

provider "aws" {}
module "vpc" {
    source = "./modules/vpc"
    name = "dev-vpc"
    cidr = "10.0.0.0/16"

}

module "yewon_eks" {
    source = "./modules/eks"
    cluster_name = "dev-cluster"
    cluster_version = 1.2
    vpc_id = module.yewon_vpc.vpc_id
    private_subnets = module.yewon_vpc.private_subnets
}



/*
module "module_instance" {
    source = "../module_ec2"
    project = "yewon"
    vpc_id = module.vpc.vpc_id
    subnet_id = module.vpc.public_subnets[0]
}

output "instance" {
    value = module.module_instance
    sensitive = true
}
*/