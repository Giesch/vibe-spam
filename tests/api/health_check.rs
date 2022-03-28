use crate::helpers::*;

#[tokio::test]
async fn health_check() {
    let app = spawn_app().await;

    let response = app
        .client
        .get(&format!("{}/api/health", &app.address))
        .send()
        .await
        .expect("Failed to execute request.");

    assert!(response.status().is_success());
}
