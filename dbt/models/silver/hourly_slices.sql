{{ config(
    materialized='ephemeral'
) }}

WITH hourly_slices AS (
    SELECT
        generate_series(
            MIN(ss.start_time) AT TIME ZONE osi.timezone,
            MAX(ss.end_time) AT TIME ZONE osi.timezone,
            '1 hour'::interval
        ) AS start_time,
        generate_series(
            MIN(ss.start_time) AT TIME ZONE osi.timezone,
            MAX(ss.end_time) AT TIME ZONE osi.timezone,
            '1 hour'::interval
        ) + interval '1 hour' AS end_time,
        ss.meta_orb_site,
        ss.meta_machine_name,
        ss.meta_deploy_mode
    FROM {{ ref('sorting_states') }} ss
    JOIN {{ ref('orb_site_info') }} osi ON ss.meta_orb_site = osi.orb_site
    GROUP BY ss.meta_orb_site, ss.meta_machine_name, ss.meta_deploy_mode
)

SELECT *
FROM hourly_slices
