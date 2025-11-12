TRUNCATE TABLE unify.matched;
TRUNCATE TABLE unify.mapping_source;
TRUNCATE TABLE edw.customer;

INSERT INTO unify.matched (
    email, 
    phone, 
    birthdate,
    last_name_arr, 
    first_name_arr
  , source_id_arr, source_pk_arr,
    min_distance_last_name, 
    min_distance_first_name
)
WITH
-- 1) Union all sources into a canonical set of columns (one row per source record)
all_sources AS (
  SELECT
    'customers_a' AS source_name,
    crm.customers_a.source_pk AS source_id,
    crm.customers_a.pk AS source_pk
    
      ,crm.customers_a.eml AS email
      ,crm.customers_a.home_phone AS phone
      ,crm.customers_a.birthdate AS birthdate
      ,crm.customers_a.lst_name AS last_name
      ,crm.customers_a.fst_name AS first_name
  FROM crm.customers_a
  UNION ALL
  SELECT
    'customers_b' AS source_name,
    sap.customers_b.source_pk AS source_id,
    sap.customers_b.pk AS source_pk
    
      ,sap.customers_b.email AS email
      ,sap.customers_b.other_phone AS phone
      ,sap.customers_b.birthdate AS birthdate
      ,sap.customers_b.last_name AS last_name
      ,sap.customers_b.first_name AS first_name
  FROM sap.customers_b
),

-- 2) Aggregate rows into groups defined by exact matching fields and build arrays for fuzzy fields and source identifiers
mapped AS (
  SELECT
      email, 
      phone, 
      birthdate, 
        groupArray(last_name) AS last_name_arr, 
        groupArray(first_name) AS first_name_arr, 
    groupArray(source_id) AS source_id_arr,
    groupArray(source_pk) AS source_pk_arr
  FROM all_sources
  GROUP BY
      email, 
      phone, 
      birthdate
),



min_distance_last_name AS (
  SELECT
      email, 
      phone, 
      birthdate,
    min(levenshteinDistance(a, b)) AS min_distance_last_name
  FROM mapped
  ARRAY JOIN last_name_arr AS a
  ARRAY JOIN last_name_arr AS b
  WHERE a < b
  GROUP BY
      email, 
      phone, 
      birthdate
),

step_1 AS (
  SELECT p.*, md.min_distance_last_name
  FROM mapped AS p
  LEFT JOIN min_distance_last_name AS md USING (email, phone, birthdate)
),

min_distance_first_name AS (
  SELECT
      email, 
      phone, 
      birthdate,
    min(levenshteinDistance(a, b)) AS min_distance_first_name
  FROM step_1
  ARRAY JOIN first_name_arr AS a
  ARRAY JOIN first_name_arr AS b
  WHERE a < b
  GROUP BY
      email, 
      phone, 
      birthdate
),

step_2 AS (
  SELECT p.*, md.min_distance_first_name
  FROM step_1 AS p
  LEFT JOIN min_distance_first_name AS md USING (email, phone, birthdate)
)

-- 4) Final: select from the last step (or mapped if no fuzzy fields) to insert into tmp_unified
SELECT *
FROM step_2 AS unified;


/*
  Check if the group is match or not
*/
ALTER TABLE unify.matched
UPDATE
  is_matched = 1
  , unified_ids = [generateUUIDv4()]
WHERE
    min_distance_last_name <= 2  AND 
    min_distance_first_name <= 2 
;

ALTER TABLE unify.matched
UPDATE
  is_matched = 0
  , unified_ids = arrayMap(x -> generateUUIDv4(), range(length(source_id_arr)))
WHERE
    min_distance_last_name > 2  OR 
    min_distance_first_name > 2 
;

/*
  For each group, generate UUID and insert into unified table
*/

INSERT INTO unify.mapping_source
(
  group_id,
  source_id,
  source_pk
)
WITH source AS (
  SELECT
    CASE 
      WHEN is_matched = 1 THEN unified_ids[1]
      ELSE unified_ids[index]
    END AS group_id,
    source_id_arr[index] AS source_id,
    source_pk_arr[index] AS source_pk
  FROM unify.matched
  ARRAY JOIN arrayEnumerate(source_id_arr) AS index
)
SELECT * FROM source;

/*
  Insert into Unified table
*/
INSERT INTO edw.customer
(
  user_profile_id,
  --exact rule
      email, 
      phone, 
      birthdate, 

  --fuzzy field
      last_name, 
      first_name
)
WITH source AS (
  SELECT
    arrayJoin(unified_ids) AS user_profile_id,
      email, 
      phone, 
      birthdate, 
      
        arrayMin(last_name_arr) AS last_name
      
      , 
      
        first_name_arr[indexOf(source_id_arr, 'src_a')] AS first_name
      
      
  FROM unify.matched
)
SELECT * FROM source;