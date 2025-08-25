use crate::config::Config;
use anyhow::{Context, Result};
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tracing::{error, info};

pub struct RedisProxy {
    config: Arc<Config>,
}

impl RedisProxy {
    pub fn new(config: Config) -> Self {
        Self {
            config: Arc::new(config),
        }
    }

    pub async fn start(&self) -> Result<()> {
        let listener = TcpListener::bind(&self.config.proxy.listen)
            .await
            .with_context(|| format!("Failed to bind to {}", self.config.proxy.listen))?;

        info!("Redis proxy listening on {}", self.config.proxy.listen);
        info!("Forwarding to Redis at {}", self.config.redis_address());

        loop {
            match listener.accept().await {
                Ok((client_stream, client_addr)) => {
                    info!("New client connection from {}", client_addr);
                    let config = Arc::clone(&self.config);
                    
                    tokio::spawn(async move {
                        if let Err(e) = handle_client(client_stream, config).await {
                            error!("Error handling client {}: {}", client_addr, e);
                        }
                    });
                }
                Err(e) => {
                    error!("Failed to accept connection: {}", e);
                }
            }
        }
    }
}

async fn handle_client(mut client_stream: TcpStream, config: Arc<Config>) -> Result<()> {
    // Connect to Redis server
    let mut redis_stream = connect_to_redis(&config).await?;

    // Handle authentication if credentials are provided
    if !config.redis.password.is_empty() {
        authenticate_redis(&mut redis_stream, &config).await?;
    }

    // Start bidirectional forwarding
    let (mut client_read, mut client_write) = client_stream.split();
    let (mut redis_read, mut redis_write) = redis_stream.split();

    let client_to_redis = async {
        let mut buffer = vec![0u8; 8192];
        loop {
            match client_read.read(&mut buffer).await {
                Ok(0) => break, // Client disconnected
                Ok(n) => {
                    if let Err(e) = redis_write.write_all(&buffer[..n]).await {
                        error!("Failed to write to Redis: {}", e);
                        break;
                    }
                }
                Err(e) => {
                    error!("Failed to read from client: {}", e);
                    break;
                }
            }
        }
    };

    let redis_to_client = async {
        let mut buffer = vec![0u8; 8192];
        loop {
            match redis_read.read(&mut buffer).await {
                Ok(0) => break, // Redis disconnected
                Ok(n) => {
                    if let Err(e) = client_write.write_all(&buffer[..n]).await {
                        error!("Failed to write to client: {}", e);
                        break;
                    }
                }
                Err(e) => {
                    error!("Failed to read from Redis: {}", e);
                    break;
                }
            }
        }
    };

    // Run both forwarding tasks concurrently
    tokio::select! {
        _ = client_to_redis => {},
        _ = redis_to_client => {},
    }

    info!("Client connection closed");
    Ok(())
}

async fn connect_to_redis(config: &Config) -> Result<TcpStream> {
    let redis_addr = config.redis_address();
    
    TcpStream::connect(&redis_addr)
        .await
        .with_context(|| format!("Failed to connect to Redis at {}", redis_addr))
}

async fn authenticate_redis(redis_stream: &mut TcpStream, config: &Config) -> Result<()> {
    let auth_cmd = if config.redis.user.is_empty() {
        format!("*2\r\n$4\r\nAUTH\r\n${}\r\n{}\r\n", 
                config.redis.password.len(), config.redis.password)
    } else {
        format!("*3\r\n$4\r\nAUTH\r\n${}\r\n{}\r\n${}\r\n{}\r\n",
                config.redis.user.len(), config.redis.user,
                config.redis.password.len(), config.redis.password)
    };

    redis_stream.write_all(auth_cmd.as_bytes()).await
        .context("Failed to send AUTH command")?;

    // Read response
    let mut buffer = vec![0u8; 1024];
    let n = redis_stream.read(&mut buffer).await
        .context("Failed to read AUTH response")?;
    
    let response = String::from_utf8_lossy(&buffer[..n]);
    if !response.starts_with("+OK") {
        return Err(anyhow::anyhow!("Redis authentication failed: {}", response));
    }

    info!("Successfully authenticated with Redis");
    Ok(())
}
