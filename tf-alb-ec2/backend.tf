terraform {
    backend "s3" {
        bucket = "yewon-terraform-state20240929023938622500000001"
        key = "yewon-terraform-state"
        region = "ap-northeast-1"
        dynamodb_table = "yewon-terraform-lock"
    }
}