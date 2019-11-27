FROM nginx:mainline-alpine

LABEL maintainer="Kamil Samigullin <kamil@samigullin.info>" \
      vendor="OctoLab"

ARG BASE

COPY . /tmp/

RUN set -ex; \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default; \
    cp -r /tmp/etc/* /etc/nginx/; \
    mkdir -p /etc/nginx/sites-available; \
    mv /tmp/entrypoint.sh /entrypoint.sh \
      && chmod +x /entrypoint.sh; \
    mv /tmp/metadata /metadata; \
    sed -i "s/NGINX_BASE/${BASE}/" /metadata; \
    sed -i "s/NGINX_VERSION/$(nginx -v 2>&1 | awk '{print $3}' | cut -d'/' -f2)/" /metadata; \
    sed -i "s/CERTBOT_VERSION/$(certbot --version 2>&1 | awk '{print $2}')/" /metadata; \
    rm -rf /tmp/* /var/cache/apk/*; \
    apk add --no-cache \
      bash \
      certbot \
      openssl \
      tzdata

ENV TIME_ZONE="UTC" \
    LE_ENABLED="" \
    LE_EMAIL="" \
    DEV_ENABLED=""

ENTRYPOINT [ "/entrypoint.sh" ]

VOLUME [ "/etc/nginx/ssl", "/etc/letsencrypt" ]

WORKDIR "/etc/nginx"
