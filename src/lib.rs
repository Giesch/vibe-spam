#![warn(
    clippy::module_name_repetitions,
    clippy::wildcard_imports,
    clippy::unwrap_used,
    clippy::panic
)]

pub mod app;
pub mod routes;
pub mod schema;
pub mod session;
pub mod settings;
pub mod telemetry;