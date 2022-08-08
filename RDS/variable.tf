variable "region" {
 type = string 
}

#-------------- AWS VPC

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list
}

variable "private_subnets" {
  type = list
}

variable "database_subnets" {
  type = list
}
#-------------- RDS Cluster

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_family" {
  type = string
}

variable "major_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "availability_zones" {
  type = list
}

variable "sgname" {
  type = string
}


variable "create_database_subnet_group" {
  type = bool
}

variable "create_database_subnet_route_table" {
 type = bool 
}


variable "int_from_port" {
  type = number
}

variable "int_to_port" {
  type = number
}

variable "int_protocol" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_port" {
  type = number
}

variable "multi_az" {
  type = bool
}

variable "identifier_name" {
  type = string
}




