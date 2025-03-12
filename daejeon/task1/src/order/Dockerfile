FROM alpine:latest

WORKDIR /app
COPY ./order /app/order
RUN apk update && \
    apk add --no-cache libc6-compat libstdc++ libgcc curl openssl && \
    apk upgrade --no-cache busybox && \
    chmod +x /app/order
EXPOSE 8080

CMD ["/app/order"]