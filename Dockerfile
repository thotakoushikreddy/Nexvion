FROM nginx:alpine

LABEL maintainer="Kowshik Reddy Thota"
LABEL app="Nexvion E-Commerce"

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /usr/share/nginx/html

COPY --chown=nginx:nginx . .

RUN mkdir -p /tmp/client_temp \
             /tmp/proxy_temp \
             /tmp/fastcgi_temp \
             /tmp/uwsgi_temp \
             /tmp/scgi_temp \
    && chown -R nginx:nginx /tmp/client_temp \
                           /tmp/proxy_temp \
                           /tmp/fastcgi_temp \
                           /tmp/uwsgi_temp \
                           /tmp/scgi_temp \
    && chmod -R 755 /usr/share/nginx/html

EXPOSE 8080

USER nginx

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
