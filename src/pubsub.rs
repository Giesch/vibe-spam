use anyhow::Context;
use bb8::{Pool, PooledConnection};
use bb8_redis::redis::AsyncCommands;
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures::StreamExt;
use futures_core::stream::Stream;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use tokio::sync::{broadcast, watch};
use tokio_stream::wrappers::{BroadcastStream, WatchStream};
use uuid::Uuid;

use crate::schema::lobby;
use crate::schema::ChatMessage;

const REDIS_LOBBY_CHANNEL: &str = "vibe_spam:lobby";
const REDIS_CHAT_MESSAGES_CHANNEL: &str = "vibe_spam:chat_messages";
const CHAT_MESSAGES_CHANNEL_CAPACITY: usize = 20;

#[derive(Serialize, Deserialize, Debug, Clone, Default)]
pub struct LobbyMessage {
    pub rooms: Vec<RoomMessage>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct RoomMessage {
    pub id: Uuid,
    pub title: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone)]
pub struct LobbySubscriber {
    rx: watch::Receiver<LobbyMessage>,
}

impl LobbySubscriber {
    pub fn into_stream(self) -> impl Stream<Item = LobbyMessage> {
        WatchStream::new(self.rx)
    }

    #[tracing::instrument(name = "spawn lobby subscriber")]
    pub async fn spawn(redis: Pool<RedisConnectionManager>, db: &PgPool) -> anyhow::Result<Self> {
        let mut pubsub = Pool::dedicated_connection(&redis)
            .await
            .context("failed to check out pubsub connection")?
            .into_pubsub();

        let lobby: LobbyMessage = lobby::fetch(db).await?.into();
        let (tx, rx) = watch::channel(lobby);

        tokio::task::spawn(async move {
            pubsub
                .subscribe(REDIS_LOBBY_CHANNEL)
                .await
                .expect("failed to subscribe to lobby channel");

            while let Some(result) = pubsub.on_message().next().await {
                let payload = result
                    .get_payload::<String>()
                    .expect("failed to get string lobby payload");

                let lobby: LobbyMessage =
                    serde_json::from_str(&payload).expect("failed to parse lobby json from redis");

                tx.send(lobby).expect("failed to send lobby");
            }
        });

        Ok(Self { rx })
    }
}

pub struct LobbyPublisher<'a> {
    redis: PooledConnection<'a, RedisConnectionManager>,
}

impl<'a> LobbyPublisher<'a> {
    pub fn new(redis: PooledConnection<'a, RedisConnectionManager>) -> Self {
        Self { redis }
    }

    #[tracing::instrument(name = "lobby publish", skip(self))]
    pub async fn publish(&mut self, lobby: &LobbyMessage) -> anyhow::Result<()> {
        let json = serde_json::to_string(&lobby)?;

        let _result = self
            .redis
            .publish(REDIS_LOBBY_CHANNEL, json)
            .await
            .context("failed to publish lobby")?;

        Ok(())
    }
}

#[derive(Debug)]
pub struct ChatMessageSubscriber {
    tx: broadcast::Sender<Vec<ChatMessage>>,
}

impl ChatMessageSubscriber {
    pub fn room_stream(&self, room_id: Uuid) -> impl Stream<Item = Vec<ChatMessage>> {
        let rx = self.tx.subscribe();

        // explanation for this pattern:
        // https://users.rust-lang.org/t/cloning-variable-inside-of-an-async-move-block/40883/2
        BroadcastStream::new(rx).filter_map(move |new_messages| {
            // NOTE
            // the 'ok' will drop missed messages if a subscriber falls too far behind:
            // https://docs.rs/tokio/latest/tokio/sync/broadcast/index.html#lagging
            let maybe_new_messages = new_messages.ok();

            async move {
                maybe_new_messages.filter(|new_messages| {
                    !new_messages.is_empty() && new_messages[0].room_id == room_id
                })
            }
        })
    }

    #[tracing::instrument(name = "spawn chat room subscriber")]
    pub async fn spawn(redis: Pool<RedisConnectionManager>) -> anyhow::Result<Self> {
        let mut pubsub = Pool::dedicated_connection(&redis)
            .await
            .context("failed to check out pubsub connection")?
            .into_pubsub();

        let (tx, _rx) = broadcast::channel(CHAT_MESSAGES_CHANNEL_CAPACITY);

        let producer = tx.clone();
        tokio::task::spawn(async move {
            pubsub
                .subscribe(REDIS_CHAT_MESSAGES_CHANNEL)
                .await
                .expect("failed to subscribe to lobby channel");

            while let Some(result) = pubsub.on_message().next().await {
                let payload = result
                    .get_payload::<String>()
                    .expect("failed to get string lobby payload");

                let new_messages: Vec<ChatMessage> = serde_json::from_str(&payload)
                    .expect("failed to parse chat message json from redis");

                producer.send(new_messages).expect("failed to send lobby");
            }
        });

        Ok(Self { tx })
    }
}

pub struct ChatMessagePublisher<'a> {
    redis: PooledConnection<'a, RedisConnectionManager>,
}

impl<'a> ChatMessagePublisher<'a> {
    pub fn new(redis: PooledConnection<'a, RedisConnectionManager>) -> Self {
        Self { redis }
    }

    #[tracing::instrument(name = "lobby publish", skip(self))]
    pub async fn publish(&mut self, new_messages: Vec<ChatMessage>) -> anyhow::Result<()> {
        let json = serde_json::to_string(&new_messages)?;

        let _result = self
            .redis
            .publish(REDIS_CHAT_MESSAGES_CHANNEL, json)
            .await
            .context("failed to publish new chat messages")?;

        Ok(())
    }
}
