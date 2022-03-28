use axum::extract::Extension;
use axum::http::StatusCode;
use axum::Json;
use bb8_redis::{redis, RedisConnectionManager};
use serde::Serialize;

pub async fn check(
    Extension(redis_pool): Extension<bb8::Pool<RedisConnectionManager>>,
) -> (StatusCode, Json<Deps>) {
    let redis_status = get_redis_status(redis_pool).await;

    let status_code = match redis_status {
        Status::Up => StatusCode::OK,
        _ => StatusCode::SERVICE_UNAVAILABLE,
    };

    let health = Deps {
        redis: redis_status,
    };

    (status_code, Json(health))
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
    pub redis: Status,
}

#[derive(Serialize, Debug, Clone, Copy)]
#[serde(rename_all = "camelCase")]
pub enum Status {
    Up,
    Down,
}
