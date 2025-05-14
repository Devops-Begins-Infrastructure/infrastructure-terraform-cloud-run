output "service_url" {
  value       = google_cloud_run_service.service.status[0].url
  description = "The URL of the deployed Cloud Run service"
}

output "service_name" {
  value       = google_cloud_run_service.service.name
  description = "The name of the deployed Cloud Run service"
}

output "latest_revision_name" {
  value       = google_cloud_run_service.service.status[0].latest_created_revision_name
  description = "The name of the latest revision of the Cloud Run service"
}

output "service_id" {
  value       = google_cloud_run_service.service.id
  description = "The ID of the Cloud Run service"
}

output "location" {
  value       = google_cloud_run_service.service.location
  description = "The location where the Cloud Run service is deployed"
}

output "service_account_email" {
  value       = google_service_account.service_account.email
  description = "The email address of the dedicated service account for the Cloud Run service"
}

output "service_account_id" {
  value       = google_service_account.service_account.id
  description = "The ID of the dedicated service account for the Cloud Run service"
}

output "service_account_name" {
  value       = google_service_account.service_account.name
  description = "The name of the dedicated service account for the Cloud Run service"
}