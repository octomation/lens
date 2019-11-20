FROM nginx:mainline-alpine

LABEL maintainer="Kamil Samigullin <kamil@samigullin.info>" \
      vendor="OctoLab"

ARG BASE

ENV TIME_ZONE   "UTC"
ENV LE_ENABLED  ""
ENV LE_EMAIL    ""
ENV DEV_ENABLED ""

COPY etc entrypoint.sh metadata /tmp/

RUN set -ex; \
    apk add --no-cache \
      bash \
      certbot \
      openssl \
      tzdata; \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default; \
    mv /tmp/nginx.conf /etc/nginx/nginx.conf; \
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.default; \
    mv /tmp/conf.d/default.conf /etc/nginx/conf.d/default.conf; \
    mv /tmp/h5bp /etc/nginx/h5bp; \
    mkdir -p /etc/nginx/sites-available; \
    mv /tmp/entrypoint.sh /entrypoint.sh \
      && chmod +x /entrypoint.sh; \
    mv /tmp/metadata /metadata; \
    sed -i "s/NGINX_BASE/${BASE}/" /metadata; \
    sed -i "s/NGINX_VERSION/$(nginx -v 2>&1 | awk '{print $3}' | cut -d'/' -f2)/" /metadata; \
    sed -i "s/CERTBOT_VERSION/$(certbot --version 2>&1 | awk '{print $2}')/" /metadata; \
    rm -rf /tmp/* /var/cache/apk/*

VOLUME [ "/etc/nginx/ssl", "/etc/letsencrypt" ]

WORKDIR "/etc/nginx"

ENTRYPOINT [ "/entrypoint.sh" ]
