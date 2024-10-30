terraform {
    required_version = ">= 1.4"
    # required_version = ">= 1.1.4"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 4.57"
           # version = ">= 4.0.0"
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = ">= 2.10"
           # version = "~> 2.10.0"
        }
    }
}

provider "aws" {
    default_tags {
        tags = {
            Service = "yewon-terraform-Test"
            Team = "tech/sre"
            Env = "dev"
            Terraformd = "true"
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
# backend 부분이랑 depends_on 필요 (s3 버킷이 생성된 후, 그 정보를 backend 에 지정)


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



## 모듈
module "vpc" {
    source = "./modules/vpc"
    vpc_name = "yewon-vpc"
    vpc_cidr = "10.0.0.0/16"

}

module "yewon_eks" {
    source = "./modules/eks"
    cluster_name = "yewon-eks-cluster"
    cluster_version = 1.29
    vpc_id = module.vpc.vpc_id
    private_first = module.vpc.private_first
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

#### IRSA Role
module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller-yewon-dev"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.yewon_eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  # tags = local.tags
}

module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z04217742QA6YH6URH23G"]

  oidc_providers = {
    ex = {
      provider_arn               = module.yewon_eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  # tags = local.tags
}

# EntityAlreadyExists: Role with name external-dns already exists.