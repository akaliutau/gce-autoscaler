variable "container" {
  type        = any
  description = "A description of the container to deploy"
  default = {
    image   = "gcr.io/google-containers/busybox"
    command = "ls"
  }
}

variable "volumes" {
  type        = any
  description = "A set of Docker Volumes to configure"
  default     = []
}

variable "restart_policy" {
  description = "The restart policy for a Docker container. Defaults to `OnFailure`"
  type        = string
  default     = "OnFailure"
}

variable "cos_image_family" {
  description = "The COS image family to use (eg: stable, beta, or dev)"
  type        = string
  default     = "stable"
}

variable "cos_image_name" {
  description = "Name of a specific COS image to use instead of the latest cos family image"
  type        = string
  default     = null
}
