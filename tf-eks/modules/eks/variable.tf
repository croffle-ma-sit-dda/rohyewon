variable "cluster_name" {
    type = string
}

variable "cluster_version" {
    type = string
}

variable "vpc_id" {
    type = string   
}

variable "private_first" {
    type = list(string)
}