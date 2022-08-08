#--------------------------------------------VPC---------------------------------------------#

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.64.0"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets = var.public_subnets

}


#-------------- AWS ECS Cluster-----------------------------------------------#

resource "aws_ecs_cluster" "main" {
  
  name =    var.ecs-cluster-name
}

#-------------- AWS ECS Task Execution Role------------------------------------#

resource "aws_iam_role" "ecs_task_execution_role" {
  name                 = "${var.name_prefix}-ecs-task-execution-role"
  assume_role_policy   = file("${path.module}/ecs-task-execution-role.json")
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



#---- Container Definition---------------------------------------------------------------#

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"

  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  port_mappings                = var.port_mappings
  container_cpu                = var.container_cpu
  log_configuration            = var.log_configuration
  ulimits                      = var.ulimits
  
}

#------------------------ Task Definition----------------------------------------------#

resource "aws_ecs_task_definition" "td" {
  family                  = "${var.name_prefix}-td"
  container_definitions   = "[${module.container_definition.json_map_encoded}]"
  task_role_arn           = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  network_mode            = var.network_mode
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = var.requires_compatibilities
  
}



resource "aws_security_group" "LB-SG" {
  name   = "${var.ecs-cluster-name}-LB"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "app_lb_allow_outbound" {
  security_group_id = aws_security_group.LB-SG.id

  type        = "egress"
  from_port   = var.sg_ext_from_port
  to_port     = var.sg_ext_to_port
  protocol    = var.sg_ext_protocol
  cidr_blocks = var.sg_ext_cidr
}

resource "aws_security_group_rule" "app_lb_allow_all_http" {
  
  security_group_id = aws_security_group.LB-SG.id

   type        = "ingress"
  from_port   = var.sg_int_from_port
  to_port     = var.sg_int_to_port
  protocol    = var.sg_int_protocol
  cidr_blocks = var.sg_int_cidr
}

#-------------- AWS Application Load Balancer----------------------------#

resource "aws_lb" "main" {
  name               = "lb-${var.ecs-cluster-name}"
  internal           = var.lb_internal
  load_balancer_type = var.associate_alb == true && var.associate_nlb == false ? "application" : "network"
  security_groups    = var.associate_alb == true && var.associate_nlb == false ? [aws_security_group.LB-SG.id] : null
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "http" {
  count = length(var.lb_ports)

  load_balancer_arn = aws_lb.main.id
  port              = element(var.lb_ports, count.index)
  protocol          = var.associate_alb == true && var.associate_nlb == false ? "HTTP" : "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.http[count.index].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "http" {
  count = length(var.lb_ports)

  name     = "${var.ecs-cluster-name}-${var.lb_ports[count.index]}"
  port     = element(var.lb_ports, count.index)
  protocol = var.associate_alb == true && var.associate_nlb == false ? "HTTP" : "TCP"

  vpc_id      = module.vpc.vpc_id
  target_type = var.lb_target_type

  deregistration_delay = var.lb_deregistration_delay

  health_check {
    timeout             = var.associate_alb == true && var.associate_nlb == false ? 5 : null
    interval            = var.hc_interval
    path                = var.associate_alb == true && var.associate_nlb == false ? "/" : null
    protocol            = var.associate_alb == true && var.associate_nlb == false ? "HTTP" : "TCP"
    healthy_threshold   = var.hc_healthy_threshold
    unhealthy_threshold = var.hc_unhealthy_threshold
    matcher             = var.associate_alb == true && var.associate_nlb == false ? "200" : null
  }

  depends_on = [aws_lb.main]
}

#------------------------------ AWS KMS--------------------------------------------# 

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "main" {
  description         = "Key for ECS log encryption"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}


#-------------- -------------------AWS ECS Fargate---------------------------------------------#

module "ecs-service" {
  source = "trussworks/ecs-service/aws"

  name        = "fg-${var.ecs-cluster-name}"
  environment = "test"

  associate_alb = var.associate_alb
  associate_nlb = var.associate_nlb

  alb_security_group     = var.associate_alb == true && var.associate_nlb == false ? aws_security_group.LB-SG.id : null
  nlb_subnet_cidr_blocks = var.associate_alb == false && var.associate_nlb == true ? module.vpc.public_subnets_cidr_blocks : null

  hello_world_container_ports = var.lb_ports

  lb_target_groups = [
    {
      lb_target_group_arn         = aws_lb_target_group.http[0].arn
      container_port              = element(var.lb_ports, 0)
      container_health_check_port = element(var.lb_ports, 0)
    },
    {
      lb_target_group_arn         = aws_lb_target_group.http[1].arn
      container_port              = element(var.lb_ports, 0)
      container_health_check_port = element(var.lb_ports, 1)
    }
  ]

  ecs_cluster      = aws_ecs_cluster.main
  ecs_subnet_ids   = module.vpc.public_subnets
  ecs_vpc_id       = module.vpc.vpc_id
  ecs_use_fargate  = true
  assign_public_ip = true
  kms_key_id       = aws_kms_key.main.arn
}



