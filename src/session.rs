use anyhow::Context;
use axum::async_trait;
use axum::extract::{FromRequest, RequestParts};
use axum::http::StatusCode;
use bb8::PooledConnection;
use bb8_redis::redis::AsyncCommands;
use bb8_redis::RedisConnectionManager;
use cookie::SameSite;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tower_cookies::{Cookie, Cookies, Key};
use uuid::Uuid;

/// The name of the session id cookie
const SESSION_ID: &str = "session-id";

pub struct Session {
    data: Data,
    #[allow(dead_code)] // this is necessary for non-anonymous sessions
    manager: Manager,
}

impl std::fmt::Debug for Session {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Session").field("data", &self.data).finish()
    }
}

impl Session {
    fn new(data: Data, manager: Manager) -> Self {
        Self { data, manager }
    }

    pub fn data(&self) -> &Data {
        &self.data
    }
}

#[async_trait]
impl<B> FromRequest<B> for Session
where
    B: Send,
{
    type Rejection = StatusCode;

    async fn from_request(req: &mut RequestParts<B>) -> Result<Self, Self::Rejection> {
        let manager = Manager::from_request(req).await?;

        let cookie_session_id = manager.cookie_session_id().map_err(|e| {
            tracing::error!("failed to parse session id: {e}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        if let Some(session_id) = cookie_session_id {
            let data = manager.fetch_session(session_id).await.map_err(|e| {
                tracing::error!("failed to fetch session: {e}");
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

            if let Some(data) = data {
                return Ok(Session::new(data, manager));
            } else {
                tracing::info!("session expired, old id: {session_id}");
            }
        }

        let data = manager.create_anonymous_session().await.map_err(|e| {
            tracing::error!("failed to create anonymous session: {e}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        Ok(Session::new(data, manager))
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Data {
    pub session_id: Uuid,
}

impl Data {
    fn anonymous(session_id: Uuid) -> Self {
        Self { session_id }
    }
}

struct Manager {
    cookies: Cookies,
    key: Arc<Key>,
    redis_pool: bb8::Pool<RedisConnectionManager>,
}

impl std::fmt::Debug for Manager {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Manager")
            .field("cookies", &self.cookies)
            .finish()
    }
}

impl Manager {
    async fn create_anonymous_session(&self) -> anyhow::Result<Data> {
        let mut redis = self
            .redis_pool
            .get()
            .await
            .context("failed to check out redis connection from pool")?;

        let session_id = Uuid::new_v4();
        let data = Data::anonymous(session_id);

        self.save_session(&mut redis, session_id, data).await
    }

    async fn fetch_session(&self, session_id: Uuid) -> anyhow::Result<Option<Data>> {
        let mut redis = self
            .redis_pool
            .get()
            .await
            .context("failed to check out redis connection from pool")?;

        let session_data: Option<String> = redis
            .get(session_id.to_string())
            .await
            .context("failed to get session data from redis")?;

        let session_data = match session_data {
            Some(data) => data,
            None => return Ok(None),
        };

        let session_data: Data =
            serde_json::from_str(&session_data).context("failed to parse session data")?;

        Ok(Some(session_data))
    }

    fn cookie_session_id(&self) -> anyhow::Result<Option<Uuid>> {
        let session_id = self
            .cookies
            .private(&self.key)
            .get(SESSION_ID)
            .map(|cookie| cookie.value().to_string());
        let session_id = match session_id {
            Some(id) => id,
            None => return Ok(None),
        };

        let session_id: Uuid = session_id.parse().context("failed to parse uuid")?;

        Ok(Some(session_id))
    }

    async fn save_session<'a>(
        &self,
        redis: &mut PooledConnection<'a, RedisConnectionManager>,
        session_id: Uuid,
        data: Data,
    ) -> anyhow::Result<Data> {
        let serialized_data =
            serde_json::to_string(&data).context("failed to serialize session")?;

        redis
            .set(session_id.to_string(), serialized_data)
            .await
            .context("failed to set new session")?;

        self.cookies
            .private(&self.key)
            .add(session_cookie(session_id));

        Ok(data)
    }
}

fn session_cookie(session_id: Uuid) -> Cookie<'static> {
    Cookie::build(SESSION_ID, session_id.to_string())
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .max_age(cookie::time::Duration::days(14))
        .finish()
}

#[async_trait]
impl<B> FromRequest<B> for Manager
where
    B: Send,
{
    type Rejection = StatusCode;

    async fn from_request(req: &mut RequestParts<B>) -> Result<Self, Self::Rejection> {
        extract_session_manager(req).await.map_err(|e| {
            tracing::error!("failed to extract session manager: {e}");
            StatusCode::INTERNAL_SERVER_ERROR
        })
    }
}

async fn extract_session_manager<B>(req: &mut RequestParts<B>) -> anyhow::Result<Manager>
where
    B: Send,
{
    let extensions = req
        .extensions()
        .ok_or_else(|| anyhow::anyhow!("failed to extract extensions"))?;

    let cookies = extensions
        .get::<Cookies>()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("failed to extract cookies"))?;

    let key = extensions
        .get::<Arc<Key>>()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("failed to extract signing key"))?;

    let redis = extensions
        .get::<bb8::Pool<RedisConnectionManager>>()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("failed to extract redis pool"))?;

    Ok(Manager {
        cookies,
        key,
        redis_pool: redis,
    })
}
