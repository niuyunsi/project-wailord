# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Project Wailord is a Docker Compose-based deployment running on AWS Lightsail (ap-southeast-1). It provides:
- A Next.js web application client (hosted on ECR: `public.ecr.aws/n6q5v2z5/project-wailmer`)
- V2Ray proxy service (vmess protocol over websocket)
- Nginx reverse proxy with SSL termination
- Certbot for Let's Encrypt SSL certificate management

## Commands

### First-time setup
```bash
# Initialize nginx config before starting services
sudo scp etc/nginx/conf.d/default.conf.init /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf

# Start nginx and certbot for initial SSL certificate
docker-compose --env-file .env.local up nginx certbot
```

### Start all services
```bash
docker-compose --env-file .env.local up -d
```

### Renew SSL certificate
```bash
docker-compose --env-file .env.local up certbot
docker-compose --env-file .env.local exec nginx nginx -s reload
```

### Update nginx configuration
```bash
# Copy local config to docker volume
sudo scp etc/nginx/conf.d/default.conf /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf

# Or deploy to remote instance
scp -i LightsailDefaultKey-ap-southeast-1.pem etc/nginx/conf.d/default.conf ec2-user@54.169.124.85:/home/ec2-user/docker
```

## Architecture

### Service Communication
- **Nginx** (ports 80, 443) terminates TLS and routes traffic:
  - `/` → `client:3000` (Next.js app)
  - `/tech` → `v2ray:11055` (V2Ray websocket endpoint, only accepts websocket upgrades)
- **V2Ray** listens on port 11055 internally, configured via `/etc/v2ray/config.json`
- **Client** is a containerized image pulled from ECR, runs on port 3000

### Docker Volumes
- `nginx-conf` - Nginx configuration
- `certs` - Let's Encrypt SSL certificates
- `certbot-www` - ACME challenge directory
- `v2ray-config` - V2Ray configuration

### Environment Variables
The `.env.local` file contains:
- `EMAIL` - For Let's Encrypt notifications
- `DOMAIN` - The domain for SSL certificates (currently `wailord2.f7b7.com`)
- `V2RAY_ID` - UUID for V2Ray client authentication

### CloudWatch Monitoring
The `etc/cloudwatch/config.json` configures CloudWatch agent metrics collection for CPU, memory, and disk usage.

## Deployment Target

The project is deployed to an AWS Lightsail instance via SSH key `LightsailDefaultKey-ap-southeast-1.pem`. All services use the `Asia/Shanghai` timezone.
