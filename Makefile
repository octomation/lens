PROJECT  = lens

_branch  = mainline
_alpine  = $(shell docker images | grep '^nginx\s\+$(_branch)-alpine\s\+' | awk '{print $$3}')
_debian  = $(shell docker images | grep '^nginx\s\+$(_branch)\s\+' | awk '{print $$3}')
_compose = docker-compose -p $(PROJECT)

.DEFAULT_GOAL = process

.PHONY: mainline
mainline:
	$(eval _branch = mainline)
	@echo $(_branch)

.PHONY: stable
stable:
	$(eval _branch = stable)
	@echo $(_branch)


.PHONY: process
process: cleanup build publish


.PHONY: cleanup
cleanup:
	docker images --all \
	| grep '^kamilsk\/nginx\s\+' \
	| awk '{print $$3}' \
	| xargs docker rmi -f &>/dev/null || true


.PHONY: build-parallel
build-parallel:
	semaphore create
	semaphore add -- make build-alpine
	semaphore add -- make build-debian
	semaphore wait

.PHONY: build
build: build-alpine build-debian

.PHONY: build-alpine
build-alpine:
	docker build -f $(PWD)/$(_branch)/alpine/Dockerfile \
	             -t kamilsk/nginx:alpine \
	             -t kamilsk/nginx:1.x-alpine \
	             -t kamilsk/nginx:1.x \
	             -t kamilsk/nginx:latest \
	             -t quay.io/kamilsk/nginx:alpine \
	             -t quay.io/kamilsk/nginx:1.x-alpine \
	             -t quay.io/kamilsk/nginx:1.x \
	             -t quay.io/kamilsk/nginx:latest \
	             --force-rm --no-cache --pull --rm \
	             --build-arg BASE=$(_alpine) \
	             $(PWD)/context

.PHONY: build-debian
build-debian:
	docker build -f $(PWD)/$(_branch)/debian/Dockerfile \
	             -t kamilsk/nginx:debian \
	             -t kamilsk/nginx:1.x-debian \
	             -t quay.io/kamilsk/nginx:debian \
	             -t quay.io/kamilsk/nginx:1.x-debian \
	             --force-rm --no-cache --pull --rm \
	             --build-arg BASE=$(_debian) \
	             $(PWD)/context


.PHONY: publish
publish: publish-alpine publish-debian

.PHONY: publish-alpine
publish-alpine:
	docker push kamilsk/nginx:alpine
	docker push kamilsk/nginx:1.x-alpine
	docker push kamilsk/nginx:1.x
	docker push kamilsk/nginx:latest
	docker push quay.io/kamilsk/nginx:alpine
	docker push quay.io/kamilsk/nginx:1.x-alpine
	docker push quay.io/kamilsk/nginx:1.x
	docker push quay.io/kamilsk/nginx:latest

.PHONY: publish-debian
publish-debian:
	docker push kamilsk/nginx:debian
	docker push kamilsk/nginx:1.x-debian
	docker push quay.io/kamilsk/nginx:debian
	docker push quay.io/kamilsk/nginx:1.x-debian


# TODO:fix use variable
.PHONY: pull-upstream
pull-upstream:
	docker pull nginx:mainline-alpine
	docker pull nginx:mainline


.PHONY: in-alpine
in-alpine:
	docker run --rm -it --entrypoint /bin/sh kamilsk/nginx:alpine

.PHONY: in-debian
in-debian:
	docker run --rm -it --entrypoint /bin/sh kamilsk/nginx:debian


.PHONY: refresh
refresh: cleanup refresh-alpine refresh-debian

.PHONY: refresh-alpine
refresh-alpine:
	docker pull kamilsk/nginx:alpine

.PHONY: refresh-debian
refresh-debian:
	docker pull kamilsk/nginx:debian


# TODO:fix invalid paths
.PHONY: nginx/mainline-alpine.conf
nginx/mainline-alpine.conf:
	rm -rf ./nginx/default/mainline-alpine/*
	docker run --rm -d --name=nginx-mainline-alpine nginx:mainline-alpine
	docker exec nginx-mainline-alpine rm -rf /etc/nginx/modules
	docker cp nginx-mainline-alpine:/etc/nginx ./nginx/default/mainline-alpine/
	mv ./nginx/default/mainline-alpine/nginx/* ./nginx/default/mainline-alpine/
	rm -rf ./nginx/default/mainline-alpine/nginx
	docker stop nginx-mainline-alpine
	echo 'nginx:mainline-alpine at revision' $(_alpine) > ./nginx/default/mainline-alpine/metadata

# TODO:fix invalid paths
.PHONY: nginx/mainline.conf
nginx/mainline.conf:
	rm -rf ./nginx/default/mainline/*
	docker run --rm -d --name=nginx-mainline nginx:mainline
	docker cp nginx-mainline:/etc/nginx ./nginx/default/mainline/
	mv ./nginx/default/mainline/nginx/* ./nginx/default/mainline/
	rm -rf ./nginx/default/mainline/nginx
	docker stop nginx-mainline
	echo 'nginx:mainline at revision' $(_debian) > ./nginx/default/mainline/metadata


# TODO:fix use variable
.PHONY: validate
validate:
	docker run --rm -it \
	           -h nginx \
	           -v $(PWD)/context/etc/h5bp:/etc/nginx/h5bp \
	           -v $(PWD)/context/etc/conf.d:/etc/nginx/conf.d \
	           -v $(PWD)/context/etc/nginx.conf:/etc/nginx/nginx.conf \
	           -w /etc/nginx \
	           nginx:mainline-alpine nginx -t


.PHONY: up
up:
	$(_compose) up -d --build

.PHONY: status
status:
	$(_compose) ps

.PHONY: restart
restart:
	$(_compose) stop proxy
	$(_compose) rm -f
	$(_compose) up -d proxy

.PHONY: down
down:
	$(_compose) down --rmi local --volumes --remove-orphans
