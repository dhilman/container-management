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

This section provides option[s] to provision infrastructure described in the pseudocode below. 
Feel free to skip if this infrastructure already exists.

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

Implementation Options:
- [README: Terraform + Digital Ocean](./infrastructure/digital_ocean/README.md)


## Server Setup

> **Outcome**: setup router with ability to add service based routing and TLS/SSL certificate management dynamically.

The server applications will be run using Docker's `docker-compose`. 
If [infrastructure](#infrastructure) section was followed, server will have docker installed, else install this separetely.

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