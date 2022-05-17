// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures::StreamExt;
use futures_core::stream::{BoxStream, Stream};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use std::{str::FromStr, sync::Arc};
use uuid::Uuid;

use crate::{
    pubsub::{self, ChatMessagePublisher, ChatMessageSubscriber, LobbyPublisher, LobbySubscriber},
    settings::Settings,
};

pub mod chat;
mod chat_repo;
pub mod lobby;
mod lobby_repo;

pub struct Query;

#[Object]
impl Query {
    async fn lobby<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<Lobby> {
        let db = ctx.db();

        let lobby = lobby::fetch(db).await?;

        Ok(lobby)
    }
}

pub struct Mutation;

#[Object]
impl Mutation {
    async fn create_room<'ctx>(&self, ctx: &'ctx Context<'_>) -> Result<Room> {
        let db = ctx.db();
        let settings = ctx.settings();
        let mut lobby_publisher = ctx.lobby_publisher().await?;

        let room = lobby::create_room(db, settings, &mut lobby_publisher).await?;

        Ok(room)
    }

    async fn create_message<'ctx>(
        &self,
        ctx: &'ctx Context<'_>,
        new_message: NewMessage,
    ) -> Result<ChatMessage> {
        let db = ctx.db();
        let mut chat_publisher = ctx.chat_publisher().await?;

        let message = chat::create_message(db, &mut chat_publisher, new_message).await?;

        Ok(message)
    }
}

#[derive(InputObject)]
pub struct NewMessage {
    room_title: String,
    author_session_id: Uuid,
    emoji: Emoji,
}

pub struct Subscription;

#[Subscription]
impl Subscription {
    async fn lobby_updates<'ctx>(&self, ctx: &'ctx Context<'_>) -> impl Stream<Item = Lobby> {
        ctx.lobby_subscriber().into_stream().map(Into::into)
    }

    async fn chat_room_updates<'ctx>(
        &self,
        ctx: &'ctx Context<'_>,
        room_title: String,
    ) -> BoxStream<'_, Vec<ChatMessage>> {
        let db = ctx.db();
        let chat_subscriber = ctx.chat_subscriber();

        let initial = match chat::list_initial_messages(db, room_title).await {
            Ok(ok) => ok,
            Err(err) => {
                tracing::error!("failed to list chat messages: {err}");
                return futures::stream::empty().boxed();
            }
        };

        let first = tokio_stream::once(initial.messages);
        let rest = chat_subscriber.room_stream(initial.room_id);

        first.chain(rest).boxed()
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
pub struct PosixTime(i64);

scalar!(PosixTime, "PosixTime", "Unix epoch time, in milliseconds");

impl From<DateTime<Utc>> for PosixTime {
    fn from(dt: DateTime<Utc>) -> Self {
        Self(dt.timestamp_millis())
    }
}

// NOTE, this is also used for serializing to redis
#[derive(SimpleObject, Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub id: Uuid,
    pub emoji: Emoji,
    pub room_id: Uuid,
    pub author_session_id: Uuid,
    pub updated_at: PosixTime,
}

// NOTE, this is also used for serializing to redis
#[derive(Enum, Copy, Clone, Eq, PartialEq, Debug, Serialize, Deserialize)]
pub enum Emoji {
    SweatSmile,
    Smile,
    Heart,
    Crying,
    UpsideDown,
    Party,
}

impl Emoji {
    pub fn to_str(&self) -> &str {
        match self {
            Emoji::SweatSmile => "😅",
            Emoji::Smile => "😊",
            Emoji::Heart => "❤️",
            Emoji::Crying => "😭",
            Emoji::UpsideDown => "🙃",
            Emoji::Party => "🥳",
        }
    }
}

impl FromStr for Emoji {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        use anyhow::Context;

        ALL_EMOJI
            .iter()
            .find(|emoji| emoji.to_str() == s)
            .copied()
            .context("invalid emoji")
    }
}

const ALL_EMOJI: [Emoji; 6] = [
    Emoji::SweatSmile,
    Emoji::Smile,
    Emoji::Heart,
    Emoji::Crying,
    Emoji::UpsideDown,
    Emoji::Party,
];

#[derive(SimpleObject, Serialize, Debug)]
pub struct Lobby {
    rooms: Vec<Room>,
}

#[derive(SimpleObject, Serialize, Debug)]
pub struct Room {
    id: Uuid,
    title: String,
    updated_at: PosixTime,
}

impl From<pubsub::LobbyMessage> for Lobby {
    fn from(lobby: pubsub::LobbyMessage) -> Self {
        Self {
            rooms: lobby.rooms.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<Lobby> for pubsub::LobbyMessage {
    fn from(lobby: Lobby) -> Self {
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
            updated_at: room.updated_at,
        }
    }
}

impl From<pubsub::RoomMessage> for Room {
    fn from(room: pubsub::RoomMessage) -> Self {
        Self {
            id: room.id,
            title: room.title,
            updated_at: room.updated_at,
        }
    }
}

impl From<lobby_repo::RoomRow> for Room {
    fn from(row: lobby_repo::RoomRow) -> Self {
        Self {
            id: row.id,
            title: row.title,
            updated_at: row.updated_at.into(),
        }
    }
}

pub type VibeSpam = Schema<Query, Mutation, Subscription>;

pub fn new(
    db: PgPool,
    redis: Pool<RedisConnectionManager>,
    lobby_subscriber: LobbySubscriber,
    chat_subscriber: ChatMessageSubscriber,
    settings: Arc<Settings>,
) -> VibeSpam {
    Schema::build(Query, Mutation, Subscription)
        .data(db)
        .data(redis)
        .data(lobby_subscriber)
        .data(chat_subscriber)
        .data(settings)
        .finish()
}

pub fn sdl() -> String {
    Schema::build(Query, Mutation, Subscription).finish().sdl()
}

#[async_trait]
trait VibeSpamContext {
    fn settings(&self) -> &Settings;

    fn db(&self) -> &PgPool;

    async fn redis(&self) -> anyhow::Result<PooledConnection<RedisConnectionManager>>;

    async fn lobby_publisher(&self) -> anyhow::Result<LobbyPublisher>;

    async fn chat_publisher(&self) -> anyhow::Result<ChatMessagePublisher>;

    fn lobby_subscriber(&self) -> LobbySubscriber;

    fn chat_subscriber(&self) -> &ChatMessageSubscriber;
}

#[async_trait]
impl<'ctx> VibeSpamContext for Context<'ctx> {
    fn settings(&self) -> &Settings {
        self.data_unchecked::<Arc<Settings>>()
    }

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

    async fn chat_publisher(&self) -> anyhow::Result<ChatMessagePublisher> {
        let redis = self.redis().await?;

        Ok(ChatMessagePublisher::new(redis))
    }

    fn lobby_subscriber(&self) -> LobbySubscriber {
        self.data_unchecked::<LobbySubscriber>().clone()
    }

    fn chat_subscriber(&self) -> &ChatMessageSubscriber {
        self.data_unchecked::<ChatMessageSubscriber>()
    }
}
