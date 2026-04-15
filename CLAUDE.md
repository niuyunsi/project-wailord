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
- **Remote environment file**: `/home/ec2-user/docker/.env.local`
- **Remote templates**: `/home/ec2-user/docker/etc/nginx/templates/`
- **Remote static files**: `/home/ec2-user/html/` (Astro build output)

### Template-Based Configuration
- Nginx uses `envsubst` for environment variable substitution
- Templates in `etc/nginx/templates/` use `${DOMAIN}` syntax
- Automatically rendered at container startup
- No manual docker volume editing required

**Template Files:**
- `default.conf.template` - Full nginx configuration with SSL
- `default.conf.init.template` - Simplified template for initial SSL certificate generation (HTTP only)

### Working Pattern for Nginx Config Updates
1. Update `etc/nginx/templates/default.conf.template` locally
2. `ssh wailord "mkdir -p /home/ec2-user/docker/etc/nginx/templates"`
3. `scp etc/nginx/templates/default.conf.template wailord:/home/ec2-user/docker/etc/nginx/templates/`
4. `ssh wailord "docker-compose ... restart nginx"`

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
