terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

module "krakend_service" {
  source = "../../modules/cloud-run-service-module"

  project_id           = var.krakend_config.project_id
  region               = var.krakend_config.region
  service_name         = var.krakend_config.service_name
  container_image      = var.krakend_config.krakend_image
  container_port       = var.krakend_config.container_port
  
  # Pass IAM roles for the service account from tfvars
  service_account_roles = var.krakend_config.service_account_roles
  
  min_instances        = var.krakend_config.min_instances
  max_instances        = var.krakend_config.max_instances
  container_concurrency = var.krakend_config.container_concurrency
  memory_limit         = var.krakend_config.memory_limit
  cpu_limit            = var.krakend_config.cpu_limit
  vpc_connector        = var.krakend_config.vpc_connector
  
  env_variables        = var.krakend_config.env_variables
  secret_env_vars      = var.krakend_config.secret_env_vars
  secret_file_mounts   = var.krakend_config.secret_file_mounts
  
  # Agregar la configuración para el montaje de Google Cloud Storage
  gcs_bucket_mounts    = var.krakend_config.gcs_bucket_mounts

  allow_public_access  = true # KrakenD API Gateway is typically publicly accessible
}