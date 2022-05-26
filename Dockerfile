FROM openresty/openresty:1.19.9.1-focal

WORKDIR /

RUN apt-get update && apt-get --no-install-recommends -y install bc=1.07.1-2build1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    luarocks install lua-resty-http && \
    luarocks install hasher

# reload nginx every 6 hours (for reloading certificates)
ENV NGINX_ENTRYPOINT_RELOAD_EVERY_X_HOURS 6

# copy entrypoint scripts
COPY entrypoint /

# copy nginx configuration files
COPY nginx /etc/nginx/
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

ENTRYPOINT ["/docker-entrypoint.sh"]

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
