{% macro handle_dates(date_field) %}

CAST(
    TRY_TO_DATE(
        {{ date_field }}::VARCHAR,
        IFF(
            CONTAINS({{ date_field }}::VARCHAR, '-') AND CHARINDEX(':', {{ date_field }}::VARCHAR) = 14,
            'YYYY-MM-DD HH24:MI:SS.FF9',
        ) AS DATE
)
