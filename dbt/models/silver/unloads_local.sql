{{ config(
    materialized='ephemeral'
) }}

unloads_local AS (
    SELECT
        u.unload_id,
        u.order_id,
        u.event_time,
        u.meta_orb_site,
        u.meta_machine_name,
        u.meta_deploy_mode,
        u.meta_event_time AT TIME ZONE osi.timezone AS local_event_time
    FROM {{ ref('unloads') }} u
    JOIN {{ ref('orb_site_info') }} osi ON u.meta_orb_site = osi.orb_site
),

SELECT *
FROM unloads_local
