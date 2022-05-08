// async_graphql:: is a prelude by a different name
#![allow(clippy::wildcard_imports)]
use async_graphql::*;
use axum::async_trait;
use bb8::{Pool, PooledConnection};
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures::StreamExt;
use futures_core::stream::Stream;
use serde::Serialize;
use sqlx::PgPool;
use std::sync::Arc;
use uuid::Uuid;

use crate::{
    pubsub::{self, ChatMessageSubscriber, LobbyPublisher, LobbySubscriber},
    settings::Settings,
};

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
        room_id: Uuid,
    ) -> impl Stream<Item = Vec<ChatMessage>> {
        let db = ctx.db();
        let chat_subscriber = ctx.chat_subscriber();

        // TODO get first message is from a db query,
        let initial_messages = vec![];
        let first = tokio_stream::once(initial_messages);

        let rest = chat_subscriber
            .into_stream(room_id)
            .map(convert_new_messages);

        first.chain(rest)
    }
}

fn convert_new_messages(new_messages: Vec<pubsub::ChatMessage>) -> Vec<ChatMessage> {
    new_messages.into_iter().map(Into::into).collect()
}

#[derive(SimpleObject, Serialize, Debug)]
pub struct ChatMessage {
    id: Uuid,
    emoji: Emoji,
    room_id: Uuid,
    author_session_id: Uuid,
    updated_at: DateTime<Utc>,
}

impl From<pubsub::ChatMessage> for ChatMessage {
    fn from(chat_message: pubsub::ChatMessage) -> Self {
        Self {
            id: chat_message.id,
            emoji: chat_message.emoji.into(),
            room_id: chat_message.room_id,
            author_session_id: chat_message.author_session_id,
            updated_at: chat_message.updated_at,
        }
    }
}

#[derive(Enum, Serialize, Copy, Clone, Eq, PartialEq, Debug)]
pub enum Emoji {
    SweatSmile,
    Smile,
    Heart,
    Crying,
    UpsideDown,
    Party,
}

impl From<pubsub::Emoji> for Emoji {
    fn from(emoji: pubsub::Emoji) -> Self {
        match emoji {
            pubsub::Emoji::SweatSmile => Emoji::SweatSmile,
            pubsub::Emoji::Smile => Emoji::Smile,
            pubsub::Emoji::Heart => Emoji::Heart,
            pubsub::Emoji::Crying => Emoji::Crying,
            pubsub::Emoji::UpsideDown => Emoji::UpsideDown,
            pubsub::Emoji::Party => Emoji::Party,
        }
    }
}

#[derive(SimpleObject, Serialize, Debug)]
pub struct Lobby {
    rooms: Vec<Room>,
}

#[derive(SimpleObject, Serialize, Debug)]
pub struct Room {
    id: Uuid,
    title: String,
    created_at: DateTime<Utc>,
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

    fn lobby_subscriber(&self) -> LobbySubscriber {
        self.data_unchecked::<LobbySubscriber>().clone()
    }

    fn chat_subscriber(&self) -> &ChatMessageSubscriber {
        self.data_unchecked::<ChatMessageSubscriber>()
    }
}
