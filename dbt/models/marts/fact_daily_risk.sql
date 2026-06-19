{{ config(materialized='table', schema='analytics') }}

WITH daily_txns AS (
    SELECT 
        DATE(txn_date) AS report_date,
        COUNT(txn_id) AS total_transactions,
        SUM(ABS(amount)) AS total_volume,
        SUM(CASE WHEN high_value_flag THEN 1 ELSE 0 END) AS high_value_count,
        SUM(CASE WHEN potential_fraud_flag THEN 1 ELSE 0 END) AS flagged_count
    FROM {{ ref('stg_transactions') }}
    GROUP BY 1
)

SELECT 
    report_date,
    total_transactions,
    total_volume,
    high_value_count,
    flagged_count,
    (flagged_count::float / NULLIF(total_transactions, 0)) * 100 AS fraud_rate_pct,
    NOW() AS loaded_at
FROM daily_txns
ORDER BY report_date DESC;