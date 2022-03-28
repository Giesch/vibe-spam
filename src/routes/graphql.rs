use crate::schema::AppSchema;
use crate::session::Session;
use async_graphql::http::{playground_source, GraphQLPlaygroundConfig};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::extract::Extension;
use axum::response::{Html, IntoResponse};

pub const ROUTE: &str = "/api/graphql";

pub async fn handler(
    schema: Extension<AppSchema>,
    req: GraphQLRequest,
    session: Session,
) -> GraphQLResponse {
    schema.execute(req.into_inner().data(session)).await.into()
}

pub async fn playground() -> impl IntoResponse {
    let playground_config = GraphQLPlaygroundConfig::new(ROUTE);
    Html(playground_source(playground_config))
}

#[allow(deprecated)] // I couldn't get the recommended alternative to compile
pub fn layer(schema: AppSchema) -> axum::AddExtensionLayer<AppSchema> {
    axum::AddExtensionLayer::new(schema)
}
