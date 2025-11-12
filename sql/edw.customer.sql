-- Create / recreate tmp_unified table used by the match_unify template.
-- This file should be executed before running the rendered match_unify SQL (which INSERTs into tmp_unified).
-- Example usage:
--   clickhouse-client --multiquery < sql/create_tmp_unified.sql

DROP TABLE IF EXISTS edw.customer;

CREATE TABLE edw.customer
(
    user_profile_id UUID,
    email String,
    phone String,
    birthdate Date,

    first_name String,
    last_name String,
    created_at DateTime DEFAULT now()
)
ENGINE = Memory;
