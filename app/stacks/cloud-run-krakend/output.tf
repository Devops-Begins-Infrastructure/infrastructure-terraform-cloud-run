output "krakend_service_url" {
  description = "The URL of the deployed KrakenD API Gateway service"
  value       = module.krakend_service.service_url
}

output "krakend_service_name" {
  description = "Name of the deployed KrakenD service"
  value       = module.krakend_service.service_name
}

output "krakend_latest_revision" {
  description = "Latest deployed revision of the KrakenD service"
  value       = module.krakend_service.latest_revision_name
}

output "krakend_region" {
  description = "Region where the KrakenD service is deployed"
  value       = var.krakend_config.region
}

output "krakend_service_account_email" {
  description = "Email of the dedicated service account for KrakenD service"
  value       = module.krakend_service.service_account_email
}

output "krakend_service_account_name" {
  description = "Name of the dedicated service account for KrakenD service"
  value       = module.krakend_service.service_account_name
}