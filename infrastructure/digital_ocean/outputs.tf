# IP Address of the server.
# This will print the IP on successful completion of the `terraform apply` command.
output "server_ip_address" {
  value = digitalocean_droplet.default.ipv4_address
}
