{{ config(
    materialized='ephemeral'
) }}

WITH sorting_states_local AS (
    SELECT
        ss.phase_group_id,
        ss.start_time,
        ss.end_time,
        ss.state,
        ss.meta_orb_site,
        ss.meta_machine_name,
        ss.meta_deploy_mode,
        ss.meta_event_time AT TIME ZONE osi.timezone AS local_event_time
    FROM {{ ref('sorting_states') }} ss
    JOIN {{ ref('orb_site_info') }} osi ON ss.meta_orb_site = osi.orb_site
),

SELECT *
FROM sorting_states_local