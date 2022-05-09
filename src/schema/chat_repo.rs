use anyhow::Context;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct ChatMessageRow {
    pub id: Uuid,
    pub room_id: Uuid,
    pub author_session_id: Uuid,
    pub content: String,

    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug)]
pub struct NewMessage {
    pub room_id: Uuid,
    pub author_session_id: Uuid,
    pub content: String,
}

#[tracing::instrument(name = "list chat messages query")]
pub async fn list_messages(db: &PgPool, room_id: Uuid) -> anyhow::Result<Vec<ChatMessageRow>> {
    sqlx::query_as!(
        ChatMessageRow,
        r#"
            SELECT *
            FROM chat_messages
            ORDER BY created_at DESC
            LIMIT 50
        "#
    )
    .fetch_all(db)
    .await
    .context("failed to list chat messages")
}

#[tracing::instrument(name = "create chat message query")]
pub async fn create_message(
    db: &PgPool,
    new_message: NewMessage,
) -> anyhow::Result<ChatMessageRow> {
    sqlx::query_as!(
        ChatMessageRow,
        r#"
            INSERT INTO chat_messages (room_id, author_session_id, content)
            VALUES ($1, $2, $3) RETURNING *
        "#,
        new_message.room_id,
        new_message.author_session_id,
        new_message.content
    )
    .fetch_one(db)
    .await
    .context("failed to insert chat message")
}
