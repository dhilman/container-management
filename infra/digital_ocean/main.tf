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

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_container_registry" "default" {
  name                   = var.registry_name
  # Available subscription tiers: https://docs.digitalocean.com/reference/api/api-reference/#operation/registry_create
  subscription_tier_slug = "starter"
}

resource "digitalocean_ssh_key" "default" {
  name       = "david-ssh-key"
  public_key = var.ssh_key_pub
}

resource "digitalocean_droplet" "default" {
  # Using an image with docker installed.
  # https://marketplace.digitalocean.com/apps/docker
  image    = "docker-20-04"
  name     = "default"
  # Available regions: https://docs.digitalocean.com/reference/api/api-reference/#tag/Regions
  region   = "lon1"
  # Available sizes: https://docs.digitalocean.com/reference/api/api-reference/#tag/Sizes
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
}

resource "digitalocean_reserved_ip" "default" {
  region = "lon1"
}

resource "digitalocean_domain" "default" {
  name       = var.domain_name
  ip_address = digitalocean_reserved_ip.default.ip_address
}

resource "digitalocean_record" "www_alias" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  # Time To Live in seconds.
  ttl    = 3600
}

resource "digitalocean_record" "wildcard_redirect" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "*"
  value  = digitalocean_reserved_ip.default.ip_address
  # Time To Live in seconds.
  ttl    = 3600
}

resource "digitalocean_reserved_ip_assignment" "default" {
  ip_address = digitalocean_reserved_ip.default.ip_address
  droplet_id = digitalocean_droplet.default.id
}
