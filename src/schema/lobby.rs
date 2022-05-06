use sqlx::PgPool;

use super::lobby_repo;
use super::{LobbyResponse, Room};
use crate::pubsub::{self, LobbyPublisher};
use crate::settings::Settings;

#[tracing::instrument(name = "lobby fetch")]
pub async fn fetch(db: &PgPool) -> anyhow::Result<LobbyResponse> {
    let room_rows = lobby_repo::list_rooms(db).await?;
    let rooms: Vec<Room> = room_rows.into_iter().map(Into::into).collect();

    Ok(LobbyResponse { rooms })
}

#[tracing::instrument(name = "create room", skip(lobby_publisher))]
pub async fn create_room(
    db: &PgPool,
    settings: &Settings,
    lobby_publisher: &mut LobbyPublisher<'_>,
) -> anyhow::Result<Room> {
    let adjective = settings.dictionary.random_adjective();
    let noun = settings.dictionary.random_noun();
    let title = format!("{adjective}-{noun}");

    let room = lobby_repo::create_room(db, title).await?;

    let lobby: pubsub::LobbyMessage = fetch(db).await?.into();
    lobby_publisher.publish(&lobby).await?;

    Ok(room.into())
}
