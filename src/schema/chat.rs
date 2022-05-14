use anyhow::Context;
use sqlx::PgPool;
use uuid::Uuid;

use super::chat_repo;
use super::chat_repo::ChatMessageRow;
use super::{ChatMessage, Emoji};
use crate::pubsub::ChatMessagePublisher;

pub struct InitialMessages {
    pub room_id: Uuid,
    pub messages: Vec<ChatMessage>,
}

pub async fn list_initial_messages(
    db: &PgPool,
    room_title: String,
) -> anyhow::Result<InitialMessages> {
    let room = chat_repo::find_room_by_title(db, room_title).await?;

    let messages = chat_repo::list_messages(db, room.id)
        .await
        .and_then(convert_message_rows)?;

    Ok(InitialMessages {
        room_id: room.id,
        messages,
    })
}

fn convert_message_rows(rows: Vec<chat_repo::ChatMessageRow>) -> anyhow::Result<Vec<ChatMessage>> {
    rows.into_iter().map(TryInto::try_into).collect()
}

pub async fn create_message(
    db: &PgPool,
    publisher: &mut ChatMessagePublisher<'_>,
    new_message: chat_repo::NewMessage,
) -> anyhow::Result<ChatMessage> {
    let message = chat_repo::create_message(db, new_message.into()).await?;
    let message: ChatMessage = message.try_into()?;

    publisher.publish(vec![message.clone()]).await?;

    Ok(message)
}

impl TryFrom<ChatMessageRow> for ChatMessage {
    type Error = anyhow::Error;

    fn try_from(row: ChatMessageRow) -> Result<Self, Self::Error> {
        let emoji = Emoji::from_str(&row.content).context("unexpected emoji string")?;

        Ok(Self {
            emoji,
            id: row.id,
            room_id: row.room_id,
            author_session_id: row.author_session_id,
            updated_at: row.updated_at,
        })
    }
}

pub struct NewMessage {
    room_id: Uuid,
    author_session_id: Uuid,
    emoji: Emoji,
}

impl From<NewMessage> for chat_repo::NewMessage {
    fn from(message: NewMessage) -> Self {
        let content = message.emoji.to_str().to_string();

        Self {
            room_id: message.room_id,
            author_session_id: message.author_session_id,
            content,
        }
    }
}
