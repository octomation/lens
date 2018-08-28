NGINX_ALPINE  := $(shell docker images | grep '^nginx\s\+mainline-alpine\s\+' | awk '{print $$3}')
NGINX_DEBIAN  := $(shell docker images | grep '^nginx\s\+mainline\s\+' | awk '{print $$3}')
NGINX_COMPOSE := docker-compose -f nginx/docker-compose.yml -p experiments


.PHONY: pull-nginx-upstream
pull-nginx-upstream:
	docker pull nginx:mainline-alpine
	docker pull nginx:mainline


.PHONY: build-nginx-parallel
build-nginx-parallel:
	semaphore create
	semaphore add -- make build-nginx-alpine
	semaphore add -- make build-nginx-debian
	semaphore wait

.PHONY: build-nginx
build-nginx: build-nginx-alpine build-nginx-debian

.PHONY: build-nginx-alpine
build-nginx-alpine:
	docker build -f $(PWD)/nginx/mainline-alpine.Dockerfile \
	             -t kamilsk/nginx:alpine \
	             -t kamilsk/nginx:1.x-alpine \
	             -t kamilsk/nginx:1.x \
	             -t kamilsk/nginx:latest \
	             -t quay.io/kamilsk/nginx:alpine \
	             -t quay.io/kamilsk/nginx:1.x-alpine \
	             -t quay.io/kamilsk/nginx:1.x \
	             -t quay.io/kamilsk/nginx:latest \
	             --force-rm --no-cache --pull --rm \
	             --build-arg BASE=$(NGINX_ALPINE) \
	             $(PWD)/nginx/context

.PHONY: build-nginx-debian
build-nginx-debian:
	docker build -f $(PWD)/nginx/mainline-debian.Dockerfile \
	             -t kamilsk/nginx:debian \
	             -t kamilsk/nginx:1.x-debian \
	             -t quay.io/kamilsk/nginx:debian \
	             -t quay.io/kamilsk/nginx:1.x-debian \
	             --force-rm --no-cache --pull --rm \
	             --build-arg BASE=$(NGINX_DEBIAN) \
	             $(PWD)/nginx/context


.PHONY: clean-invalid-nginx
clean-invalid-nginx:
	docker images --all \
	| grep '^kamilsk\/nginx\s\+' \
	| awk '{print $$2 "\t" $$3}' \
	| grep '^<none>\s\+' \
	| awk '{print $$2}' \
	| xargs docker rmi -f &>/dev/null || true


.PHONY: drop-nginx
drop-nginx:
	docker images --all \
	| grep '^kamilsk\/nginx\s\+' \
	| awk '{print $$3}' \
	| xargs docker rmi -f &>/dev/null || true


.PHONY: in-nginx-alpine
in-nginx-alpine:
	docker run --rm -it --entrypoint /bin/sh kamilsk/nginx:alpine

.PHONY: in-nginx-debian
in-nginx-debian:
	docker run --rm -it --entrypoint /bin/sh kamilsk/nginx:debian


.PHONY: process-nginx
process-nginx: drop-nginx build-nginx publish-nginx


.PHONY: publish-nginx
publish-nginx: publish-nginx-alpine publish-nginx-debian

.PHONY: publish-nginx-alpine
publish-nginx-alpine:
	docker push kamilsk/nginx:alpine
	docker push kamilsk/nginx:1.x-alpine
	docker push kamilsk/nginx:1.x
	docker push kamilsk/nginx:latest
	docker push quay.io/kamilsk/nginx:alpine
	docker push quay.io/kamilsk/nginx:1.x-alpine
	docker push quay.io/kamilsk/nginx:1.x
	docker push quay.io/kamilsk/nginx:latest

.PHONY: publish-nginx-debian
publish-nginx-debian:
	docker push kamilsk/nginx:debian
	docker push kamilsk/nginx:1.x-debian
	docker push quay.io/kamilsk/nginx:debian
	docker push quay.io/kamilsk/nginx:1.x-debian


.PHONY: refresh-nginx
refresh-nginx: drop-nginx refresh-nginx-alpine refresh-nginx-debian

.PHONY: refresh-nginx-alpine
refresh-nginx-alpine:
	docker pull kamilsk/nginx:alpine

.PHONY: refresh-nginx-debian
refresh-nginx-debian:
	docker pull kamilsk/nginx:debian


.PHONY: nginx/mainline-alpine.conf
nginx/mainline-alpine.conf:
	rm -rf ./nginx/default/mainline-alpine/*
	docker run --rm -d --name=nginx-mainline-alpine nginx:mainline-alpine
	docker exec nginx-mainline-alpine rm -rf /etc/nginx/modules
	docker cp nginx-mainline-alpine:/etc/nginx ./nginx/default/mainline-alpine/
	mv ./nginx/default/mainline-alpine/nginx/* ./nginx/default/mainline-alpine/
	rm -rf ./nginx/default/mainline-alpine/nginx
	docker stop nginx-mainline-alpine
	echo 'nginx:mainline-alpine at revision' $(NGINX_ALPINE) > ./nginx/default/mainline-alpine/metadata

.PHONY: nginx/mainline.conf
nginx/mainline.conf:
	rm -rf ./nginx/default/mainline/*
	docker run --rm -d --name=nginx-mainline nginx:mainline
	docker cp nginx-mainline:/etc/nginx ./nginx/default/mainline/
	mv ./nginx/default/mainline/nginx/* ./nginx/default/mainline/
	rm -rf ./nginx/default/mainline/nginx
	docker stop nginx-mainline
	echo 'nginx:mainline at revision' $(NGINX_DEBIAN) > ./nginx/default/mainline/metadata


.PHONY: validate-nginx
validate-nginx:
	docker run --rm -it \
	           -h nginx \
	           -v $(PWD)/nginx/context/etc/h5bp:/etc/nginx/h5bp \
	           -v $(PWD)/nginx/context/etc/conf.d:/etc/nginx/conf.d \
	           -v $(PWD)/nginx/context/etc/nginx.conf:/etc/nginx/nginx.conf \
	           -w /etc/nginx \
	           nginx:mainline-alpine nginx -t


.PHONY: nginx-up
nginx-up:
	$(NGINX_COMPOSE) up -d --build

.PHONY: nginx-status
nginx-status:
	$(NGINX_COMPOSE) ps

.PHONY: nginx-restart
nginx-restart:
	$(NGINX_COMPOSE) stop proxy
	$(NGINX_COMPOSE) rm -f
	$(NGINX_COMPOSE) up -d proxy

.PHONY: nginx-down
nginx-down:
	$(NGINX_COMPOSE) down --rmi local --volumes --remove-orphans
