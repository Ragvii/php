terraform {
  backend "s3" {
    key    = "ecs/terraform.tfstate"
    region = var.region
  }
}