# README

## First time setup
```
sudo scp default.conf.init /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf

docker-compose --env-file .env.local up nginx certbot
```

## Subsequent runs
```
docker-compose --env-file .env.local up -d
```

## Renew SSL Certificate
```
docker-compose -f ./docker-compose.yaml up certbot
docker-compose -f ./docker-compose.yaml exec nginx nginx -s reload
```

## Useful Commands
```
sudo scp default.conf /var/lib/docker/volumes/docker_nginx-conf/_data/default.conf

scp -i LightsailDefaultKey-ap-southeast-1.pem etc/nginx/conf.d/default.conf ec2-user@54.169.124.85:/home/ec2-user/docker
```
