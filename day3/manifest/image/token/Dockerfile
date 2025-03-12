FROM alpine:latest

# ENV MYSQL_USER=<USERNAME>
# ENV MYSQL_PASSWORD=<PASSWORD>
# ENV MYSQL_HOST=<RDS_EP>
# ENV MYSQL_PORT=<PORT>
# ENV MYSQL_DBNAME=dev

WORKDIR /app
COPY ./token /app/token
RUN apk update && \
    apk add --no-cache libc6-compat libstdc++ libgcc curl openssl && \
    apk upgrade --no-cache busybox && \
    chmod +x /app/token && \
    adduser -D -H -s /bin/sh token
USER token
EXPOSE 8080

CMD ["/app/token"]