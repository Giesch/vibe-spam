use crate::helpers::*;

#[tokio::test]
async fn example() {
    let app = spawn_app().await;

    let query = r#"{
      add(a: 1, b: 1)
    }"#;

    let data = app.graphql_query(query).await;
    let result = data["add"].as_i64().unwrap();

    assert_eq!(result, 2);
}
