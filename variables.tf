# -----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# -----------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# -----------------------------------------------------------------------------
# PARAMETERS
# -----------------------------------------------------------------------------

variable "region" {
  description = "Region to deploy"
}

variable "domain" {
  description = "Domain name. Service will be deployed using the appsilon_subdomain"
}

variable "appsilon_subdomain" {
  description = "The Subdomain for your appsilon graphql service."
  default     = "appsilon"
}

variable "appsilon_version_tag" {
  description = "The Docker image tag version."
}

variable "rds_username" {
  description = "The username for RDS"
}

variable "rds_password" {
  description = "The password for RDS"
}

variable "rds_db_name" {
  description = "The DB name in the RDS instance"
}

variable "rds_instance" {
  description = "The size of RDS instance, eg db.t2.micro"
}

variable "environment" {
  description = "Environment variables for ECS task: [ { name = \"foo\", value = \"bar\" }, ..]"
  default     = []
}

variable "ecs_cluster_name" {
  description = "The name to assign to the ECS cluster"
  default     = "appsilon-cluster"
}

variable "az_count" {
  description = "How many AZ's to create in the VPC"
  default     = 2
}
