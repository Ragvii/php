module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  create_database_subnet_group       = var.create_database_subnet_group
  create_database_subnet_route_table = var.create_database_subnet_route_table

  
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.sgname
  
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = var.int_from_port
      to_port     = var.int_to_port
      protocol    = var.int_protocol
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.identifier_name
  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.db_family
  major_engine_version = var.major_engine_version
  instance_class       = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  
  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  multi_az               = var.multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

}

