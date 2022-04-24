use sqlx::PgPool;

use super::lobby_repo;
use super::{LobbyResponse, Room};

pub async fn fetch(db: &PgPool) -> anyhow::Result<LobbyResponse> {
    let room_rows = lobby_repo::list_rooms(db).await?;
    let rooms: Vec<Room> = room_rows.into_iter().map(Into::into).collect();

    Ok(LobbyResponse { rooms })
}
