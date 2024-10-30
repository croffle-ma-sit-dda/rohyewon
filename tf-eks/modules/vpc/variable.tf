variable "vpc_name" {
    type = string
}

variable "vpc_cidr" {
    type = string
}

variable "private_first" {
  description = "CIDR block for the first private subnet"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_secondary" {
  description = "CIDR block for the second private subnet"
  type        = list(string)
  default     = ["198.18.48.0/21", "198.18.56.0/21"]
}