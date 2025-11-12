-- Create / recreate tmp_unified table used by the match_unify template.
-- This file should be executed before running the rendered match_unify SQL (which INSERTs into tmp_unified).
-- Example usage:
--   clickhouse-client --multiquery < sql/create_tmp_unified.sql

DROP TABLE IF EXISTS unify.matched;

CREATE TABLE unify.matched
(
    -- exact grouping keys (from customer.yaml: email, phone, birthdate)
    email String,
    phone String,
    birthdate Date,

    -- arrays for fuzzy fields (first_name, last_name)
    first_name_arr Array(String),
    last_name_arr Array(String),

    -- arrays to track source identifiers
    source_id_arr Array(String),
    source_pk_arr Array(String),

    -- computed min-distance columns for each fuzzy field
    min_distance_first_name UInt32,
    min_distance_last_name UInt32,

    is_matched Bit,
    unified_ids Array(String),
    created_at DateTime
)
ENGINE = Memory;
