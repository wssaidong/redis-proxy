use anyhow::{Context, Result};
use clap::Parser;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedisConfig {
    pub host: String,
    pub port: u16,
    #[serde(default)]
    pub user: String,
    #[serde(default)]
    pub password: String,
    #[serde(default)]
    pub ssl: bool,
}

impl Default for RedisConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 6379,
            user: String::new(),
            password: String::new(),
            ssl: false,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyConfig {
    pub listen: String,
}

impl Default for ProxyConfig {
    fn default() -> Self {
        Self {
            listen: "127.0.0.1:6379".to_string(),
        }
    }
}



#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Config {
    pub redis: RedisConfig,
    pub proxy: ProxyConfig,
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Args {
    /// Configuration file path
    #[arg(short, long)]
    pub config: Option<PathBuf>,

    /// Redis host address
    #[arg(long)]
    pub redis_host: Option<String>,

    /// Redis port
    #[arg(long)]
    pub redis_port: Option<u16>,

    /// Redis username
    #[arg(long)]
    pub redis_user: Option<String>,

    /// Redis password
    #[arg(long)]
    pub redis_password: Option<String>,

    /// Enable SSL for Redis connection
    #[arg(long)]
    pub redis_ssl: bool,

    /// Proxy listen address and port
    #[arg(long)]
    pub listen: Option<String>,
}

impl Config {
    pub fn load(args: Args) -> Result<Self> {
        let mut config = if let Some(config_path) = &args.config {
            let config_content = std::fs::read_to_string(config_path)
                .with_context(|| format!("Failed to read config file: {:?}", config_path))?;
            toml::from_str::<Config>(&config_content)
                .with_context(|| format!("Failed to parse config file: {:?}", config_path))?
        } else {
            Config::default()
        };

        // Override with command line arguments
        if let Some(host) = args.redis_host {
            config.redis.host = host;
        }
        if let Some(port) = args.redis_port {
            config.redis.port = port;
        }
        if let Some(user) = args.redis_user {
            config.redis.user = user;
        }
        if let Some(password) = args.redis_password {
            config.redis.password = password;
        }
        if args.redis_ssl {
            config.redis.ssl = true;
        }
        if let Some(listen) = args.listen {
            config.proxy.listen = listen;
        }

        Ok(config)
    }

    pub fn redis_address(&self) -> String {
        format!("{}:{}", self.redis.host, self.redis.port)
    }
}
