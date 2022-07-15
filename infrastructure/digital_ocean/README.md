# Terraform + Digital Ocean

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=0cfe0653d239&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)

Summary in pseudo code:

```js
function create_infrastructure(domain_name, publis_ssh_keys, registry_name) {
    const server = create_server(public_ssh_keys, apps=["docker"])
    
    const ip = create_virtual_ip()
    bind_ip(ip, server.ip)

    const domain = register_domain_name(domain_name, ip)
    create_domain_alias(`www.` + domain_name, domain)
    create_domain_record(`*.` + domain_name, ip)

    create_container_registry(registry_name)

    return ip
}
```

## Background

Terraform TLDR:
- Open-source infrastructure as code tool
- Most infrastructure providers (e.g. AWS, GCP, DigitalOcean) supply terraform module 
that allow provisioning their infrastructure
- Terrafom has to be installed locally
- Main CLI commands are:
    - `terraform init` - initialisation (nothing applied, modules downloaded)
    - `terraform apply` - provisions specified infrastructure
    - `terraform destroy` - destroys all infrastructure
- `Terraform State` is a file that stores metadata about all the provisioned resources

Terraform Cloud TLDR:
- Pricing: **FREE** (for all intents of this spec)
- Manage Terraform remotely
- Allows to store Terraform state and variables remotely

DigitalOcean Pricing:
- Server: **~7$ / month for server**
- Container Registry, DNS Records, Virtual IP Addresses: **Free**


## Steps

All the commands are expected to be run from within this directory.

1. [Install terraform locally](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. Register with [Terraform Cloud](https://app.terraform.io/session):
    1. create an organization
    2. substitute `organization` and `workspace name` at the top of [main.tf](./main.tf) with
       your values
    3. run `terraform login` inside `./infrastructure/digital_ocean`
3. Register with DigitalOcean
    1. Generate **Read and Write** [Personal Access Token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) (needed for terraform)
    2. Point your domain to [DigitalOcean nameservers](https://docs.digitalocean.com/tutorials/dns-registrars/)
4. Add variables to Terraform Cloud
    1. Use DigitalOcean Token as the `do_token` variable
    2. Use your **public ssh key** as `ssh_key_pub`
    3. Variables have to match those in [variables.tf](./variables.tf) exactly
5. Create the infrastructure 🎉
    1. ```sh
       terraform login
       terraform init
       # apply command can take a minute to complete
       # apply command will require explicit confirmation
       terraform apply
       ```
    2. Confirm infrastructure has been created by going to [DigitalOcean dashboard](https://cloud.digitalocean.com/droplets)
    3. SSH onto the server: `ssh <server_ip_address> -i ~/.ssh/id_rsa -l root`


### Destroying 

All the infrastructure created through this module can be removed by running:
> `terraform destroy`