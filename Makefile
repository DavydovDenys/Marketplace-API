CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
# DOCKER_IMAGES_LIST := $(shell docker images --filter "label=PROJECT=IDION" --filter "dangling=false" --format "{{.Repository}}:{{.Tag}}")

define get_ip_address
	docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${1}
endef

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help build up start down destroy stop restart logs logs-app ps login-db login-app db-shell run clean prepare

help: ## This help.
				@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

build:	## Build Docker images
				docker compose -f docker-compose.yml build --force-rm \
					--build-arg RAILS_ENV=development \
					--build-arg UID=${CURRENT_UID} \
					--build-arg GID=${CURRENT_GID} $(c)

up:			## Run Docker containers
				docker compose -f docker-compose.yml up -d $(c)
				@echo "App IP address: $$($(call get_ip_address,api))"

start:	## Start Docker containers
				docker compose -f docker-compose.yml start $(c)
				@echo "App IP address: $$($(call get_ip_address,api))"

down:		## Stop and destroy Docker containers
				docker compose -f docker-compose.yml down $(c)

destroy:	## Remove Docker volumes
				docker compose -f docker-compose.yml down -v $(c)

stop:		## Stop Docker containers
				docker compose -f docker-compose.yml stop $(c)

restart:	stop up ## Restart Docker containers

logs:		## View logs of running Docker containers
				docker compose -f docker-compose.yml logs --tail=100 -f $(c)

#logs-app:	## View logs of Docker container with app
				docker compose -f docker-compose.yml logs --tail=100 -f integrator sidekiq

ps:			## View the list of running Docker containers
				docker compose -f docker-compose.yml ps

login-db:	## Log in to running Docker container with database
				docker compose -f docker-compose.yml exec database /bin/bash

login-app:	## Log in to running Docker container with app
				docker compose -f docker-compose.yml exec api /bin/bash

db-shell:	## Get access to database shell
				docker compose -f docker-compose.yml exec database psql -U api -d api_rails_development

run:	stop build up ## Run Local environment

clean: ## Delete docker images
				@if [ -n "${DOCKER_IMAGES_LIST}" ]; then\
					docker rmi ${DOCKER_IMAGES_LIST};\
					docker image prune --filter "label=PROJECT=PANTERA" --all --force;\
				fi
