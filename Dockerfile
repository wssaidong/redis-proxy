# Build stage
FROM rust:latest AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Copy source code
COPY src ./src

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder stage
COPY --from=builder /app/target/release/redis-proxy /app/redis-proxy

# Copy default config
COPY config.toml /app/config.toml

# Create non-root user
RUN useradd -r -s /bin/false redis-proxy

# Change ownership
RUN chown -R redis-proxy:redis-proxy /app

USER redis-proxy

EXPOSE 6379

ENTRYPOINT ["/app/redis-proxy"]
CMD ["--config", "/app/config.toml"]
