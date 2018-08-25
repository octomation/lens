## Docker

.PHONY: pull-umputun/nginx-le
pull-umputun/nginx-le:
	rm -rf docker/umputun/nginx-le
	git clone git@github.com:umputun/nginx-le.git docker/umputun/nginx-le
	( \
	  cd docker/umputun/nginx-le && \
	  echo 'umputun/nginx-le at revision' $$(git rev-parse HEAD) > metadata \
	)
	rm -rf docker/umputun/nginx-le/.git

## Nginx

.PHONY: pull-h5bp/server-configs-nginx
pull-h5bp/server-configs-nginx:
	rm -rf nginx/h5bp/server-configs-nginx
	git clone git@github.com:h5bp/server-configs-nginx.git nginx/h5bp/server-configs-nginx
	( \
	  cd nginx/h5bp/server-configs-nginx && \
	  echo 'h5bp/server-configs-nginx at revision' $$(git rev-parse HEAD) > metadata \
	)
	rm -rf nginx/h5bp/server-configs-nginx/.git
