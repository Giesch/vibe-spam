// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures_core::stream::Stream;
use serde::Serialize;
use sqlx::PgPool;
use uuid::Uuid;

mod lobby_repo;

pub struct Query;

#[Object]
impl Query {
    async fn lobby<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<LobbyResponse> {
        let lobby_response = get_lobby(ctx.db()).await?;

        Ok(lobby_response)
    }
}

async fn get_lobby(db: &PgPool) -> anyhow::Result<LobbyResponse> {
    let room_rows = lobby_repo::list_rooms(db).await?;
    let rooms: Vec<Room> = room_rows.into_iter().map(Into::into).collect();

    Ok(LobbyResponse { rooms })
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn create_room<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<Room> {
        let db = ctx.db();

        let title = Uuid::new_v4().to_string();
        let room = lobby_repo::create_room(db, title).await?;

        // TODO need transaction?
        let lobby = get_lobby(ctx.db()).await?;
        let lobby = serde_json::to_string(&lobby)?;
        ctx.lobby_publisher().await?.publish(lobby).await?;

        Ok(room.into())
    }
}

struct Subscription;

use crate::pubsub::{LobbyMessage, LobbyPublisher, LobbyWatcher};

#[Subscription]
impl Subscription {
    // TODO convert return to lobby response
    async fn lobby_updates<'ctx>(
        &self,
        ctx: &'ctx Context<'_>,
    ) -> impl Stream<Item = LobbyMessage> {
        ctx.lobby_watcher().into_stream()
    }
}

#[derive(SimpleObject, Serialize)]
pub struct LobbyResponse {
    rooms: Vec<Room>,
}

#[derive(SimpleObject, Serialize)]
pub struct Room {
    id: Uuid,
    title: String,
    created_at: DateTime<Utc>,
}

impl From<lobby_repo::RoomRow> for Room {
    fn from(row: lobby_repo::RoomRow) -> Self {
        Self {
            id: row.id,
            title: row.title,
            created_at: row.created_at,
        }
    }
}

pub type VibeSpam = Schema<Query, Mutation, EmptySubscription>;

pub fn new(
    db: PgPool,
    redis: Pool<RedisConnectionManager>,
    lobby_watcher: LobbyWatcher,
) -> VibeSpam {
    Schema::build(Query, Mutation, EmptySubscription)
        .data(db)
        .data(redis)
        .data(lobby_watcher)
        .finish()
}

#[async_trait]
trait VibeSpamContext {
    fn db(&self) -> &PgPool;

    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>>;

    async fn lobby_publisher(&self) -> anyhow::Result<LobbyPublisher>;

    fn lobby_watcher(&self) -> LobbyWatcher;
}

#[async_trait]
impl<'ctx> VibeSpamContext for Context<'ctx> {
    fn db(&self) -> &PgPool {
        self.data_unchecked::<PgPool>()
    }

    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>> {
        let pool = self.data_unchecked::<Pool<RedisConnectionManager>>();

        use anyhow::Context;
        pool.get()
            .await
            .context("failed to checkout redis connection from pool")
    }

    async fn lobby_publisher(&self) -> anyhow::Result<LobbyPublisher> {
        let redis = self.redis().await?;

        Ok(LobbyPublisher::new(redis))
    }

    fn lobby_watcher(&self) -> LobbyWatcher {
        self.data_unchecked::<LobbyWatcher>().clone()
    }
}
