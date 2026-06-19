-- Staging: Cleaned transactions (Silver layer) - Incremental
{{ config(
    materialized='incremental',
    unique_key='txn_id',
    incremental_strategy='append'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_transactions') }}
)

SELECT
    txn_id,
    customer_id,
    account_id,
    txn_date,
    amount,
    currency,
    txn_type,
    merchant_name,
    status,
    device_ip,
    user_agent,
    loaded_at,
    -- Basic fraud enrichment
    CASE WHEN amount > 10000 THEN true ELSE false END AS high_value_flag,
    CASE WHEN status = 'flagged' OR device_ip IS NULL THEN true ELSE false END AS potential_fraud_flag
FROM source
WHERE status NOT IN ('failed')

{% if is_incremental() %}
  AND txn_date > (SELECT MAX(txn_date) FROM {{ this }})
{% endif %};