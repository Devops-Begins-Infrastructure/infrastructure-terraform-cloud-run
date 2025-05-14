variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "container_image" {
  description = "Docker image to use for the Cloud Run service"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port on which the container will listen"
  type        = number
  default     = 8080
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 2
}

variable "container_concurrency" {
  description = "Maximum number of concurrent requests per container"
  type        = number
  default     = 80
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "1000m"
}

variable "vpc_connector" {
  description = "The VPC connector to use for the Cloud Run service"
  type        = string
  default     = null
}

variable "env_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "allow_public_access" {
  description = "Whether to make the service publicly accessible"
  type        = bool
  default     = false
}

variable "secret_file_mounts" {
  description = "Files to create as secrets and mount in the container with full path control"
  type = list(object({
    name        = string  # Name of the secret in Secret Manager
    mount_path  = string  # Path in container where secret will be mounted
    files = list(object({
      path    = string  # Full path of the file inside the mount_path
      content = string  # Content of the file
    }))
  }))
  default = []
}

variable "secret_env_vars" {
  description = "Secret Manager secrets to inject as environment variables"
  type = list(object({
    name         = string  # Name of the secret in Secret Manager
    env_var_name = string  # Name of the environment variable
    version      = string  # Version of the secret, default is 'latest'
  }))
  default = []
}

variable "service_account_roles" {
  description = "IAM roles to grant to the service account with their respective projects"
  type = list(object({
    role    = string  # IAM role to grant (e.g., roles/secretmanager.secretAccessor)
    project = string  # GCP project ID where the role should be granted
  }))
  default = []
}

variable "gcs_bucket_mounts" {
  description = "GCS buckets to create, upload files to, and mount in the container"
  type = list(object({
    bucket_name = string  # Name of the GCS bucket to create
    mount_path  = string  # Path in container where bucket will be mounted
    location    = optional(string, "US")  # Location for the bucket (default: "US")
    files = list(object({
      name    = string  # Name of the file to create in the bucket
      content = string  # Content of the file
    }))
  }))
  default = []
}