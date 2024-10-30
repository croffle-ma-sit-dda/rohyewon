output "vpc_id" {
    value = module.vpc.vpc_id
}

output "private_first" {
  description = "First set of private subnet CIDRs"
  value       = slice(module.vpc.private_subnets, 0, length(var.private_first))  # 첫 번째 CIDR 대역 추출
}

output "private_secondary" {
  description = "Second set of private subnet CIDRs"
  value       = slice(module.vpc.private_subnets, length(var.private_first), length(var.private_first) + length(var.private_secondary))  # 두 번째 CIDR 대역 추출
}


#output "private_secondary" {
#    value = module.vpc.private_secondary
#}