use anyhow::Context;
use sqlx::PgPool;
use uuid::Uuid;

use super::chat_repo;
use super::chat_repo::ChatMessageRow;
use super::{ChatMessage, Emoji, NewMessage};
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
    new_message: NewMessage,
) -> anyhow::Result<ChatMessage> {
    let room = chat_repo::find_room_by_title(db, new_message.room_title).await?;

    let content = new_message.emoji.to_str().to_string();
    let new_message = chat_repo::NewMessage {
        room_id: room.id,
        author_session_id: new_message.author_session_id,
        content,
    };

    let created_message = chat_repo::create_message(db, new_message).await?;
    let created_message: ChatMessage = created_message.try_into()?;

    publisher.publish(vec![created_message.clone()]).await?;

    Ok(created_message)
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
