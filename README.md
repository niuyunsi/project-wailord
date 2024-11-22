```
docker-compose up -d

docker-compose -f ./docker-compose.yaml up certbot

docker-compose -f ./docker-compose.yaml exec nginx nginx -s reload
```
