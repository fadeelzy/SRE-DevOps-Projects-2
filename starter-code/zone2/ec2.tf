#  module "project_ec2" {
#    source             = "./modules/ec2"
#    name               = local.name
#    account            = data.aws_caller_identity.current.account_id
#    aws_ami            = data.aws_ami.amazon_linux_2.id
#    private_subnet_ids = module.vpc.private_subnet_ids
#    vpc_id             = module.vpc.vpc_id
#  }

  module "project_ec2" {
   source             = "./modules/ec2"
   instance_count     = var.instance_count
   name               = local.name
   account            = data.aws_caller_identity.current.account_id
   aws_ami            = "ami-00672170e324c2fdc"
   private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
   public_subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnet_ids
   vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
 }

#  ami-name = s3-udacity-ami
#  ami-id = ami-00fe1f89c2f77f144 (us-east-1)
#  ami-id = ami-010022d43ad0f0452 (us-east-2)
#  ami-id = ami-00672170e324c2fdc (us-west-1)