terraform {
   backend "s3" {
     bucket = "s3-udacity-terraform-us-west-1"
     key    = "terraform/terraform.tfstate"
     region = "us-west-1"
   }
 }

 provider "aws" {
   region = "us-west-1"
   
   default_tags {
     tags = local.tags
   }
 }

provider "aws" {
  alias  = "usw1"
  region = "us-west-1"
}
