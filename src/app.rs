use crate::routes;
use crate::{schema, settings::Settings};

use anyhow::Context;
use axum::routing::IntoMakeService;
use axum::Router;
use axum::Server;
use bb8_redis::RedisConnectionManager;
use hyper::server::conn::AddrIncoming;
use secrecy::ExposeSecret;
use std::net::{SocketAddr, TcpListener};

type AppServer = Server<AddrIncoming, IntoMakeService<Router>>;

pub struct App {
    port: u16,
    server: AppServer,
}

impl App {
    pub async fn build(settings: Settings) -> anyhow::Result<Self> {
        let address = format!("{}:{}", settings.app_host, settings.app_port);

        let listener = TcpListener::bind(&address)?;
        let addr = listener.local_addr()?;
        let port = addr.port();

        let redis_url: &str = settings.redis_url.expose_secret();
        let redis_manager =
            RedisConnectionManager::new(redis_url).context("failed to create redis connection")?;
        let redis = bb8::Pool::builder()
            .build(redis_manager)
            .await
            .context("failed to create redis pool")?;

        let schema = schema::make(redis.clone());
        let router = routes::make_router(schema, redis, settings)?;
        let server = axum::Server::from_tcp(listener)?.serve(router.into_make_service());

        Ok(Self { port, server })
    }

    pub async fn run(self) -> hyper::Result<()> {
        self.server.await
    }

    pub fn port(&self) -> u16 {
        self.port
    }

    pub fn address(&self) -> SocketAddr {
        self.server.local_addr()
    }
}