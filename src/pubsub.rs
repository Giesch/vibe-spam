use anyhow::Context;
use bb8::{Pool, PooledConnection};
use bb8_redis::redis::AsyncCommands;
use bb8_redis::RedisConnectionManager;
use futures::StreamExt;
use futures_core::stream::Stream;
use tokio::sync::watch::{self, Receiver};
use tokio_stream::wrappers::WatchStream;

const REDIS_LOBBY_CHANNEL: &str = "vibe_spam:lobby";

pub type LobbyMessage = String;

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

        let initial_lobby: LobbyMessage = "initial lobby json (empty or from sql)".to_string();
        let (tx, rx) = watch::channel(initial_lobby);

        tokio::task::spawn(async move {
            pubsub.subscribe(REDIS_LOBBY_CHANNEL).await.unwrap();

            while let Some(result) = pubsub.on_message().next().await {
                let payload = result.get_payload::<String>().unwrap();
                tx.send(payload).unwrap();
            }
        });

        Ok(LobbyWatcher { rx })
    }
}

// TODO
// do we just have one redis channel for everything?
//   ie, one tx for all redis stuff, but still many rx and/or filtered rx wrappers
//
// do we need a thread/task to hold the redis pubsub?

pub struct LobbyPublisher<'a> {
    redis: PooledConnection<'a, RedisConnectionManager>,
}

impl<'a> LobbyPublisher<'a> {
    pub fn new(redis: PooledConnection<'a, RedisConnectionManager>) -> Self {
        LobbyPublisher { redis }
    }

    pub async fn publish(&mut self, lobby: LobbyMessage) -> anyhow::Result<()> {
        let _result = self
            .redis
            .publish(REDIS_LOBBY_CHANNEL, lobby)
            .await
            .context("failed to publish lobby")?;

        Ok(())
    }
}
