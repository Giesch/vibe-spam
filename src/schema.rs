#![allow(clippy::wildcard_imports)] // this is a prelude by a different name
use async_graphql::*;
use bb8_redis::RedisConnectionManager;

pub struct Query;

#[Object]
impl Query {
    /// Returns the sum of a and b
    async fn add<'ctx>(&self, _ctx: &'ctx Context<'_>, a: i32, b: i32) -> Result<i32> {
        Ok(a + b)
    }
}

pub type AppSchema = Schema<Query, EmptyMutation, EmptySubscription>;

pub fn make(redis: bb8::Pool<RedisConnectionManager>) -> AppSchema {
    Schema::build(Query, EmptyMutation, EmptySubscription)
        .data(redis)
        .finish()
}
