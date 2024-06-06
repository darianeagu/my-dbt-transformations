{{ config(
    materialized='ephemeral'
) }}

WITH sort_attempts_local AS (
    SELECT
        sa.phase_group_id,
        sa.start_time,
        sa.end_time,
        sa.outcome,
        sa.terminating_error,
        sa.meta_orb_site,
        sa.meta_machine_name,
        sa.meta_deploy_mode,
        sa.meta_event_time AT TIME ZONE osi.timezone AS local_event_time
    FROM {{ ref('sort_attempts') }} sa
    JOIN {{ ref('orb_site_info') }} osi ON sa.meta_orb_site = osi.orb_site
),

SELECT *
FROM sort_attempts_local
