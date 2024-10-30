module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.4.0"

    name = var.vpc_name
    cidr = "10.0.0.0/16"
    secondary_cidr_blocks = ["198.18.48.0/20"]

    azs = ["ap-northeast-1a", "ap-northeast-1c"]
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

    # Use the concatenation of two separate variables
    private_subnets = concat(
        var.private_first, # First CIDR
        var.private_secondary  # Second CIDR
    )


    enable_nat_gateway = true
    single_nat_gateway = true

    public_subnet_tags = {
        "kubernetes.io/role/elb" = 1
    }
    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
    }
}
