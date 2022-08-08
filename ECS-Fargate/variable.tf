#------------ AWS ECS Cluster ------------#

variable "ecs-cluster-name" {
  type        = string
}

variable "region" {
  type = string
}

#------------ AWS ECS Task Execution Role ------------#

variable "name_prefix" {
  type = string
}

#------------ AWS ECS Task Definition ------------#

#----Container Definition

variable "container_name" {
  type        = string
}

variable "container_image" {
  type        = string
}

variable "container_memory" {
  type        = number
}

variable "container_memory_reservation" {
  type        = number
}

variable "port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
}

variable "container_cpu" {
  type        = number
}

variable "log_configuration" {
  type        = any
}

#----Task Definition

variable "network_mode" {
  type  = string
}

variable "requires_compatibilities" {
  type  = list(any)
}

variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
}


#-------------- AWS VPC

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}
variable "public_subnets" {
  type = list(string)
}
variable "sg_ext_protocol" {
  type = string
}

variable "sg_ext_cidr" {
  type = list(string)
}

variable "sg_ext_from_port" {
  type = number
}

variable "sg_ext_to_port" {
  type = number
}

variable "sg_int_protocol" {
  type = string
}

variable "sg_int_cidr" {
  type = list(string)
}

variable "sg_int_from_port" {
  type = number
}

variable "sg_int_to_port" {
  type = number
}

#ALB

variable "associate_alb" {
  type = bool
}

variable "associate_nlb" {
  type = bool
}

variable "lb_ports" {
  type = list
}

variable "lb_internal" {
  type = bool
}

variable "lb_target_type" {
  type = string
}

variable "lb_deregistration_delay" {
  type = number
}

variable "hc_interval" {
  type = number
}

variable "hc_healthy_threshold" {
  type = number
}

variable "hc_unhealthy_threshold" {
  type = number
}




