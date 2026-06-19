-- Gold: Customer Dimension with KYC, RFM, and Risk Profile
{{ config(materialized='table') }}

WITH txns AS (
    SELECT * FROM {{ ref('stg_transactions') }}
),
customers AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        c.kyc_status,
        c.country,
        c.signup_date,
        MIN(t.txn_date) AS first_txn_date,
        MAX(t.txn_date) AS last_txn_date,
        COUNT(t.txn_id) AS total_transactions,
        SUM(ABS(t.amount)) AS total_volume,
        AVG(t.amount) AS avg_txn_amount,
        SUM(CASE WHEN t.high_value_flag THEN 1 ELSE 0 END) AS high_value_txns,
        SUM(CASE WHEN t.potential_fraud_flag THEN 1 ELSE 0 END) AS flagged_txns
    FROM {{ source('bronze', 'raw_customers') }} c
    LEFT JOIN txns t ON c.customer_id = t.customer_id
    GROUP BY c.customer_id, c.full_name, c.email, c.kyc_status, c.country, c.signup_date
)

SELECT
    *,
    -- RFM-like segmentation
    CASE 
        WHEN total_volume > 50000 OR high_value_txns > 5 THEN 'High Value / VIP'
        WHEN total_transactions > 20 THEN 'Active'
        ELSE 'New / Low Activity'
    END AS customer_segment,
    -- Risk profile
    CASE 
        WHEN flagged_txns > 0 OR kyc_status != 'verified' THEN 'High Risk'
        WHEN total_volume > 100000 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_profile,
    NOW() AS last_updated
FROM customers;