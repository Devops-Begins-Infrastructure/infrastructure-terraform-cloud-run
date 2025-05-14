krakend_config = {
  project_id            = "dob-infra-dev-cr-compliance"  # Replace with your actual GCP project ID
  region                = "us-central1"
  service_name          = "krakend-api-gateway-dev"
  krakend_image         = "devopsfaith/krakend:2.3"  # Using a specific version is better than 'latest' for stability
  container_port        = 8080
  min_instances         = 0
  max_instances         = 2
  container_concurrency = 80    # Concurrent requests per container
  memory_limit          = "512Mi"
  cpu_limit             = "1000m"  # Must be at least 1 CPU for Gen2 execution environment
  env_variables         = {
    KRAKEND_PORT = "8080"
    DEBUG_LEVEL  = "DEBUG"
  }

  # Example of Secret Manager secrets mounted as environment variables
  secret_env_vars = [
    # {
    #   name         = "krakend-api-key"      # Name of the secret in Secret Manager
    #   env_var_name = "API_KEY"              # Name of the environment variable
    #   version      = "latest"               # Version of the secret to use
    # }
  ]

  # Example of Secret Manager secrets mounted as files with full paths
  secret_file_mounts = [
    {
      name       = "krakend-secrets"       # Nombre base para el secreto en Secret Manager
      mount_path = "/etc/krakend"          # Ruta base en el contenedor donde se montarán los archivos
      files = [
        {
          path    = "config/auth/jwt.json"  # Ruta completa del archivo dentro de mount_path
          content = <<-EOT
          {
            "signing_key": "secret-key-example",
            "issuer": "krakend-auth",
            "audience": ["api-users"],
            "expires_at": 3600
          }
          EOT
        },
        {
          path    = "config/cors/cors-settings.json"
          content = <<-EOT
          {
            "allow_origins": ["*"],
            "allow_methods": ["GET", "POST", "PUT", "DELETE"],
            "allow_headers": ["Origin", "Authorization", "Content-Type"],
            "expose_headers": ["Content-Length"],
            "max_age": 12
          }
          EOT
        },
        {
          path    = "config/keys/api-keys.json"
          content = <<-EOT
          {
            "keys": [
              {"id": "dev-key-1", "client": "internal-service-1"},
              {"id": "dev-key-2", "client": "internal-service-2"}
            ]
          }
          EOT
        }
      ]
    }
  ]

  # Example of mounting GCS buckets with config files
  gcs_bucket_mounts = [
    {
      bucket_name = "krakend-configs-dev"  # Name of the GCS bucket to create
      mount_path  = "/etc/krakend"  # Path where bucket will be mounted in container
      location    = "US"  # Location for the bucket
      files = [
        {
          name    = "krakend.json"  # Name of the file to create in the bucket
          content = <<-EOT
          {
            "version": 3,
            "endpoints": [
              {
                "endpoint": "/api/v1/users",
                "method": "GET",
                "backend": [
                  {
                    "url_pattern": "/users",
                    "host": ["https://jsonplaceholder.typicode.com"],
                    "encoding": "json",
                    "output_encoding": "no-op",
                    "extra_config": {
                      "backend/http/client": {
                        "client_timeout": "3s"
                      }
                    }
                  }
                ],
                "output_encoding": "no-op"
              }
            ],
            "extra_config": {
              "github.com/devopsfaith/krakend/health": {
                "endpoint": "/__health",
                "status": "ok"
              }
            }
          }
          EOT
        },
        {
          name    = "rate-limits.json"
          content = <<-EOT
          {
            "rate_limit": {
              "max_requests": 100,
              "window_size": 60
            }
          }
          EOT
        },
        {
          name    = "services-config.json"
          content = <<-EOT
          {
            "services": {
              "auth": {
                "url": "https://auth-service.example.com",
                "timeout": "2s"
              },
              "users": {
                "url": "https://user-service.example.com",
                "timeout": "1s"
              },
              "products": {
                "url": "https://product-service.example.com",
                "timeout": "3s"
              }
            }
          }
          EOT
        }
      ]
    }
  ]
}