use vibe_spam::app::App;
use vibe_spam::settings::Settings;
use vibe_spam::telemetry;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let subscriber =
        telemetry::get_subscriber("vibe-spam-server".into(), "info".into(), std::io::stdout);
    telemetry::init_subscriber(subscriber);

    let settings = Settings::from_env().expect("failed to read config from env");
    let app = App::build(settings).await?;

    tracing::info!("listening on {:?}", app.address());

    app.run().await?;

    Ok(())
}
