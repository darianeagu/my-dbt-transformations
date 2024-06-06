{{ config(
    materialized='table'
) }}

SELECT
    orb_site,
    timezone
FROM
    {{ source('raw_source') }}


