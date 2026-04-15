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
# Create tmp directory on remote instance
ssh wailord "mkdir -p /home/ec2-user/tmp"

# Deploy nginx config to remote docker volume
scp etc/nginx/conf.d/default.conf.init wailord:/home/ec2-user/tmp/default.conf.init
ssh wailord "sudo cp /home/ec2-user/tmp/default.conf.init /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf"

# Start nginx and certbot for initial SSL certificate
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml --env-file /home/ec2-user/docker/.env.local up nginx certbot"
```

### Start All Services

```bash
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml --env-file /home/ec2-user/docker/.env.local up -d"
```

### Renew SSL Certificate

```bash
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml --env-file /home/ec2-user/docker/.env.local up certbot"
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml exec nginx nginx -s reload"
```

### Update Nginx Configuration

```bash
# Deploy to remote docker volume
scp etc/nginx/conf.d/default.conf wailord:/home/ec2-user/tmp/default.conf
ssh wailord "sudo cp /home/ec2-user/tmp/default.conf /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf"
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml exec nginx nginx -s reload"
```

### Deploy Static Site Files

```bash
# Build the Astro project (in the client repository)
npm run build

# Deploy built files to the instance
scp -r client/dist/* wailord:/home/ec2-user/html/
```

## Architecture

### Service Communication

- **Nginx** (ports 80, 443) terminates TLS and routes traffic:
  - `/` → Serves static Astro build files from `/usr/share/nginx/html` (bind mount from `/home/ec2-user/html`)
  - `/tech` → `v2ray:11055` (V2Ray websocket endpoint, only accepts websocket upgrades)
- **V2Ray** listens on port 11055 internally, configured via `/etc/v2ray/config.json`
- Static files are built locally and deployed to `/home/ec2-user/html` on the instance

### Docker Volumes

- `nginx-conf` - Nginx configuration
- `certs` - Let's Encrypt SSL certificates
- `certbot-www` - ACME challenge directory
- `v2ray-config` - V2Ray configuration

### File Paths

| Location | Path |
|----------|------|
| Docker Compose config | `/home/ec2-user/docker/docker-compose.yml` |
| Environment file | `/home/ec2-user/docker/.env.local` |
| Nginx docker volume | `/var/lib/docker/volumes/docker_nginx-conf/_data/` |
| Temp directory | `/home/ec2-user/tmp/` |
| Static files | `/home/ec2-user/html/` |

### CloudWatch Monitoring

The `etc/cloudwatch/config.json` configures CloudWatch agent metrics collection for CPU, memory, and disk usage.

## Deployment Target

- **Platform**: AWS Lightsail (ap-southeast-1)
- **Timezone**: Asia/Shanghai
- **SSH Key**: `LightsailDefaultKey-ap-southeast-1.pem`
