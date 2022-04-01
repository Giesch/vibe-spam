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

        // TODO generate fun names
        let title = Uuid::new_v4().to_string();
        let room = lobby::create_room(db, title).await?;

        // TODO publish to redis

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

#[async_trait]
trait LobbyRepo {
    async fn lobby_rooms(&mut self) -> anyhow::Result<Vec<RedisRoom>>;
}

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
