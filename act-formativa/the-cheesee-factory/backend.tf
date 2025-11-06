terraform {
  backend "s3" {
    bucket         = "my-unique-bucket-name-1-mifz"
    key            = "the-cheesee-factory/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-tcf-lock"
    encrypt        = true
  }
}