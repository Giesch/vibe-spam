use crate::helpers::*;

#[tokio::test]
async fn empty_lobby() {
    let app = spawn_app().await;

    let query = r#"{
      lobby {
        rooms {
          name
        }
      }
    }"#;

    let data = app.graphql_query(query).await;
    let data = dbg!(data);
    let rooms = data["lobby"]["rooms"].as_array().unwrap();

    assert_eq!(rooms.len(), 0);
}
