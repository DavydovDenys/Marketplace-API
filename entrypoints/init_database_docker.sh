#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER USER api WITH SUPERUSER;
    CREATE DATABASE api_rails_development;
    CREATE DATABASE api_rails_test;
    GRANT ALL PRIVILEGES ON DATABASE api_rails_development TO api;
    GRANT ALL PRIVILEGES ON DATABASE api_rails_test TO api;
EOSQL
