output "public_ip" {
    value = aws_instance.yewon_bastion_ec2.public_ip
}

output "private_key" {
    value = module.yewon-bastion-key_pair.private_key_pem
}