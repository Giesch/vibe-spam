use anyhow::Context;
use secrecy::Secret;
use serde_aux::field_attributes::deserialize_number_from_string;
use std::str::FromStr;

#[derive(serde::Deserialize, Clone)]
pub struct Settings {
    pub app_env: Env,

    pub app_host: String,
    #[serde(deserialize_with = "deserialize_number_from_string")]
    pub app_port: u16,

    pub redis_url: Secret<String>,

    /// The path to the 'dist' directory that contains the compiled elm client
    pub dist: String,

    /// The public root url that oauth should redirect back to
    pub app_url: String,

    pub app_signing_secret: Secret<String>,
}

impl Settings {
    pub fn from_env() -> anyhow::Result<Self> {
        dotenv::dotenv().ok();

        let app_env = require_env_var("APP_ENV")?;
        let app_env: Env = app_env.parse().context("failed to parse app env")?;

        let app_host = require_env_var("APP_HOST")?;

        let app_port = require_env_var("APP_PORT")?;
        let app_port = u16::from_str(&app_port).context("failed to parse APP_PORT")?;

        let redis_url = require_env_var("REDIS_URL")?;
        let redis_url = Secret::new(redis_url);

        let dist = require_env_var("APP_DIST")?;

        let app_url = require_env_var("APP_URL")?;

        let app_signing_secret = require_env_var("APP_SIGNING_SECRET")?;
        let app_signing_secret = Secret::new(app_signing_secret);

        Ok(Self {
            app_env,
            app_host,
            app_port,
            redis_url,
            dist,
            app_url,
            app_signing_secret,
        })
    }
}

fn require_env_var(var_name: &str) -> anyhow::Result<String> {
    let value = std::env::var(var_name).with_context(|| format!("failed to read {var_name}"))?;
    Ok(value)
}

#[derive(serde::Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum Env {
    Local,
    Prod,
}

impl FromStr for Env {
    type Err = ParseEnvError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "local" => Ok(Self::Local),
            "prod" => Ok(Self::Prod),
            other => Err(ParseEnvError::Failed(other.to_string())),
        }
    }
}

#[derive(thiserror::Error, Debug)]
pub enum ParseEnvError {
    #[error("{0} is not a valid env, use local or prod")]
    Failed(String),
}
