FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install --silent
COPY . .
RUN npm run build

FROM nginx:alpine
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
    location /health { return 200 "healthy"; add_header Content-Type text/plain; } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
