// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::redis::AsyncCommands;
use bb8_redis::RedisConnectionManager;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

const LOBBY_ROOMS: &str = "lobby:rooms";

// TODO paging - hard limit?

pub struct Query;

#[Object]
impl Query {
    async fn lobby<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<LobbyResponse> {
        let mut redis = ctx.redis().await?;
        let rooms = redis.lobby_rooms().await?;

        let rooms: Vec<Room> = rooms.into_iter().map(Into::into).collect();

        Ok(LobbyResponse { rooms })
    }
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn create_room<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<LobbyResponse> {
        let mut redis = ctx.redis().await?;

        let name = Uuid::new_v4().to_string();
        let room = RedisRoom { name };

        todo!("randomly generate, create, and return a room")
    }
}

#[derive(SimpleObject)]
pub struct LobbyResponse {
    rooms: Vec<Room>,
}

#[derive(SimpleObject)]
pub struct Room {
    name: String,
}

#[derive(Serialize, Deserialize)]
struct RedisRoom {
    name: String,
}

impl From<RedisRoom> for Room {
    fn from(room: RedisRoom) -> Self {
        Self { name: room.name }
    }
}

pub type VibeSpam = Schema<Query, EmptyMutation, EmptySubscription>;

pub fn make(db: PgPool, redis: Pool<RedisConnectionManager>) -> VibeSpam {
    Schema::build(Query, EmptyMutation, EmptySubscription)
        .data(db)
        .data(redis)
        .finish()
}

#[async_trait]
trait VibeSpamContext {
    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>>;
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
}

#[async_trait]
trait LobbyRepo {
    async fn lobby_rooms(&mut self) -> anyhow::Result<Vec<RedisRoom>>;
}

// TODO move this
#[async_trait]
impl<'a> LobbyRepo for PooledConnection<'a, RedisConnectionManager> {
    async fn lobby_rooms(&mut self) -> anyhow::Result<Vec<RedisRoom>> {
        use anyhow::Context;

        let rooms_json: Option<String> =
            self.get(LOBBY_ROOMS).await.context("failed to get lobby")?;

        let rooms: Vec<RedisRoom> = match rooms_json {
            Some(rs) => {
                let rs: Vec<RedisRoom> =
                    serde_json::from_str(&rs).context("failed to deserialize lobby")?;
                rs
            }
            None => vec![],
        };

        Ok(rooms)
    }

    // async fn create_room(&mut self, room: RedisRoom) -> anyhow::Result<RedisRoom> {
    //     use anyhow::Context;
    // }
}
