// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::RedisConnectionManager;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

mod lobby;

const LOBBY_ROOMS: &str = "lobby:rooms";

pub struct Query;

#[Object]
impl Query {
    async fn lobby<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<LobbyResponse> {
        let room_rows = lobby::list_rooms(ctx.db()).await?;
        let rooms: Vec<Room> = room_rows.into_iter().map(Into::into).collect();

        Ok(LobbyResponse { rooms })
    }
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn create_room<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<Room> {
        let db = ctx.db();

        let title = Uuid::new_v4().to_string();
        let room = lobby::create_room(db, title).await?;

        Ok(room.into())
    }
}

#[derive(SimpleObject)]
pub struct LobbyResponse {
    rooms: Vec<Room>,
}

#[derive(SimpleObject)]
pub struct Room {
    title: String,
}

#[derive(Serialize, Deserialize)]
struct RedisRoom {
    name: String,
}

impl From<lobby::RoomRow> for Room {
    fn from(row: lobby::RoomRow) -> Self {
        Self { title: row.title }
    }
}

pub type VibeSpam = Schema<Query, Mutation, EmptySubscription>;

pub fn make(db: PgPool, redis: Pool<RedisConnectionManager>) -> VibeSpam {
    Schema::build(Query, Mutation, EmptySubscription)
        .data(db)
        .data(redis)
        .finish()
}

#[async_trait]
trait VibeSpamContext {
    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>>;
    fn db(&self) -> &PgPool;
}

#[async_trait]
impl<'ctx> VibeSpamContext for Context<'ctx> {
    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>> {
        let pool = self.data_unchecked::<Pool<RedisConnectionManager>>();

        use anyhow::Context;
        pool.get()
            .await
            .context("failed to checkout redis connection from pool")
    }

    fn db(&self) -> &PgPool {
        self.data_unchecked::<PgPool>()
    }
}
