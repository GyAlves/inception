COMPOSE_FILE = srcs/docker-compose.yml

all:
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down

re: down all

clean:
	docker compose -f $(COMPOSE_FILE) down -v --rmi all --remove-orphans

.PHONY: all down re clean
