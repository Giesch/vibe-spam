use crate::helpers::*;

const LIST_ROOMS: &str = r#"{
  lobby {
    rooms {
      title
    }
  }
}"#;

#[tokio::test]
async fn empty_lobby() {
    let app = spawn_app().await;

    let data = app.graphql_query(LIST_ROOMS).await;
    let rooms = data["lobby"]["rooms"].as_array().unwrap();

    assert_eq!(rooms.len(), 0);
}

#[tokio::test]
async fn create_room() {
    let app = spawn_app().await;

    let query = r#"
      mutation {
        createRoom {
          title
        }
      }
    "#;

    let data = app.graphql_query(query).await;
    let created_room_title = data["createRoom"]["title"].as_str().unwrap();

    let data = app.graphql_query(LIST_ROOMS).await;
    let rooms = data["lobby"]["rooms"].as_array().unwrap();

    assert_eq!(rooms.len(), 1);
    assert_eq!(&rooms[0]["title"], created_room_title);
}
