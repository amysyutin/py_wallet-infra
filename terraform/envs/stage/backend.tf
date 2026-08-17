terraform {
  backend "s3" {
    bucket         = "pywallet-dev-tfstate"
    key            = "envs/stage/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "pywallet-dev-tf-lock"
    encrypt        = true
    profile        = "pywallet-dev"
  }
}