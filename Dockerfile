# Builder stage
FROM rust:latest AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime stage
FROM debian:stable-slim
WORKDIR /app
COPY --from=builder /app/target/release/deontevanterpool .

# Install CA certificates for SSL verification
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY Caddyfile /etc/caddy/Caddyfile

# Expose the application port
EXPOSE 4000

CMD ["./deontevanterpool"]

