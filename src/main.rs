use anyhow::Result;
use clap::Parser;
use redis_proxy::{Config, RedisProxy};
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "redis_proxy=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Parse command line arguments
    let args = redis_proxy::config::Args::parse();

    // Load configuration
    let config = Config::load(args)?;

    info!("Starting Redis Proxy");
    info!("Configuration: {:?}", config);

    // Create and start proxy service
    let proxy = RedisProxy::new(config);
    proxy.start().await?;

    Ok(())
}
