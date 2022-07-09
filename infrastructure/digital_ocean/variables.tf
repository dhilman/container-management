variable "do_token" {
  # Creation of PAT: https://docs.digitalocean.com/reference/api/create-personal-access-token/
  type        = string
  description = "Digital Ocean Personal Access Token (PAT) with read and write permissions."
}

variable "ssh_key_pub" {
  type        = string
  description = "Public SSH key"
}

variable "registry_name" {
  type        = string
  description = "Container registry name"
}

variable "domain_name" {
  type = string
  description = "Name of the domain"
}
