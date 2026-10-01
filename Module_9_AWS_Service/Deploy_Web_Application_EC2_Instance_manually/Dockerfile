FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=nginx:nginx index.html styles.css /usr/share/nginx/html/

RUN nginx -t

EXPOSE 8080
