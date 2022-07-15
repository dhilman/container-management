terraform {
  cloud {
    organization = "dhilman"
    workspaces {
      name = "dhilman"
    }
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.21.0"
    }
  }
}

# Configures access to a specific DigitalOcean project based on the provided access token.
provider "digitalocean" {
  token = var.do_token
}

# Creates a Free DigitalOcean container registry.
resource "digitalocean_container_registry" "default" {
  # Final registry URL will be: registry.digitalocean.com/<registry_name>
  name                   = var.registry_name
  # Available subscription tiers:
  # https://docs.digitalocean.com/reference/api/api-reference/#operation/registry_create
  subscription_tier_slug = "starter"
}

# Registering Public SSH Key with DigitalOcean.
# This is used in server configuration to enable SSH access.
resource "digitalocean_ssh_key" "personal" {
  name       = "personal-ssh-key"
  public_key = var.ssh_key_pub
}

# Droplet is DigitalOcean's name for a server.
resource "digitalocean_droplet" "default" {
  # Using an image with docker installed.
  # https://marketplace.digitalocean.com/apps/docker
  image    = "docker-20-04"
  # Name for the server.
  name     = "default"
  # Available regions:
  # https://docs.digitalocean.com/reference/api/api-reference/#tag/Regions
  region   = "lon1"
  # Available sizes:
  # https://docs.digitalocean.com/reference/api/api-reference/#tag/Sizes
  size     = "s-1vcpu-1gb"
  # SSH keys that can be used to access the server.
  ssh_keys = [
    digitalocean_ssh_key.personal.id,
  ]
}

# Creating a virtual/reserved IP address to bind the domain records to.
# Allows to recreate the server without effecting domain records.
resource "digitalocean_reserved_ip" "default" {
  region = "lon1"
}

# Binding the domain address to the reserved IP address.
resource "digitalocean_domain" "default" {
  name       = var.domain_name
  ip_address = digitalocean_reserved_ip.default.ip_address
}

# Creating an CNAME record (alias) to redirect from www.<domain> to <domain>
resource "digitalocean_record" "www_alias" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  # Time To Live in seconds.
  ttl    = 3600
}

# Creating an A record to direct all requests to subdomains to the IP address.
resource "digitalocean_record" "wildcard_redirect" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "*"
  value  = digitalocean_reserved_ip.default.ip_address
  # Time To Live in seconds.
  ttl    = 3600
}

# Assigning IP address of the server to the reserved IP address.
resource "digitalocean_reserved_ip_assignment" "default" {
  ip_address = digitalocean_reserved_ip.default.ip_address
  droplet_id = digitalocean_droplet.default.id
}
