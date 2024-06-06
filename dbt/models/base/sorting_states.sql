{{ config(
    materialized='table'
) }}

SELECT
    meta_orb_site,
    meta_machine_name,
    meta_event_time,
    meta_deploy_mode,
    meta_received_time,
    phase_group_id,
    start_time,
    end_time,
    state
FROM
    {{ source('raw_source') }}

