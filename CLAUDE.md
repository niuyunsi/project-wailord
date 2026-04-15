# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Project Wailord is a Docker Compose deployment for AWS Lightsail. It provides:
- Static web assets (Astro build) served via Nginx
- V2Ray proxy service (vmess over websocket)
- Nginx reverse proxy with SSL termination
- Certbot for Let's Encrypt SSL certificates

## Key Conventions

### SSH Access
All commands use SSH alias `wailord` configured in `~/.ssh/config`. Example:
```bash
Host wailord
    HostName ip-address-of-your-lightsail-instance
    User ec2-user
    IdentityFile ~/.ssh/LightsailDefaultKey-ap-southeast-1.pem
```

Use `ssh wailord "command"` for remote commands and `scp file wailord:/path/` for file transfers.

### File Locations
- **Remote docker-compose**: `/home/ec2-user/docker/docker-compose.yml`
- **Remote environment file**: `/home/ec2-user/docker/.env` (renamed from .env.local)
- **Remote templates**: `/home/ec2-user/docker/etc/nginx/templates/`
- **Remote v2ray template**: `/home/ec2-user/docker/etc/v2ray/config.json.template`
- **Remote v2ray generated config**: `/home/ec2-user/docker/etc/v2ray/config.json`
- **Remote static files**: `/home/ec2-user/html/` (Astro build output)

### Template-Based Configuration
- Nginx uses `envsubst` for environment variable substitution
- Templates in `etc/nginx/templates/` use `${DOMAIN}` syntax
- Automatically rendered at container startup
- No manual docker volume editing required

**Template Files:**
- `default.conf.template` - Full nginx configuration with SSL
- `default.conf.init.template` - Simplified template for initial SSL certificate generation (HTTP only)

### V2Ray Configuration
- Template file `config.json` uses `${V2RAY_ID}` variable
- Upload template to `/home/ec2-user/docker/etc/v2ray/config.json.template`
- Generate on remote server: `ssh wailord "cd /home/ec2-user/docker && set -a && source .env && set +a && envsubst < etc/v2ray/config.json.template > etc/v2ray/config.json"`
- `set -a` automatically exports all variables, `set +a` restores normal behavior
- This avoids local environment variable issues

### Working Pattern for Nginx Config Updates
1. Update `etc/nginx/templates/default.conf.template` locally
2. `ssh wailord "mkdir -p /home/ec2-user/docker/etc/nginx/templates"`
3. `scp etc/nginx/templates/default.conf.template wailord:/home/ec2-user/docker/etc/nginx/templates/`
4. `ssh wailord "docker-compose ... restart nginx"`

### Working Pattern for V2Ray Config Updates
1. Update `etc/v2ray/config.json.template` locally (use `${V2RAY_ID}` variable)
2. `scp etc/v2ray/config.json.template wailord:/home/ec2-user/docker/etc/v2ray/config.json.template`
3. `ssh wailord "cd /home/ec2-user/docker && set -a && source .env && set +a && envsubst < etc/v2ray/config.json.template > etc/v2ray/config.json"`
4. `ssh wailord "docker-compose ... restart v2ray"`

### First-Time Setup Pattern
For initial deployment when SSL certificates don't exist:
1. `ssh wailord "mkdir -p /home/ec2-user/docker/etc/nginx/templates /home/ec2-user/docker/etc/v2ray /home/ec2-user/html"`
2. Upload docker-compose.yml and .env (renamed from .env.local): `scp .env.local wailord:/home/ec2-user/docker/.env`
3. Upload V2Ray template: `scp etc/v2ray/config.json wailord:/home/ec2-user/docker/etc/v2ray/config.json.template`
4. Generate V2Ray config: `ssh wailord "cd /home/ec2-user/docker && set -a && source .env && set +a && envsubst < etc/v2ray/config.json.template > etc/v2ray/config.json"`
5. Upload init template: `scp etc/nginx/templates/default.conf.init.template wailord:/home/ec2-user/docker/etc/nginx/templates/default.conf.template`
6. Start services: `ssh wailord "docker-compose ... up nginx certbot"`
7. Upload full template: `scp etc/nginx/templates/default.conf.template wailord:/home/ec2-user/docker/etc/nginx/templates/`
8. Restart nginx: `ssh wailord "docker-compose ... restart nginx"`

### Environment Variables
Located in `.env.local`:
- `EMAIL` - Let's Encrypt notifications
- `DOMAIN` - SSL certificate domain (used in nginx templates via `${DOMAIN}`)
- `V2RAY_ID` - V2Ray client UUID

## Commands Reference

See [README.md](README.md) for complete command documentation. Quick reference:

| Task | Command Pattern |
|------|-----------------|
| Start services | `ssh wailord "docker-compose ... up -d"` |
| Renew SSL | `ssh wailord "docker-compose ... up certbot"` |
| Update nginx | `ssh wailord "mkdir -p .../templates"` + `scp template wailord:/.../templates/` + `ssh wailord "docker-compose ... restart nginx"` |

## Architecture Summary

- **Nginx** (ports 80, 443) → Static files + V2Ray proxy
- **V2Ray** (port 11055) → vmess over websocket at `/tech`
- **Certbot** → Let's Encrypt SSL automation
- **Template system** → Environment variable substitution for DOMAIN

See [README.md](README.md) for detailed architecture diagrams and CloudWatch monitoring configuration.

## Deployment Target

AWS Lightsail instance in ap-southeast-1, timezone `Asia/Shanghai`.
