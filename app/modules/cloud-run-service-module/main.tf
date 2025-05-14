terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Create a dedicated service account for the Cloud Run service
resource "google_service_account" "service_account" {
  account_id   = var.service_name
  display_name = "${var.service_name} Service Account"
  project      = var.project_id
  description  = "Service account for ${var.service_name} Cloud Run service"
}

# Assign specified IAM roles to the service account
resource "google_project_iam_member" "service_account_roles" {
  for_each = { for idx, role_mapping in var.service_account_roles : "${role_mapping.project}-${role_mapping.role}" => role_mapping }
  
  project = each.value.project
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Create a local variable to store the secret content mappings
locals {
  create_valid_secret_name = function(secret_name, file_path) 
  {
    "${secret_name}-${replace(replace(file_path, "/", "-"), ".", "-")}"
  }
  
  secret_contents = {
    for idx, file_data in flatten([
      for secret in var.secret_file_mounts : [
        for file in secret.files : {
          secret_name = local.create_valid_secret_name(secret.name, file.path)
          content     = file.content
        }
      ]
    ]) : file_data.secret_name => file_data.content
  }
}

# Create Secret Manager secrets for each file in secret_file_mounts
resource "google_secret_manager_secret" "file_secrets" {
  for_each = {
    for idx, file_data in flatten([
      for secret in var.secret_file_mounts : [
        for file in secret.files : {
          secret_name = local.create_valid_secret_name(secret.name, file.path)
          mount_path  = secret.mount_path
          file_path   = file.path
        }
      ]
    ]) : file_data.secret_name => file_data
  }

  secret_id = each.key
  project   = var.project_id

  replication {
    auto {}
  }
}

# Add secret versions for each file content
resource "google_secret_manager_secret_version" "file_secret_versions" {
  for_each = google_secret_manager_secret.file_secrets

  secret      = each.value.id
  secret_data = local.secret_contents[each.key]
}

# Add IAM binding to allow the service account to access the secrets
resource "google_secret_manager_secret_iam_member" "file_secret_access" {
  for_each = google_secret_manager_secret.file_secrets
  
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service_account.email}"
}

# Create GCS buckets for mounting
resource "google_storage_bucket" "config_buckets" {
  for_each = { for idx, bucket in var.gcs_bucket_mounts : bucket.bucket_name => bucket }
  
  name          = each.value.bucket_name
  project       = var.project_id
  location      = each.value.location
  force_destroy = true  # This allows Terraform to delete the bucket even if it contains files
  
  uniform_bucket_level_access = true  # Enable uniform bucket-level access
}

# Upload files to the GCS buckets
resource "google_storage_bucket_object" "config_files" {
  for_each = {
    for idx, file_data in flatten([
      for bucket in var.gcs_bucket_mounts : [
        for file in bucket.files : {
          bucket_name = bucket.bucket_name
          file_name   = file.name
          content     = file.content
        }
      ]
    ]) : "${file_data.bucket_name}-${file_data.file_name}" => file_data
  }

  name    = each.value.file_name
  bucket  = google_storage_bucket.config_buckets[each.value.bucket_name].name
  content = each.value.content
}

# Grant access to GCS buckets for the service account
resource "google_storage_bucket_iam_member" "gcs_bucket_access" {
  for_each = { for idx, bucket in var.gcs_bucket_mounts : bucket.bucket_name => bucket }
  
  bucket = google_storage_bucket.config_buckets[each.value.bucket_name].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = var.container_image
        
        ports {
          container_port = var.container_port
        }

        resources {
          limits = {
            memory = var.memory_limit
            cpu    = var.cpu_limit
          }
        }

        # Regular environment variables
        dynamic "env" {
          for_each = var.env_variables
          content {
            name  = env.key
            value = env.value
          }
        }
        
        # Secret Manager as environment variables
        dynamic "env" {
          for_each = var.secret_env_vars
          content {
            name = env.value.env_var_name
            value_from {
              secret_key_ref {
                name    = env.value.name
                key     = env.value.version
              }
            }
          }
        }
        
        # Mount Secret Manager secrets as files with full paths
        dynamic "volume_mounts" {
          for_each = {
            for idx, file_data in flatten([
              for secret in var.secret_file_mounts : [
                for file in secret.files : {
                  secret_name = local.create_valid_secret_name(secret.name, file.path)
                  mount_group = secret.name
                  mount_path  = secret.mount_path
                  file_path   = file.path
                  dirname     = dirname(file.path)
                }
              ]
            ]) : "${file_data.mount_group}-${file_data.file_path}" => file_data
          }
          
          content {
            name       = "secret-${volume_mounts.value.mount_group}-${replace(replace(volume_mounts.value.file_path, "/", "-"), ".", "-")}"
            mount_path = "${volume_mounts.value.mount_path}/${volume_mounts.value.file_path}"
          }
        }
        
        # Mount GCS buckets
        dynamic "volume_mounts" {
          for_each = var.gcs_bucket_mounts
          content {
            name       = "gcs-${replace(volume_mounts.value.bucket_name, ".", "-")}"
            mount_path = volume_mounts.value.mount_path
          }
        }
      }

      # Mount Secret Manager secrets as files with full paths
      dynamic "volumes" {
        for_each = {
          for idx, file_data in flatten([
            for secret in var.secret_file_mounts : [
              for file in secret.files : {
                secret_name = local.create_valid_secret_name(secret.name, file.path)
                mount_group = secret.name
                mount_path  = secret.mount_path
                file_path   = file.path
              }
            ]
          ]) : file_data.secret_name => file_data
        }
        
        content {
          name = "secret-${volumes.value.mount_group}-${replace(replace(volumes.value.file_path, "/", "-"), ".", "-")}"
          secret {
            secret_name = volumes.value.secret_name
            items {
              key  = "latest"
              path = volumes.value.file_path
            }
          }
        }
      }
      
      # Define volumes for GCS buckets
      dynamic "volumes" {
        for_each = var.gcs_bucket_mounts
        content {
          name = "gcs-${replace(volumes.value.bucket_name, ".", "-")}"
          csi {
            driver = "gcsfuse.run.googleapis.com"
            read_only = true
            volume_attributes = {
              bucketName = google_storage_bucket.config_buckets[volumes.value.bucket_name].name
            }
          }
        }
      }

      container_concurrency = var.container_concurrency
      service_account_name  = google_service_account.service_account.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = var.min_instances
        "autoscaling.knative.dev/maxScale"      = var.max_instances
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector != null ? var.vpc_connector : null
        "run.googleapis.com/vpc-access-egress"    = var.vpc_connector != null ? "all-traffic" : null
        "run.googleapis.com/execution-environment" = "gen2"  # Required for some volume mounting features
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
  
  # Make sure the Cloud Run service depends on the bucket and file uploads
  depends_on = [
    google_storage_bucket.config_buckets,
    google_storage_bucket_object.config_files,
    google_storage_bucket_iam_member.gcs_bucket_access
  ]
}

# IAM policy to make the service publicly accessible if configured
resource "google_cloud_run_service_iam_member" "public_access" {
  count    = var.allow_public_access ? 1 : 0
  location = google_cloud_run_service.service.location
  project  = google_cloud_run_service.service.project
  service  = google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}