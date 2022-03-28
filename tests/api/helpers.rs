use once_cell::sync::Lazy;
use secrecy::Secret;
use vibe_spam::app::App;
use vibe_spam::settings::Settings;
use vibe_spam::telemetry;

// Taken from zero-to-prod

// Ensure that the `tracing` stack is only initialised once using `once_cell`
static TRACING: Lazy<()> = Lazy::new(|| {
    let default_filter_level = String::from("info");
    let subscriber_name = String::from("test");

    if std::env::var("TEST_LOG").is_ok() {
        let sub = telemetry::get_subscriber(subscriber_name, default_filter_level, std::io::stdout);
        telemetry::init_subscriber(sub);
    } else {
        let sub = telemetry::get_subscriber(subscriber_name, default_filter_level, std::io::sink);
        telemetry::init_subscriber(sub);
    };
});

pub struct TestApp {
    pub address: String,
    pub port: u16,
    pub client: reqwest::Client,
}

pub async fn spawn_app() -> TestApp {
    Lazy::force(&TRACING);

    let settings = test_settings();

    let app = App::build(settings).await.expect("failed to build app");

    let port = app.port();

    let _ = tokio::spawn(app.run());

    let address = format!("http://localhost:{}", port);

    let client = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .cookie_store(true)
        .build()
        .expect("failed to build client");

    TestApp {
        address,
        client,
        port,
    }
}

const MOCK_SIGNING_SECRET: &str =
    "DEZ+TXqTNjb+qQu05MibWt4151A9wc1ZynbWv3dU8sBE+39IPJz9ZMDfQplUzrVLywDs9oNxboZzPmK892vx2Q==";

fn test_settings() -> Settings {
    let mut settings = Settings::from_env().expect("failed to read config");
    // Use a random OS port
    settings.app_port = 0;

    settings.app_signing_secret = Secret::new(MOCK_SIGNING_SECRET.to_string());

    settings
}

impl TestApp {
    pub async fn graphql_query(&self, query: &str) -> serde_json::Value {
        let graphql_request = serde_json::json!({ "query": query });
        let graphql_route = format!("{}/api/graphql", &self.address);

        let response = self
            .client
            .post(graphql_route)
            .body(graphql_request.to_string())
            .send()
            .await
            .expect("Failed to execute request.");

        assert!(response.status().is_success());

        graphql_response_data(response).await
    }

    pub async fn home_page(&self) -> reqwest::Response {
        self.client
            .get(&self.address)
            .send()
            .await
            .expect("failed to execute request")
    }
}

async fn graphql_response_data(response: reqwest::Response) -> serde_json::Value {
    let text = response.text().await.unwrap();

    let mut graphql_response: serde_json::Value = serde_json::from_str(&text).unwrap();
    let graphql_response = graphql_response.as_object_mut().unwrap();

    let data = graphql_response.remove("data").unwrap();
    if data == serde_json::Value::Null {
        let errors = graphql_response.remove("errors").unwrap();
        let errors: Vec<_> = errors
            .as_array()
            .unwrap()
            .iter()
            .map(|error_json| error_json["message"].as_str().unwrap())
            .collect();
        let errors = errors.join("\n\t");

        panic!("graphql errors:\n\t{}", errors);
    }

    data
}
