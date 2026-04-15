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
- **Remote docker volumes**: `/var/lib/docker/volumes/docker_nginx-conf/_data/`
- **Remote temp directory**: `/home/ec2-user/tmp/` (for copying files before docker volume)
- **Remote static files**: `/home/ec2-user/html/` (Astro build output)
- **Remote docker-compose**: `/home/ec2-user/docker/docker-compose.yml`

### Working Pattern for Nginx Config Updates
1. `scp config file wailord:/home/ec2-user/tmp/`
2. `ssh wailord "sudo cp /home/ec2-user/tmp/file /var/lib/docker/volumes/..."`
3. `ssh wailord "docker-compose ... exec nginx nginx -s reload"`

### Environment Variables
Located in `.env.local`:
- `EMAIL` - Let's Encrypt notifications
- `DOMAIN` - SSL certificate domain
- `V2RAY_ID` - V2Ray client UUID

## Commands Reference

See [README.md](README.md) for complete command documentation. Quick reference:

| Task | Command Pattern |
|------|-----------------|
| Start services | `ssh wailord "docker-compose ... up -d"` |
| Renew SSL | `ssh wailord "docker-compose ... up certbot"` |
| Update nginx | `scp config wailord:/tmp/` + `ssh wailord "sudo cp ..."` |
| Deploy site | `scp -r dist/* wailord:/home/ec2-user/html/` |

## Architecture Summary

- **Nginx** (ports 80, 443) → Static files + V2Ray proxy
- **V2Ray** (port 11055) → vmess over websocket at `/tech`
- **Certbot** → Let's Encrypt SSL automation

See [README.md](README.md) for detailed architecture diagrams and CloudWatch monitoring configuration.

## Deployment Target

AWS Lightsail instance in ap-southeast-1, timezone `Asia/Shanghai`.
