# Developer documentation

This directory contains the `dev-docs` project for internal developer documentation.

## Hosting the documentation

Assuming you have installed the required software using the `init.sh` script:

### Local, non-containerised

This is recommended for development purposes, as it supports **live refresh**.

```bash
uv run mkdocs serve -a <HOST>:<PORT>  # default: localhost:8000
```

### Docker

(**TODO**: create Dockerfile, global Docker Compose file for entire repo)

```bash
bake dev-docs                 # Build static site, then copy into a Docker image
docker compose up -d dev-docs # Launch the Docker service

# OR
# docker compose --profile <profile> up -d # Launch all services under the <profile> profile
```

### Kubernetes (local minikube)

(**TODO**: create k8s/)

For a static site, we need only the following:

```text
Dockerfile
k8s
├─ 01-deployment.yaml
└─ 02-service.yaml
```

Then:

```bash
# To connect to LoadBalancer services
minikube tunnel

# Deploy the new service and associated resources
minikube kubectl apply -f k8s/
```

### Google Cloud platform

(**TODO**)

## Traefik setup for Docker Compose / Kubernetes

For Docker, see [the Traefik Docker documentation](https://doc.traefik.io/traefik/routing/providers/docker/).

For Kubernetes, see the documentation for [deploying a Traefik Kubernetes Gateway](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/).
