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
- **Optional**: health check endpoint
- **Optional**: routing rules

The platform should then:
- Issue and renew TLS/SSL certificate for the domain
- Monitor service status
- Aggregate logs and metrics
- Optionally: update running version of container if new image is pushed to registry

I have struggled to find a suitable platform for this, so have set out to create a setup
that would meet the above criteria, while utilising minimal infrastructure resources (e.g. single server) 
and relying primarily on established open source services.

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
  - **Stack**: Docker, Docker Compose, Traefik, (Doppler, Grafana)

---

## Infrastructure

## Server Setup

## Container Deployment