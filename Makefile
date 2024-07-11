NO_COLOR=\033[0m
OK_COLOR=\033[32m

up:
	@echo "$(OK_COLOR)>>>>>>>>>>UP>>>>>>>>>>$(NO_COLOR)"
	@docker-compose pull
	@docker-compose up -d

down:
	@echo "$(OK_COLOR)>>>>>>>>>>DOWN>>>>>>>>>>$(NO_COLOR)"
	@docker-compose down

.PHONY: up down
