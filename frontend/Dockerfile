FROM ghcr.io/cirruslabs/flutter:3.22.2 AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

RUN flutter build web \
    --release \
    --dart-define=API_URL=/api/v1 \
    --web-renderer html \
    --base-href /

# Servir com Nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx-web.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
