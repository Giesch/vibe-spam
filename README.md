# vibe-spam

## basic dev flow

first time:  
cp .example.env .env  
cargo install bunyan

every time:

```sh
docker-compose up -d # bring up postgres and redis
sqlx migrate run # migrate postgres
cargo run | bunyan # run the app
```

## testing commands

whole suite:

```sh
cargo test
```

single test:

```sh
TEST_LOG=true cargo test test_fn_name | bunyan
```

## scripts directory

psql.sh - connects to the docker-compose postgres database  
prepare.sh - commits an update to the sqlx-data.json file

## migrations

https://github.com/launchbadge/sqlx/tree/master/sqlx-cli

### to add a new migration:

```sh
sqlx migrate add -r migration_name
```

### to migrate in prod, from this directory:

first, start the fly db proxy:

```sh
flyctl proxy 5432 -a vibe-spam-postgres

```

then, in another shell in this directory:

```sh
DATABASE_URL="postgres://postgres:<PASSWORD_HERE>@localhost:5432" sqlx migrate run
```

for direct psql to prod:

```sh
fly pg connect --app vibe-spam-postgres
```

for direct shell to prod:

```sh
fly ssh console --app vibe-spam
```
