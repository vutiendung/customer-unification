-- SQL script to create sample ClickHouse databases/tables and insert test data
-- based on customer.yaml sources (crm.customers_a and sap.customers_b).
-- This creates simple MergeTree tables and inserts rows that demonstrate:
--  - exact matching on email, phone, birthdate
--  - fuzzy matching candidates for first_name and last_name (small Levenshtein distances)
-- Run this script against a ClickHouse server.

-- Create databases
CREATE DATABASE IF NOT EXISTS crm;
CREATE DATABASE IF NOT EXISTS sap;
CREATE DATABASE IF NOT EXISTS edw;

-- Create table for customers_a in crm
CREATE TABLE IF NOT EXISTS crm.customers_a
(
    source_pk String,        -- corresponds to "source_pk" column name in YAML
    pk UInt64,               -- corresponds to "pk" column name in YAML
    eml String,              -- customers_a: email mapped as eml
    fst_name String,         -- customers_a: first_name mapped as fst_name
    lst_name String,         -- customers_a: last_name mapped as lst_name
    birthdate Date,
    home_phone String
)
ENGINE = MergeTree()
ORDER BY (pk);

-- Create table for customers_b in sap
CREATE TABLE IF NOT EXISTS sap.customers_b
(
    source_pk String,
    pk UInt64,
    email String,            -- customers_b uses "email" column name
    first_name String,
    last_name String,
    birthdate Date,
    other_phone String
)
ENGINE = MergeTree()
ORDER BY (pk);

-- Insert sample rows into crm.customers_a
INSERT INTO crm.customers_a (source_pk, pk, eml, fst_name, lst_name, birthdate, home_phone) VALUES
('src_a', 1001, 'alice@example.com', 'Alice', 'Smith', toDate('1990-01-01'), '555-0001'),
('src_a', 1002, 'bob@example.com', 'Robert', 'Johnson', toDate('1985-03-10'), '555-0002'),
('src_a', 1003, 'charlie@example.com', 'Charlie', 'Brown', toDate('1978-07-15'), '555-0003'),
('src_a', 1004, 'david@example.com', 'David', 'Oconnor', toDate('1992-11-05'), '555-0004'),
('src_a', 1005, 'shared@example.com', 'Sam', 'Lee', toDate('1988-09-09'), '555-0005');

-- Insert sample rows into sap.customers_b
INSERT INTO sap.customers_b (source_pk, pk, email, first_name, last_name, birthdate, other_phone) VALUES
('src_b', 2001, 'alice@example.com', 'Alicia', 'Smyth', toDate('1990-01-01'), '555-0001'),
('src_b', 2002, 'bob@example.com', 'Rob', 'Johnson', toDate('1985-03-10'), '555-0002'),
('src_b', 2003, 'charlie@example.com', 'Charles', 'Brown', toDate('1978-07-15'), '555-0003'),
('src_b', 2004, 'david@example.com', 'Davyd', 'Connor', toDate('1992-11-05'), '555-0004'),
('src_b', 2005, 'shared@example.com', 'Samuel', 'Lee', toDate('1988-09-09'), '555-9999');

-- A few more rows to show multiple entries within the same group and to build arrays
INSERT INTO crm.customers_a (source_pk, pk, eml, fst_name, lst_name, birthdate, home_phone) VALUES
('src_a', 1006, 'alice@example.com', 'Ally', 'Smith', toDate('1990-01-01'), '555-0001'),
('src_a', 1007, 'bob@example.com', 'Bobby', 'Johnsen', toDate('1985-03-10'), '555-0002');

INSERT INTO sap.customers_b (source_pk, pk, email, first_name, last_name, birthdate, other_phone) VALUES
('src_b', 2006, 'alice@example.com', 'Alyce', 'Smithe', toDate('1990-01-01'), '555-0001'),
('src_b', 2007, 'bob@example.com', 'Roberto', 'Johnson', toDate('1985-03-10'), '555-0002');


--the same group but not match string
INSERT INTO sap.customers_b (source_pk, pk, email, first_name, last_name, birthdate, other_phone) VALUES
('src_b', 20061, 'dzung@example.com', 'abcd', 'abcd', toDate('1990-01-01'), '555-0001')
;
INSERT INTO crm.customers_a (source_pk, pk, eml, fst_name, lst_name, birthdate, home_phone) VALUES
('src_a', 1007, 'dzung@example.com', 'abcd', 'abcd', toDate('1990-01-01'), '555-0001');

-- Quick selects to verify data (you can run these after executing the inserts)
-- SELECT * FROM crm.customers_a ORDER BY pk LIMIT 20;
-- SELECT * FROM sap.customers_b ORDER BY pk LIMIT 20;

-- Optional: create a simple EDW target table to store unified output (example)
CREATE TABLE IF NOT EXISTS edw.customers
(
    email String,
    phone String,
    birthdate Date,
    first_name String,
    last_name String,
    source_ids Array(String),
    source_pks Array(String)
)
ENGINE = MergeTree()
ORDER BY (email, phone, birthdate);

-- End of script
