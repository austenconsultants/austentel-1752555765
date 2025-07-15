FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install --silent
COPY . .
RUN npm run build

FROM nginx:alpine

RUN apk add --no-cache curl

COPY --from=builder /app/build /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    add_header X-Frame-Options "SAMEORIGIN"; \
    add_header X-Content-Type-Options "nosniff"; \
    gzip on; \
    gzip_types text/plain text/css application/json application/javascript; \
    location / { try_files $uri $uri/ /index.html; } \
    location /health { \
        access_log off; \
        return 200 "{\"status\":\"healthy\",\"hosting\":\"app_service\"}"; \
        add_header Content-Type application/json; \
    } \
}' > /etc/nginx/conf.d/default.conf

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
