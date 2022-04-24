// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures::StreamExt;
use futures_core::stream::Stream;
use sqlx::PgPool;
use uuid::Uuid;

use crate::pubsub::{self, LobbyPublisher, LobbyWatcher};

pub mod lobby;
mod lobby_repo;

pub struct Query;

#[Object]
impl Query {
    async fn lobby<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<LobbyResponse> {
        let lobby_response = lobby::fetch(ctx.db()).await?;

        Ok(lobby_response)
    }
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn create_room<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<Room> {
        let db = ctx.db();

        let title = Uuid::new_v4().to_string();

        let room = lobby_repo::create_room(db, title).await?;

        let lobby: pubsub::LobbyMessage = lobby::fetch(ctx.db()).await?.into();
        ctx.lobby_publisher().await?.publish(&lobby).await?;

        Ok(room.into())
    }
}

pub struct Subscription;

#[Subscription]
impl Subscription {
    async fn lobby_updates<'ctx>(
        &self,
        ctx: &'ctx Context<'_>,
    ) -> impl Stream<Item = LobbyResponse> {
        ctx.lobby_watcher().into_stream().map(Into::into)
    }
}

#[derive(SimpleObject)]
pub struct LobbyResponse {
    rooms: Vec<Room>,
}

#[derive(SimpleObject)]
pub struct Room {
    id: Uuid,
    title: String,
    created_at: DateTime<Utc>,
}

impl From<pubsub::LobbyMessage> for LobbyResponse {
    fn from(lobby: pubsub::LobbyMessage) -> Self {
        Self {
            rooms: lobby.rooms.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<LobbyResponse> for pubsub::LobbyMessage {
    fn from(lobby: LobbyResponse) -> Self {
        Self {
            rooms: lobby.rooms.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<Room> for pubsub::RoomMessage {
    fn from(room: Room) -> Self {
        Self {
            id: room.id,
            title: room.title,
            created_at: room.created_at,
        }
    }
}

impl From<pubsub::RoomMessage> for Room {
    fn from(room: pubsub::RoomMessage) -> Self {
        Self {
            id: room.id,
            title: room.title,
            created_at: room.created_at,
        }
    }
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

pub type VibeSpam = Schema<Query, Mutation, Subscription>;

pub fn new(
    db: PgPool,
    redis: Pool<RedisConnectionManager>,
    lobby_watcher: LobbyWatcher,
) -> VibeSpam {
    Schema::build(Query, Mutation, Subscription)
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
