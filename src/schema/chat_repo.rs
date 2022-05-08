use anyhow::Context;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

const MESSAGE_QUERY_LIMIT: usize = 50;

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
    todo!()
}

#[tracing::instrument(name = "create chat message query")]
pub async fn create_message(
    db: &PgPool,
    new_message: NewMessage,
) -> anyhow::Result<ChatMessageRow> {
    todo!()
}
