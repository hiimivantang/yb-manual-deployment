module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(["one","two","three"])

  name = "instance-${each.key}"

  ami                    = "ami-0fd1ee6c8b656f020"
  instance_type          = "t2.micro"
  key_name               = "ec2"
  monitoring             = true
  vpc_security_group_ids = ["sg-023af329d09109929"]
  subnet_id              = "subnet-08e3c224fe4b4cd38"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
