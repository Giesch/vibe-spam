use crate::schema;
use crate::settings::Settings;

use axum::extract::Extension;
use axum::routing::{get, post};
use axum::Router;
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use schema::VibeSpam;
use secrecy::ExposeSecret;
use sqlx::PgPool;
use std::sync::Arc;
use tower_cookies::{CookieManagerLayer, Key};
use tower_http::trace::TraceLayer;

mod cors;
mod graphql;
mod health;
mod static_files;

pub fn make_router(
    schema: VibeSpam,
    db: PgPool,
    redis: Pool<RedisConnectionManager>,
    settings: Settings,
) -> anyhow::Result<Router> {
    let assets = static_files::list_assets_dir(&settings.dist)?;
    let cookie_key = Key::from(settings.app_signing_secret.expose_secret().as_bytes());

    let router = Router::new()
        .route("/", get(static_files::index_html))
        .nest("/assets", static_files::assets(&settings.dist))
        .route("/api/health", get(health::check))
        .route("/api/flags", get(static_files::get_flags))
        .route(graphql::ROUTE, get(graphql::playground))
        .route(graphql::ROUTE, post(graphql::handler))
        .fallback(get(static_files::index_html))
        .layer(cors::layer())
        .layer(TraceLayer::new_for_http())
        .layer(Extension(schema))
        .layer(Extension(db))
        .layer(Extension(redis))
        .layer(Extension(Arc::new(settings)))
        .layer(Extension(Arc::new(assets)))
        .layer(Extension(Arc::new(cookie_key)))
        .layer(CookieManagerLayer::new());

    Ok(router)
}
