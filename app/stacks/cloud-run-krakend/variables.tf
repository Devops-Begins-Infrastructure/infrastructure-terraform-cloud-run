variable "krakend_config" {
  description = "Object containing all configuration for KrakenD Cloud Run service"
  type = object({
    project_id            = string
    region                = optional(string, "us-central1")
    service_name          = optional(string, "krakend-api-gateway")
    krakend_image         = optional(string, "devopsfaith/krakend:latest")
    service_account_email = optional(string, "")
    container_port        = optional(number, 8080)
    min_instances         = optional(number, 0)
    max_instances         = optional(number, 2)
    container_concurrency = optional(number, 80)
    memory_limit          = optional(string, "512Mi")
    cpu_limit             = optional(string, "1000m")
    vpc_connector         = optional(string, null)
    env_variables         = optional(map(string), {})
    service_account_roles = optional(list(object({
      role    = string  # IAM role to grant (e.g., roles/secretmanager.secretAccessor)
      project = string  # GCP project ID where the role should be granted
    })), [])
    
    secret_file_mounts = optional(list(object({
      name        = string  # Name prefix for the secrets in Secret Manager
      mount_path  = string  # Base path in container where files will be mounted
      files = list(object({
        path    = string  # Full path of the file inside the mount_path
        content = string  # Content of the file
      }))
    })), [])
    
    secret_env_vars = optional(list(object({
      name         = string  # Name of the secret in Secret Manager
      env_var_name = string  # Name of the environment variable
      version      = string  # Version of the secret, default is 'latest'
    })), [])
    
    gcs_bucket_mounts = optional(list(object({
      bucket_name = string  # Name of the GCS bucket containing configs
      mount_path  = string  # Path where bucket will be mounted in container
      location    = optional(string, "US")  # Location for the bucket
      files = list(object({
        name    = string  # Name of the file to create in the bucket
        content = string  # Content of the file
      }))
    })), [])
  })
}