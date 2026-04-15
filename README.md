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
ssh wailord "mkdir -p /home/ec2-user/docker /home/ec2-user/html"

# Upload docker-compose.yml and environment file
scp docker-compose.yml wailord:/home/ec2-user/docker/
scp .env.local wailord:/home/ec2-user/docker/

# Upload nginx templates
scp -r templates wailord:/home/ec2-user/docker/

# Create initial nginx config for SSL certificate generation
ssh wailord "cat > /home/ec2-user/docker/nginx-init.conf << 'EOF'
server {
    listen       80;
    listen  [::]:80;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
EOF"

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
# Deploy updated template
scp templates/default.conf.template wailord:/home/ec2-user/docker/templates/

# Restart nginx to apply new configuration
ssh wailord "docker-compose -f /home/ec2-user/docker/docker-compose.yml --env-file /home/ec2-user/docker/.env.local restart nginx"
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

- `certs` - Let's Encrypt SSL certificates
- `certbot-www` - ACME challenge directory
- `v2ray-config` - V2Ray configuration

### Template-Based Configuration

Nginx configuration uses `envsubst` for environment variable substitution:
- Templates located in `templates/`
- `${DOMAIN}` variable is replaced at container startup
- No manual volume editing required

### File Paths

| Location | Path |
|----------|------|
| Docker Compose config | `/home/ec2-user/docker/docker-compose.yml` |
| Environment file | `/home/ec2-user/docker/.env.local` |
| Nginx templates | `/home/ec2-user/docker/templates/` |
| Static files | `/home/ec2-user/html/` |

### CloudWatch Monitoring

The `etc/cloudwatch/config.json` configures CloudWatch agent metrics collection for CPU, memory, and disk usage.

## Deployment Target

- **Platform**: AWS Lightsail (ap-southeast-1)
- **Timezone**: Asia/Shanghai
- **SSH Key**: `LightsailDefaultKey-ap-southeast-1.pem`
