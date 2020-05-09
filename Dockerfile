FROM alpine:3.11

MAINTAINER Revin Roman <roman@rmrevin.com>

# original code https://github.com/nginxinc/docker-nginx/blob/70e44865208627c5ada57242b46920205603c096/stable/alpine/Dockerfile
# modified by Revin Roman

ENV NGINX_VERSION 1.18.0
ENV PSM_VERSION 0.5.4

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apkArch="$(cat /etc/apk/arch)" \
    && tempDir="$(mktemp -d)" && cd $tempDir \
    && mkdir -p $tempDir/nginx-psm \
    && nginxConfig=" \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-ipv6 \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_v2_module \
        --with-http_image_filter_module \
        --add-module=$tempDir/nginx-psm " \
    && mkdir -p /etc/nginx \
    && mkdir -p /var/log/nginx/ \
    && mkdir -p /var/cache/nginx/client_temp \
    && mkdir -p /var/cache/nginx/proxy_temp \
    && mkdir -p /var/cache/nginx/fastcgi_temp \
    && mkdir -p /var/cache/nginx/uwsgi_temp \
    && mkdir -p /var/cache/nginx/scgi_temp \
    && chown -R nginx:nginx /etc/nginx /var/log/nginx/ /var/cache/nginx/ \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        perl-dev \
        libedit-dev \
        mercurial \
        bash \
        alpine-sdk \
        findutils \
###    && case "$apkArch" in \
###        x86_64) \
#### arches officially built by upstream
###            set -x \
###            && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
###            && apk add --no-cache --virtual .cert-deps \
###                openssl \
###            && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
###            && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
###                echo "key verification succeeded!"; \
###                mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
###            else \
###                echo "key verification failed!"; \
###                exit 1; \
###            fi \
###            && apk del .cert-deps \
###            && apk add -X "https://nginx.org/packages/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
###            ;; \
###        *) \
#### we're on an architecture upstream doesn't officially build for
#### let's build binaries from the published packaging sources
###            set -x \
###            && chown nobody:nobody $tempDir \
###            && su nobody -s /bin/sh -c " \
###                export HOME=${tempDir} \
###                && cd ${tempDir} \
###                && hg clone https://hg.nginx.org/pkg-oss \
###                && cd pkg-oss \
###                && hg up -r 474 \
###                && cd alpine \
###                && configure ${nginxConfig} \
###                && make all \
###                && apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk \
###                && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz \
###                " \
###            && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/ \
###            && apk del .build-deps \
###            && apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages \
###            ;; \
###    esac \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
    && wget "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" \
    && wget "https://github.com/wandenberg/nginx-push-stream-module/archive/$PSM_VERSION.tar.gz" \
    && tar -xof nginx-$NGINX_VERSION.tar.gz -C $tempDir --strip-components=1 \
    && tar -xof $PSM_VERSION.tar.gz -C "$tempDir/nginx-psm" --strip-components=1 \
    && ./configure $nginxConfig && make -j2 && make install && make clean \
    && if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi \
    #&& if [ -n "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi \
    #&& if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
    && apk add --no-cache curl ca-certificates vim tzdata \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
