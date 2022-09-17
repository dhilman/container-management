# Traefik

Reverse proxy + certificate management.

## Content:

- [Traefik Basics](#traefik-basics)
  - [Architecture](#architecture)
  - [Configuration](#configuration)
    - [Static Configuration](#static-configuration)
    - [Dynamic Configuration](#dynamic-configuration)
- [Deployment](#deployment)
  - [Prerequisites](#prerequisites)

## Traefik Basics

### Architecture 

Traefik internal [components](https://doc.traefik.io/traefik/providers/overview/):
1. **Provides**: discover available services 
2. **Entrypoints**: listening for incoming traffic
3. **Routers**: analyse / process the request based on rules
   - Middleware: update the request
   - Rules: determine if the request satisfies the rules
4. **Services**: forward request to services (+ load balancing)

### Configuration

Traefik uses two types of configuration.

#### Static Configuration

- Used at service start up
- Defines **general settings**
  - Entrypoints
  - Certificate resolvers
  - Providers (e.g. docker)
- Can be provided as one of:
  - Command line arguments
  - Configuration file 

### Dynamic Configuration

- Can be updated dynamically
- Defines
  - Routers
  - Services
  - Middlewares
- Can be provided as:
  - Labels (e.g. docker labels)
  - Configuration file

## Deployment

- traefik [docker-compose file](docker-compose.yml)
- static configuration provided as commands in `docker-compose` file
- dynamic configuration provided as docker labels
  - configures Admin middleware (basic HTTP auth)
  - configures traefik `admin` host 
- other services 
  - dynamic config can be provided as **docker labels**
  - e.g. [whoami docker-compose](../whoami/docker-compose.yml)

### Prerequisites

- Domain records:
  - `A` record from `domain` to IP that traefik is running on
  - `A` record from `*.domain` to IP (if subdomains are to be used)
  - `CNAME` record from `www.domain` to `domain`