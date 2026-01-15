locals {
   account_id = data.aws_caller_identity.current.account_id

   name   = "udacity"
   region = "us-west-1"
   tags = {
     Name      = local.name
     Terraform = "true"
   }
 }

#  module "vpc" {
#    source     = "./modules/vpc"
#    cidr_block = "10.100.0.0/16"
#
#    account_owner = local.name
#    name          = "${local.name}-project"
#    azs           = ["us-east-2a", "us-east-2b", "us-east-2c"]
#    # show available zones for a particular aws region
#    # aws ec2 describe-availability-zones --region us-east-2
#
#    private_subnet_tags = {
#      "kubernetes.io/role/internal-elb" = 1
#    }
#    public_subnet_tags = {
#      "kubernetes.io/role/elb" = 1
#    }
#  }
#
#   module "vpc_west" {
#    source     = "./modules/vpc"
#    cidr_block = "10.100.0.0/16"
#
#    account_owner = local.name
#    name          = "${local.name}-project"
#    azs           = ["us-west-1a", "us-west-1b"]
#     # show available zones for a particular aws region
#     # aws ec2 describe-availability-zones --region us-west-1
#
#    private_subnet_tags = {
#      "kubernetes.io/role/internal-elb" = 1
#    }
#    public_subnet_tags = {
#      "kubernetes.io/role/elb" = 1
#    }
#   providers = {
#     aws = aws.usw1
#   }
#  }