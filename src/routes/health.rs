use axum::extract::Extension;
use axum::http::StatusCode;
use axum::Json;
use bb8_redis::{redis, RedisConnectionManager};
use serde::Serialize;
use sqlx::PgPool;

pub async fn check(
    Extension(db): Extension<PgPool>,
    Extension(redis_pool): Extension<bb8::Pool<RedisConnectionManager>>,
) -> (StatusCode, Json<Deps>) {
    let db_status = get_db_status(db).await;
    let redis_status = get_redis_status(redis_pool).await;

    let status_code = match (db_status, redis_status) {
        (Status::Up, Status::Up) => StatusCode::OK,
        _ => StatusCode::SERVICE_UNAVAILABLE,
    };

    let health = Deps {
        db: db_status,
        redis: redis_status,
    };

    (status_code, Json(health))
}

async fn get_db_status(db: PgPool) -> Status {
    match sqlx::query!("SELECT 1 AS one").fetch_one(&db).await {
        Ok(_row) => Status::Up,
        Err(e) => {
            tracing::error!("database down: {e}");
            Status::Down
        }
    }
}

async fn get_redis_status(redis_pool: bb8::Pool<RedisConnectionManager>) -> Status {
    let mut redis_conn = match redis_pool.get().await {
        Ok(conn) => conn,
        Err(e) => {
            tracing::error!("failed to get redis connection: {e}");
            return Status::Down;
        }
    };

    let pong: String = match redis::cmd("PING").query_async(&mut *redis_conn).await {
        Ok(pong) => pong,
        Err(e) => {
            tracing::error!("failed to ping redis: {e}");
            return Status::Down;
        }
    };

    if pong != "PONG" {
        tracing::error!("unexpected redis pong: {pong}");
        return Status::Down;
    }

    Status::Up
}

#[derive(Serialize, Debug, Clone, Copy)]
#[serde(rename_all = "camelCase")]
pub struct Deps {
    pub db: Status,
    pub redis: Status,
}

#[derive(Serialize, Debug, Clone, Copy)]
#[serde(rename_all = "camelCase")]
pub enum Status {
    Up,
    Down,
}
