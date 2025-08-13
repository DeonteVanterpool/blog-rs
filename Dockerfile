 # Builder stage
FROM rust:latest AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime stage
FROM debian:stable-slim
WORKDIR /app
COPY --from=builder /app/target/release/blog-rs .

# Install CA certificates for SSL verification
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*


# Expose the application port
EXPOSE 4000

CMD ["./blog-rs"]

