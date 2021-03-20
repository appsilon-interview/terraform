module "terraform-aws-appsilon" {
  source               = "./modules/terraform-aws-appsilon"
  region               = var.region
  domain               = var.domain
  appsilon_subdomain   = var.appsilon_subdomain
  appsilon_version_tag = var.appsilon_version_tag
  rds_username         = var.rds_username
  rds_password         = var.rds_password
  rds_db_name          = var.rds_db_name
  rds_instance         = var.rds_instance
}
