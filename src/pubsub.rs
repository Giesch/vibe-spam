use anyhow::Context;
use bb8::{Pool, PooledConnection};
use bb8_redis::redis::AsyncCommands;
use bb8_redis::RedisConnectionManager;
use chrono::{DateTime, Utc};
use futures::StreamExt;
use futures_core::stream::Stream;
use serde::{Deserialize, Serialize};
use tokio::sync::watch::{self, Receiver};
use tokio_stream::wrappers::WatchStream;
use uuid::Uuid;

const REDIS_LOBBY_CHANNEL: &str = "vibe_spam:lobby";

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
pub struct LobbyWatcher {
    rx: Receiver<LobbyMessage>,
}

impl LobbyWatcher {
    pub fn into_stream(self) -> impl Stream<Item = LobbyMessage> {
        WatchStream::new(self.rx)
    }

    pub async fn spawn(redis: &Pool<RedisConnectionManager>) -> anyhow::Result<Self> {
        let mut pubsub = Pool::dedicated_connection(&redis)
            .await
            .context("failed to check out pubsub connection")?
            .into_pubsub();

        // TODO get initial state from db
        let (tx, rx) = watch::channel(LobbyMessage::default());

        tokio::task::spawn(async move {
            pubsub.subscribe(REDIS_LOBBY_CHANNEL).await.unwrap();

            while let Some(result) = pubsub.on_message().next().await {
                let payload = result.get_payload::<String>().unwrap();
                let lobby =
                    serde_json::from_str(&payload).expect("failed to parse lobby json from redis");

                tx.send(lobby).unwrap();
            }
        });

        Ok(LobbyWatcher { rx })
    }
}

pub struct LobbyPublisher<'a> {
    redis: PooledConnection<'a, RedisConnectionManager>,
}

impl<'a> LobbyPublisher<'a> {
    pub fn new(redis: PooledConnection<'a, RedisConnectionManager>) -> Self {
        LobbyPublisher { redis }
    }

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
