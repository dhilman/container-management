# Container Management

> The comfortable minimum for running containerised applications.

## Motivation

Setting up infrastructure to be able to easily deploy containerized software can be expensive, 
complicated and reliant on proprietary solutions.

- [ ] TODO: include AWS, DO, Google pricing for k8s management, load balancers, servers

In an ideal world, I want a platform where all that is required for deployment is:
- Image name 
- Domain name
- **Optional**: environment variables
- **Optional**: routing rules
- **Optional**: health check endpoint

The platform should then:
- Issue and renew TLS/SSL certificate for the domain
- Monitor service status
- Aggregate logs and metrics
- **Optional**: update running version of container if new image is pushed to registry

I have struggled to find a suitable platform for this, so have set out to create a setup
that would meet the above criteria, while utilising **minimal infrastructure resources** (e.g. single server) 
and relying primarily on established **open source services**.

- [ ] TODO: In places, I have relied on specific vendors and their cloud platforms.
At the time of writing all of these have a free plan which is 

---

## Overview
- [Infrastructure](#infrastructure) - server, container registry, domain records, access
  - Easily re-create/destroy
  - Minimal dependence on provider
  - Minimum resources to provision
  - **Stack**: Terraform, DigitalOcean
- [Server Setup](#server-setup) - networking, container management
  - Minimal set of commands to run
  - New services should be deployable in isolation
    - [ ] better description
  - **Extension**: automatic container redeployment on new version
  - **Stack**: Docker Compose, Traefik
- [Container / Service Deployment](#container-deployment)
  - Isolated deployment file
  - **Extension**: Simple management of environment variables
  - **Extension**: monitoring / log aggregation
  - **Stack**: Docker, Docker Compose, Traefik (extension: Doppler, Grafana)

---

## Infrastructure

> **Outcome**: programmatically provision a server, container registry and configure DNS records.

Terraform - open-source infrastructure as code tool - allows to achieve the above goal while minimizing
the number of manual actions/configurations that have to be done.

Infrastructure providers (e.g. AWS, GCP, DigitalOcean) supply terraform modules that allow to 
provision their infrastructure as code.

Terraform TLDR:
- Terraform has to be installed locally
- Main CLI commands are:
  - `terraform init` - initialisation (nothing applied, modules downloaded)
  - `terraform apply` - provisions specified infrastructure
  - `terraform destroy` - destroys all infrastructure
- `Terraform State` is a file that stores metadata about all the provisioned resources

Terraform Cloud TLDR:
- Pricing: **FREE** (for all intents of this spec)
- Manage Terraform remotely
- Allows to store Terraform state and variables stored remotely

### Solution: Terraform (Cloud) + DigitalOcean

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=0cfe0653d239&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)

DigitalOcean Pricing:
- Server: **~7$ / month for server**
- Container Registry, DNS Records, Virtual IP Addresses: **Free**

This section refers exclusively to [./infrastructure/digital_ocean](./infrastructure/digital_ocean) directory.
The [main.tf](./infrastructure/digital_ocean/main.tf) uses the official [DigitalOcean Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
and contains comments to explain all the resources and variables.

---

Steps:

1. [Install terraform locally](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. Register with [Terraform Cloud](https://app.terraform.io/session):
    1. create an organization
    2. substitute `organization` and `workspace name` at the top of [main.tf](./infrastructure/digital_ocean/main.tf) with
         your values
    3. run `terraform login` inside `./infrastructure/digital_ocean`
3. Register with DigitalOcean
    1. Generate **Read and Write** [Personal Access Token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) (needed for terraform)
    2. Point your domain to [DigitalOcean nameservers](https://docs.digitalocean.com/tutorials/dns-registrars/)
4. Add variables to Terraform Cloud
    1. Use DigitalOcean Token as the `do_token` variable
    2. Use your **public ssh key** as `ssh_key_pub`
    3. Variables have to match those in [variables.tf](./infrastructure/digital_ocean/variables.tf) exactly
5. Create the infrastructure 🎉
    1. Inside [./infrastructure/digital_ocean](./infrastructure/digital_ocean) 
    2. ```sh
       terraform login
       terraform init
       # apply command can take a minute to complete
       # apply command will require explicit confirmation
       terraform apply
       ```

When the Terraform `apply` command completes - infrastructure would
have been created. If you go to DigitalOcean Dashboard you should be able to see your droplet,
container registry and domain records.

At the end of output from the `terraform apply` command, the IP address of the newly created server
should be printed. This can be used to SSH onto the server.
- `ssh <server_ip_address> -i ~/.ssh/id_rsa -l root`


## Server Setup

> **Outcome**: setup router with ability to add service based routing and TLS/SSL certificate management dynamically.

The server applications will be run using Docker's `docker-compose`. 
If the [Terraform](#solution-terraform-cloud--digitalocean) module was used to create the server 
then Docker and `docker-compose` would come pre-installed.

### Solution: Routing with Traefik

Traefik is an open source networking application, it allows to achieve all the desired routing outcomes
with a fairy minimal configuration.

Traefik background TLDR:
- There are two types of Traefik configuration
    - static configuration - read once at deployment time
    - dynamic configuration - can be updated/provided post deployment (e.g. routing rules provided along deployment of new services)
- Traefik configuration can be provided in multiple ways:
  - file, CLI commands, docker-compose labels
- Optional and amazing features:
    - Manages TLS/SSL certificates automatically (issuing + renewal)
    - Middleware (e.g. BasicAuth, CORS) 
    - Health Checks 
    - Admin dashboard
    - Metrics

---

Steps:

1. Update [.env](./services/traefik/.env) with your variables 
   - `ADMIN_USERS` are `user:password` pairs. This is currently set to `user=foo`, `password=bar`
   - To generate `user:password` use: `echo $(htpasswd -nb foo bar)`
2. Copy the `./services/traefik` directory to your server
   1. ```sh
      # substitute <server_ip> with actual IP of the server
      scp -r services/traefik "root@<server_ip>:~/services/"
      ```
3. Deploy Traefik on the server
   1. ```sh
      # ssh into the server
      ssh <server_ip> -i ~/.ssh/id_rsa -l root
      cd ~/services/traefik
      # run Traefik services in detached (-d) mode
      # Note: docker-compose automatically picks up variables inside .env file
      docker-compose up -d
      ```
4. Visit your personal traefik dashboard: `admin.<domain>/dashboard`

#### Traefik opinionated choices

> Static configuration provided inside [docker-compose.yml](services/traefik/docker-compose.yml) as CLI commands.
> Dynamic configuration provided as **docker labels** inside docker-compose files of new services 
> (e.g. [whoami docker-compose.yml](./services/whoami/docker-compose.yml))

I have experimented with both file (`.yml`) and CLI commands for Traefik configuration. 
The config file was initially my preffered choice due to its clean structure. When only considering 
the static configuration - file seems appropriate - as the path to the file has to be provided 
inside the Traefik deployment file. However, when it comes to specifying dynamic configuration having this live 
outside of the service deployment file (i.e. `docker-compose.yml`) has proved fairy inconvenient. 
Having static configuration provided in a file and dynamic as labels is entirely possible, 
but for consistency I have preferred specifying both in the `docker-compose.yml`.

## Container Deployment

> **Outcome**: deploy a standalone container / service at a custom subdomain.

## Server Monitoring

> **Outcome**: server utilisation and routing metrics

## Containerisation

> **Outcome**: containerise application, build and push on merge to master.


## Future Extensions:
- Automatic image updates
- Multiple nodes (docker-swarm)
- Remote storage