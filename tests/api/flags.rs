use crate::helpers::*;

use scraper::{Html, Selector};
use serde::Deserialize;

#[tokio::test]
async fn flags() {
    let app = spawn_app().await;

    let home_response = app.home_page().await;
    let _flag_json = parse_flags_from_html(home_response).await;
}

async fn parse_flags_from_html(home_response: reqwest::Response) -> ElmFlagsJson {
    assert!(home_response.status().is_success());

    let home_html = home_response.text().await.unwrap();
    let home_html = Html::parse_document(&home_html);
    let selector = Selector::parse("#elm-flags-json").unwrap();
    let elm_flags_div = home_html
        .select(&selector)
        .next()
        .expect("no flags div found");
    let json_str = elm_flags_div.inner_html();

    serde_json::from_str(&json_str).unwrap()
}

// NOTE this needs to match the elm struct Shared.Flags
#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ElmFlagsJson {
    #[allow(dead_code)] // this is here to test that it can be deserialized
    session: ElmSessionJson,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ElmSessionJson {
    #[allow(dead_code)] // this is here to test that it can be deserialized
    session_id: String,
}
