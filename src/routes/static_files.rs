use crate::session::{self, Session};

use anyhow::Context;
use askama::Template;
use axum::extract::Extension;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get_service, MethodRouter};
use axum::Json;
use serde::Serialize;
use std::fs;
use std::sync::Arc;
use tower_http::services::ServeDir;

// This is used by the vite dev server to simulate the
// flags being served in html in prod
#[tracing::instrument(name = "get flags")]
pub async fn get_flags(session: Session) -> Json<ElmFlagsJson> {
    Json(flags_from_session(session))
}

#[tracing::instrument(name = "index html")]
pub async fn index_html(
    session: Session,
    Extension(assets): Extension<Arc<Assets>>,
) -> Result<impl IntoResponse, StatusCode> {
    let flags = flags_from_session(session);

    Ok(IndexTemplate::new(&assets, flags))
}

fn flags_from_session(session: Session) -> ElmFlagsJson {
    let session: ElmSessionJson = session.data().into();

    ElmFlagsJson { session }
}

impl From<&session::Data> for ElmSessionJson {
    fn from(data: &session::Data) -> Self {
        Self {
            session_id: data.session_id.to_string(),
        }
    }
}

pub fn assets(dist: &str) -> MethodRouter {
    let asset_path = format!("{}/assets", dist);
    get_service(ServeDir::new(&asset_path)).handle_error(error_to_500)
}

async fn error_to_500(error: impl core::fmt::Debug) -> impl IntoResponse {
    tracing::error!("Error serving static file: {:?}", error);
    StatusCode::INTERNAL_SERVER_ERROR
}

// NOTE this needs to match the elm struct Shared.Flags
#[derive(Serialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ElmFlagsJson {
    session: ElmSessionJson,
}

// NOTE this needs to match the elm struct Shared.Session
#[derive(Serialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ElmSessionJson {
    session_id: String,
}

#[derive(Template)]
#[template(path = "index.html")]
struct IndexTemplate {
    index_js: String,
    vendor_js: String,
    flags: String,
}

impl IndexTemplate {
    pub fn new(assets: &Assets, flags_json: ElmFlagsJson) -> Self {
        let index_js = assets.index_js.clone();
        let vendor_js = assets.vendor_js.clone();

        // This serialize can fail only if something fundementally wrong is
        // included in elm flags; ie a mutex, or a map with number keys
        let flags = serde_json::to_string(&flags_json).expect("failed to serialize elm flags");

        Self {
            index_js,
            vendor_js,
            flags,
        }
    }
}

#[derive(Debug)]
pub struct Assets {
    /// The name of the compiled index.js file
    index_js: String,
    /// The name of the compiled vendor.js file
    vendor_js: String,
}

// for use during startup in prod
// gets the name of the compiled js files, which will have hashes in them
pub fn list_assets_dir(dist: &str) -> anyhow::Result<Assets> {
    let assets_dir = format!("{}/assets", dist);
    let assets_dir = fs::read_dir(assets_dir).context("failed to read assets dir")?;

    let mut assets_files: Vec<String> = vec![];
    for entry in assets_dir {
        let entry = entry.context("failed to read assets dir entry")?;
        let entry = match entry.file_name().to_str().map(str::to_string) {
            Some(e) => e,
            None => anyhow::bail!("invalid utf8 in file name: {entry:?}"),
        };

        assets_files.push(entry);
    }

    assets_files.sort();

    let assets = match assets_files.as_slice() {
        [index_js, vendor_js] if is_index_js(index_js) && is_vendor_js(vendor_js) => Assets {
            index_js: index_js.to_string(),
            vendor_js: vendor_js.to_string(),
        },
        other => anyhow::bail!("unexpected assets files: {other:?}"),
    };

    Ok(assets)
}

fn is_index_js(s: &str) -> bool {
    s.starts_with("index.") && s.ends_with(".js")
}

fn is_vendor_js(s: &str) -> bool {
    s.starts_with("vendor") && s.ends_with(".js")
}
