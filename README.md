# Personal Containers

> The comfortable minimum to running containerised applications.

## Motivation

Even though there is an abundance of platforms offering container management services, 
I have struggled to find one that would suite my needs at a reasonable price.

I believe my **requirements** are fairy general and simple:
- Domain management, and automatic SSL certificates
- Resources sharable between containers
- Reverse proxy / routing rules (subdomains)
- Image URI as the only thing required to run a container
- Environment variables for containers
- Aggregation of metrics and container logs

I have set out to create a setup that would satisfy these requirements, 
while utilising **minimal infrastructure resources** (e.g. single server)
and relying primarily on established **open source services**.

In places, I have relied on specific vendors and their cloud platforms.
At the time of writing all of these offer a free plan suitable for personal use.

For aggregating, storing and visualising metrics and logs I am using [Grafana](https://grafana.com/).
They offer a generous free tier, and connecting data sources is fairly straightforward.

---

## Overview
- [Infrastructure](#infrastructure) - server, container registry, domain records, ssh access
  - Easily re-create/destroy
  - Minimal dependence on provider
  - Minimum resources to provision
  - **Stack**: Terraform, DigitalOcean
- [Server Setup](#server-setup) - networking, reverse proxy, subdomains
  - **Stack**: Docker Compose, Traefik
- [Containers](#container-deployment)
  - Isolated deployment file
  - **Optional**: routing configuration
  - **Extension**: environment variables
  - **Extension**: monitoring / log aggregation
  - **Stack**: Docker, Docker Compose, Traefik (extension: Doppler, Grafana)

---

## Infrastructure

The infrastructure required is described in the pseudocode below. 
Refer to [README: Terraform + Digital Ocean](./infrastructure/digital_ocean/README.md) for exact 
steps to provision the infrastructure.

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

## Server Setup

> **Outcome**: a router providing TLS/SSL certificate management and allowing the configuration
> of routing rules for services to be provided post deployment (dynamically).

The server applications will be run using Docker's `docker-compose`. 
If [infrastructure](#infrastructure) section was followed, server will have docker installed, else install this separately.

### Routing with Traefik

Traefik is an open source networking application, it allows to achieve the desired outcome
with a fairy minimal configuration.

Traefik TLDR:
- There are two types of Traefik configuration
    - static configuration - read once at deployment time (e.g. SSL certificates)
    - dynamic configuration - can be updated/provided post deployment (e.g. routing rules for containers)
- Traefik configuration can be provided in multiple ways:
  - file, CLI commands, docker-compose labels
- Optional and amazing features:
    - Manages TLS/SSL certificates automatically (issuing + renewal)
    - Middleware (e.g. BasicAuth, CORS) 
    - Health Checks 
    - Admin dashboard
    - Metrics

---

#### Implementation

1. Update [./services/traefik/.env](./services/traefik/.env) with your variables 
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
> (e.g. [./services/whoami/docker-compose.yml](./services/whoami/docker-compose.yml))

I have experimented with both file (`.yml`) and CLI commands for Traefik configuration. 
The config file was initially my preferred choice due to its clean structure. When only considering 
the static configuration - file seems appropriate - as the path to the file has to be provided 
inside the Traefik deployment file, so is reasonably easy to find. 

However, when it comes to specifying dynamic configuration having this live 
outside the service deployment file (i.e. `docker-compose.yml`) has proved fairy inconvenient. 
Having static configuration provided in a file and dynamic as labels is entirely possible, 
but for consistency I have preferred specifying both in `docker-compose.yml`.

## Container Deployment

> **Outcome**: deploy a standalone container / service at a custom subdomain.

With the above setup in place, deploying a new container becomes incredibly simple,
here is an example of deploying a `whoami` container at `whoami.<domain>`

1. Define a new service in a `docker-compose.yml` (e.g. [./services/whoami/docker-compose.yml](./services/whoami/docker-compose.yml))
   1. Labels are used to configure routing by subdomain
2. Optional: create `.env` file for the service, specifying environment variables
   1. These will be automatically picked up by `docker-compose`
   2. e.g. use your domain name in [./services/whoami/.env](./services/whoami/.env)
3. Copy the service directory to the server
   1. ```sh
      # substitute <server_ip> with actual IP of the server
      scp services/whoami "root@<server_ip>:~/services/whoami"
      ```
4. SSH into the server and deploy the container 🎉
   1. ```sh
      ssh <server_ip> -i ~/.ssh/id_rsa -l root
      cd ~/services/whoami
      docker-compose up -d
      ```

### Container Logs

> **Outcome**: container logs aggregation

Container logs can be published to Grafana using the [Docker Loki plugin](https://grafana.com/docs/loki/latest/clients/docker-driver/).

1. Configure Loki as data source in Grafana
   - Copy the URL for log publishing
   - The URL is `http://<user>:<password>@<url>` where `user`, `password` and `url` can be 
    found on the Loki data source page in Grafana
2. SSH into the server 
   - ```sh
      ssh <server_ip> -i ~/.ssh/id_rsa -l root
      ```
3. Install Docker Loki plugin 
   - ```sh
      docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
      ```
4. Configure a service to publish logs using the Loki plugin
   - ```yaml
      version: 3.3
      
      services:
        example:
          image: registry.com/example
          logging:
              driver: "loki"
              options:
                # Loki URL must be provided in the environment or .env file
                loki-url: ${LOKI_URL:?err}
                loki-retries: "5"
                loki-batch-size: "400"
      ```



## Server Monitoring

> **Outcome**: server utilisation and routing metrics

### Routing Metrics

On the server, Traefik can publish for different metric backends. 
I chose `Prometheus` - this is the default option for Traefik - it can be enabled with the `--metrics` flag (see [docker-compose.yml](./services/traefik/docker-compose.yml#L16)). 

Prometheus service is needed for metrics to be collected by Grafana, I will not be getting into the details 
of prometheus here, but ready to use configuration can be found in [./services/prometheus](./services/prometheus).
Variables inside .env need to be provided.
Once deployed (see [Container Deployment](#container-deployment) for deployment steps), prometheus metrics will be available at `prometheus.<domain>`.

I have been using a Grafana dashboard for Traefik metrics which can be found [here](https://grafana.com/grafana/dashboards/12250-traefik-2-2/).

### Server Utilisation

For server utilisation stats - [Netdata](https://github.com/netdata/netdata) provides a great dashboard exposing 
a lot of information about the server, while keeping core stats available at a glance. Netdata also fits 
the above set-up nicely - it can be deployed as a standalone container, with system directories mounted as volumes 
for access to system stats.

Ready to use configuration can be found in [./services/netdata](./services/netdata).
Variables inside .env need to be provided.
Once deployed (see [Container Deployment](#container-deployment) for deployment steps), dashboard will be available at `netdata.<domain>`.

---

## Future Extensions
- Automatic image updates
- Multiple nodes (docker-swarm)
- Remote storage