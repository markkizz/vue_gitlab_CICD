FROM node:10.18-alpine as builder
WORKDIR /app
COPY package*.json yarn.lock ./
RUN yarn install
COPY . .
RUN yarn build

FROM nginx as server
LABEL maintainer="markkizz"
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/version.json /app/dist/version.json
COPY --from=builder /app/nginx.conf /app/nginx.conf
RUN rm -rf /usr/share/nginx/html/* && \
    cp -r /app/dist/* /usr/share/nginx/html && \
    cp /app/nginx.conf  /etc/nginx/conf.d/default.conf && \
    rm -rf /home/nginx/* && \
    sed -i 's/\/var\/run\/nginx.pid/\/tmp\/nginx.pid/g' /etc/nginx/nginx.conf && \
    mkdir /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp && \
    chown -R nginx:nginx /var/cache/nginx /run
USER nginx
EXPOSE 8080
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
