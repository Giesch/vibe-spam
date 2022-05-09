use anyhow::Context;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct RoomRow {
    pub id: Uuid,
    pub title: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[tracing::instrument(name = "list rooms query")]
pub async fn list_rooms(db: &PgPool) -> anyhow::Result<Vec<RoomRow>> {
    sqlx::query_as!(
        RoomRow,
        r#"
            SELECT *
            FROM rooms
            ORDER BY created_at DESC
            LIMIT 25
        "#
    )
    .fetch_all(db)
    .await
    .context("failed to list rooms")
}

#[tracing::instrument(name = "create room query")]
#[allow(clippy::panic)] // this is coming from within the sqlx macro
pub async fn create_room(db: &PgPool, title: String) -> anyhow::Result<RoomRow> {
    sqlx::query_as!(
        RoomRow,
        r#"
            INSERT INTO rooms (title)
            VALUES ($1) RETURNING *
        "#,
        title
    )
    .fetch_one(db)
    .await
    .context("failed to insert room")
}
