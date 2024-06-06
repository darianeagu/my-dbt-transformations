{{ config(
    materialized='incremental',
    unique_key=['orb_site', 'machine_name', 'deploy_mode', 'start_time'],
    incremental_strategy='insert_overwrite'
) }}

WITH reference_time AS (
    SELECT
        COALESCE(
            MAX(end_time) OVER (),
            TIMESTAMP '1970-01-01 00:00:00 UTC'
        ) - INTERVAL '2 days' AS reference_time
),

SELECT
    hs.meta_orb_site AS orb_site,
    hs.meta_machine_name AS machine_name,
    hs.meta_deploy_mode AS deploy_mode,
    hs.start_time,
    hs.end_time,
    hs.start_time AT TIME ZONE osi.timezone AS local_start_time,
    hs.end_time AT TIME ZONE osi.timezone AS local_end_time,

    -- aggregate units_unloaded
    COALESCE(SUM(ui.item_id), 0) AS units_unloaded,

    -- aggregate all_sort_attempts
    COALESCE(COUNT(sa.phase_group_id), 0) AS all_sort_attempts,

    -- aggregate all_complete_sort_attempts
    COALESCE(SUM(CASE WHEN sa.outcome = 'complete' THEN 1 ELSE 0 END), 0) AS all_complete_sort_attempts,

    -- aggregate operating_seconds (exclude downtime states)
    COALESCE(SUM(EXTRACT(EPOCH FROM (
        LEAST(hs.end_time, ss.end_time) - GREATEST(hs.start_time, ss.start_time)
    ))), 0) AS operating_seconds,

    -- aggregate sorting_seconds
    COALESCE(SUM(CASE WHEN ss.state = 'sorting' THEN EXTRACT(EPOCH FROM (
        LEAST(hs.end_time, ss.end_time) - GREATEST(hs.start_time, ss.start_time)
    )) ELSE 0 END), 0) AS sorting_seconds,

    -- aggregate blocked_seconds
    COALESCE(SUM(CASE WHEN ss.state = 'blocked' THEN EXTRACT(EPOCH FROM (
        LEAST(hs.end_time, ss.end_time) - GREATEST(hs.start_time, ss.start_time)
    )) ELSE 0 END), 0) AS blocked_seconds

FROM hourly_slices hs
LEFT JOIN sorting_states_local ss
    ON hs.meta_orb_site = ss.meta_orb_site
    AND hs.meta_machine_name = ss.meta_machine_name
    AND hs.meta_deploy_mode = ss.meta_deploy_mode
    AND hs.start_time < ss.end_time
    AND hs.end_time > ss.start_time
LEFT JOIN sort_attempts_local sa
    ON hs.meta_orb_site = sa.meta_orb_site
    AND hs.meta_machine_name = sa.meta_machine_name
    AND hs.meta_deploy_mode = sa.meta_deploy_mode
    AND hs.start_time <= sa.end_time
    AND hs.end_time >= sa.start_time
LEFT JOIN {{ ref('unload_items') }} ui
    ON ui.unload_id IN (
        SELECT u.unload_id
        FROM unloads_local u
        WHERE u.meta_orb_site = hs.meta_orb_site
        AND u.meta_machine_name = hs.meta_machine_name
        AND u.meta_deploy_mode = hs.meta_deploy_mode
        AND hs.start_time <= u.event_time
        AND hs.end_time >= u.event_time
    )
GROUP BY hs.meta_orb_site, hs.meta_machine_name, hs.meta_deploy_mode, hs.start_time, hs.end_time, osi.timezone
