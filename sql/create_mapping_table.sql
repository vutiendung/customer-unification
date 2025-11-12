-- Create mapping table used by the match_unify template.
-- This creates the database "unify" and a persistent mapping table named "mapping_source".
-- Adjust names if your temp_dataset points to a different database/table.

CREATE DATABASE IF NOT EXISTS unify.mapping_source;

CREATE TABLE IF NOT EXISTS unify.mapping_source
(
    mapping_id UUID DEFAULT generateUUIDv4(),      -- unique id for this mapping row (generateUUIDv4())
    group_id   UUID,      -- group id (for matched groups this is shared across the group; for unmatched we generate a new one per mapping row)
    source_id  String,    -- logical source identifier (matches source.source_id from YAML)
    source_pk  String,    -- source primary key (matches source.source_pk from YAML)
    created_at DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (mapping_id);
