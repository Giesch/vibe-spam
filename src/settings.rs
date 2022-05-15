use anyhow::Context;
use rand::seq::SliceRandom;
use secrecy::{ExposeSecret, Secret};
use serde::Deserialize;
use serde_aux::field_attributes::deserialize_number_from_string;
use sqlx::postgres::PgConnectOptions;
use std::fmt::Debug;
use std::str::FromStr;

#[derive(serde::Deserialize, Clone, Debug)]
pub struct Settings {
    pub app_env: Env,

    pub app_host: String,
    #[serde(deserialize_with = "deserialize_number_from_string")]
    pub app_port: u16,

    /// The DATABASE_URL set by fly.io
    pub db_url: Secret<String>,
    pub redis_url: Secret<String>,

    /// The path to the 'dist' directory that contains the compiled elm client
    pub dist: String,

    /// The public root url that oauth should redirect back to
    pub app_url: String,

    pub app_signing_secret: Secret<String>,

    /// The 'random' words to use for room names
    pub dictionary: Dictionary,
}

impl Settings {
    pub fn from_env() -> anyhow::Result<Self> {
        dotenv::dotenv().ok();

        let app_env = require_env_var("APP_ENV")?;
        let app_env: Env = app_env.parse().context("failed to parse app env")?;

        let app_host = require_env_var("APP_HOST")?;

        let app_port = require_env_var("APP_PORT")?;
        let app_port = u16::from_str(&app_port).context("failed to parse APP_PORT")?;

        let db_url = require_env_var("DATABASE_URL")?;
        let db_url = Secret::new(db_url);

        let redis_url = require_env_var("REDIS_URL")?;
        let redis_url = Secret::new(redis_url);

        let dist = require_env_var("APP_DIST")?;

        let app_url = require_env_var("APP_URL")?;

        let app_signing_secret = require_env_var("APP_SIGNING_SECRET")?;
        let app_signing_secret = Secret::new(app_signing_secret);

        let dictionary = read_dictionary()?;

        Ok(Self {
            app_env,
            app_host,
            app_port,
            db_url,
            redis_url,
            dist,
            app_url,
            app_signing_secret,
            dictionary,
        })
    }

    pub fn pg_options(&self) -> anyhow::Result<PgConnectOptions> {
        let options: PgConnectOptions = self
            .db_url
            .expose_secret()
            .parse()
            .context("failed to parse DATABASE_URL")?;

        Ok(options)
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

#[derive(Clone, Deserialize)]
pub struct Dictionary {
    pub adjectives: Vec<String>,
    pub nouns: Vec<String>,
}

impl Dictionary {
    pub fn random_adjective(&self) -> &str {
        let mut rng = rand::thread_rng();
        self.adjectives
            .choose(&mut rng)
            .expect("expected adjectives to be nonempty")
    }

    pub fn random_noun(&self) -> &str {
        let mut rng = rand::thread_rng();
        self.nouns
            .choose(&mut rng)
            .expect("expected nouns to be nonempty")
    }
}

impl Debug for Dictionary {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Dictionary")
            .field("adjectives", &self.adjectives.len())
            .field("nouns", &self.nouns.len())
            .finish()
    }
}

fn read_dictionary() -> anyhow::Result<Dictionary> {
    let dict_path = std::env::current_dir()?.join("config/dictionary.txt");
    let dict_str = std::fs::read_to_string(dict_path).context("failed to read dictionary")?;

    let chunks: Vec<_> = dict_str.split("\n\n").collect();

    let adjectives: Vec<String> = chunks[0].split_whitespace().map(String::from).collect();
    let nouns: Vec<String> = chunks[1].split_whitespace().map(String::from).collect();

    Ok(Dictionary { adjectives, nouns })
}
