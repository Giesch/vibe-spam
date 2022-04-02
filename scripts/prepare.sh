#!/usr/bin/env bash

cargo sqlx prepare -- --lib && git add . && git commit -m "ran cargo sqlx prepare"
