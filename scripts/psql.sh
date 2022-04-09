#!/usr/bin/env bash

PGPASSWORD="postgres" psql -h "localhost" -U "postgres" -p "5432" -d "postgres"
