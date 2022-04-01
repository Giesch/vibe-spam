use crate::helpers::*;

#[tokio::test]
async fn empty_lobby() {
    let app = spawn_app().await;

    let query = r#"{
      lobby {
        rooms {
          title
        }
      }
    }"#;

    let data = app.graphql_query(query).await;
    let rooms = data["lobby"]["rooms"].as_array().unwrap();

    assert_eq!(rooms.len(), 0);
}
