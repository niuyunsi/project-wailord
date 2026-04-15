# Project Wailord

Docker Compose deployment on AWS Lightsail providing static web hosting and V2Ray proxy service.

## Overview

- **Static web assets** (Astro build) served via Nginx from `/home/ec2-user/html`
- **V2Ray proxy** (vmess protocol over websocket)
- **Nginx reverse proxy** with SSL termination
- **Certbot** for Let's Encrypt SSL certificate automation

## SSH Configuration

Add this to your `~/.ssh/config`:

```bash
Host wailord
    HostName ip-address-of-your-lightsail-instance
    User ec2-user
    IdentityFile ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem
```

This allows using `ssh wailord` and `wailord:` prefix for scp instead of specifying the key and full address each time.

## Environment Variables

Create `.env.local` file with:

```bash
EMAIL=your-email@example.com
DOMAIN=your-domain.com
V2RAY_ID=your-v2ray-uuid
```

## Deployment

### First Time Setup

```bash
# Create necessary directories on remote instance
ssh wailord "mkdir -p /home/ec2-user/docker/etc/nginx/templates /home/ec2-user/docker/etc/v2ray /home/ec2-user/html"

# Upload docker-compose.yml and environment file
scp docker-compose.yml wailord:/home/ec2-user/docker/
scp .env.local wailord:/home/ec2-user/docker/.env

# Upload V2Ray configuration template
scp etc/v2ray/config.json.template wailord:/home/ec2-user/docker/etc/v2ray/config.json.template

# Generate V2Ray configuration on remote server (using remote .env)
ssh wailord "cd /home/ec2-user/docker && set -a && source .env && set +a && envsubst < etc/v2ray/config.json.template > etc/v2ray/config.json"

# Upload initial nginx template for SSL certificate generation
# (SSL certificates don't exist yet, so we use a simplified template with HTTP only)
scp etc/nginx/templates/default.conf.init.template wailord:/home/ec2-user/docker/etc/nginx/templates/default.conf.template

# Start nginx and certbot for initial SSL certificate
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml up nginx certbot"

# After certificates are obtained, upload the full nginx template
scp etc/nginx/templates/default.conf.template wailord:/home/ec2-user/docker/etc/nginx/templates/

# Restart nginx to apply the full configuration
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml restart nginx"

# Start all services
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml up -d"
```

### Start All Services

```bash
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml up -d"
```

### Renew SSL Certificate

```bash
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml up certbot"
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml exec nginx nginx -s reload"
```

### Update Nginx Configuration

```bash
# Ensure target directory exists (may not exist on first run)
ssh wailord "mkdir -p /home/ec2-user/docker/etc/nginx/templates"

# Deploy updated template
scp etc/nginx/templates/default.conf.template wailord:/home/ec2-user/docker/etc/nginx/templates/

# Restart nginx to apply new configuration
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml restart nginx"
```

### Update V2Ray Configuration

```bash
# Upload V2Ray configuration template
scp etc/v2ray/config.json.template wailord:/home/ec2-user/docker/etc/v2ray/config.json.template

# Generate V2Ray configuration on remote server (using remote .env)
ssh wailord "cd /home/ec2-user/docker && set -a && source .env && set +a && envsubst < etc/v2ray/config.json.template > etc/v2ray/config.json"

# Restart v2ray to apply new configuration
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml restart v2ray"
```

## Architecture

### Service Communication

- **Nginx** (ports 80, 443) terminates TLS and routes traffic:
  - `/` → Serves static Astro build files from `/usr/share/nginx/html` (bind mount from `/home/ec2-user/html`)
  - `/tech` → `v2ray:11055` (V2Ray websocket endpoint, only accepts websocket upgrades)
- **V2Ray** listens on port 11055 internally, configured via `/etc/v2ray/config.json`
- Static files are built locally and deployed to `/home/ec2-user/html` on the instance

### Docker Volumes

- `certs` - Let's Encrypt SSL certificates
- `certbot-www` - ACME challenge directory

### V2Ray Configuration

- Template file `config.json` uses `${V2RAY_ID}` variable
- Uploaded to `/home/ec2-user/docker/etc/v2ray/config.json.template`
- Generated on remote server using `envsubst` with remote `.env` file
- `set -a` automatically exports all variables from `.env` for `envsubst` to use
- Output to `/home/ec2-user/docker/etc/v2ray/config.json`
- Mounted as read-only into container at `/etc/v2ray/config.json`

### Template-Based Configuration

Nginx configuration uses `envsubst` for environment variable substitution:
- Templates located in `etc/nginx/templates/`
- `${DOMAIN}` variable is replaced at container startup
- No manual volume editing required

**Template Files:**
- `default.conf.template` - Full nginx configuration with SSL
- `default.conf.init.template` - Simplified template for initial SSL certificate generation (HTTP only)

### File Paths

| Location | Path |
|----------|------|
| Docker Compose config | `/home/ec2-user/docker/docker-compose.yml` |
| Environment file | `/home/ec2-user/docker/.env` |
| Nginx templates | `/home/ec2-user/docker/etc/nginx/templates/` |
| V2Ray config template | `/home/ec2-user/docker/etc/v2ray/config.json.template` |
| V2Ray generated config | `/home/ec2-user/docker/etc/v2ray/config.json` |
| Static files | `/home/ec2-user/html/` |

### CloudWatch Monitoring

The `etc/cloudwatch/config.json` configures CloudWatch agent metrics collection for CPU, memory, and disk usage.

## Deployment Target

- **Platform**: AWS Lightsail (ap-southeast-1)
- **Timezone**: Asia/Shanghai
- **SSH Key**: `LightsailDefaultKey-ap-southeast-1.pem`
