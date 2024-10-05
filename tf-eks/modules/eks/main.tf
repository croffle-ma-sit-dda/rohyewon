provider "kubernetes" {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)


    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command = "aws"
        args = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
    }
}


data "aws_ami" "yewon_eks_ami" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amazon-eks-node-${var.cluster_version}-v*"]
    }
}

module "eks_cluster" {
    source = "terraform-aws-modules/eks/aws"
    version = "19.21.0"

    cluster_name = var.cluster_name
    cluster_version = var.cluster_version
    
    cluster_endpoint_public_access =true
    cluster_endpoint_private_access =true

    cluster_encryption_config = {}       # etcd 에 저장되는 쿠버네티스의 secret 에 대해 encryption 적용 X

    cluster_addons = {
        coredns = {
            most_recent = true
        }

        kube-proxy = {
            most_recent = true
        }

        vpc-cni = {
            most_recent = true
        }
    }

    vpc_id = var.vpc_id
    subnet_ids = var.private_subnets
    manage_aws_auth_configmap = true

    eks_managed_node_groups = {
        yewon-ng = {
            name = "yewon-ng"
            use_name_prefix = true      # 노드그룹 뒤에 랜덤한 값을 세팅하기 위해, 중복이름 생성을 막기 위함

            subnet_ids = var.private_subnets

            min_size = 1
            max_size = 2
            desired_size = 1

            ami_id = data.aws_ami.yewon_eks_ami.id
            enable_bootstrap_user_data = true # 노드가 생성이 되었을 때 controlplane 과 통신이 되기 위해, bootstrap 에 userdata 가 필요함 

            capacity_type = "ON_DEMAND"
            instance_type = ["t3.medium"]

            create_iam_role = true
            iam_role_name = "yewon-ng-role"
            iam_role_use_name_prefix = true
            iam_role_additional_policies = {
                AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
            }
        }
    }
}