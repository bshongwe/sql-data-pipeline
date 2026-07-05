-- Create airflow database
CREATE DATABASE airflow;

-- Create schemas for medallion architecture
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Fintech Bronze Layer: Raw source data
CREATE TABLE IF NOT EXISTS bronze.raw_transactions (
    id SERIAL PRIMARY KEY,
    txn_id VARCHAR(100) UNIQUE,
    customer_id VARCHAR(50),
    account_id VARCHAR(50),
    txn_date TIMESTAMP,
    amount NUMERIC(15,4),
    currency VARCHAR(3) DEFAULT 'USD',
    txn_type VARCHAR(20),
    merchant_name VARCHAR(100),
    status VARCHAR(20),
    device_ip VARCHAR(45),
    user_agent TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.raw_accounts (
    id SERIAL PRIMARY KEY,
    account_id VARCHAR(50) UNIQUE,
    customer_id VARCHAR(50),
    account_type VARCHAR(20),
    balance NUMERIC(15,4),
    status VARCHAR(20),
    opened_date DATE,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.raw_customers (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE,
    full_name VARCHAR(100),
    email VARCHAR(100),
    kyc_status VARCHAR(20),
    country VARCHAR(2),
    signup_date DATE,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed sample fintech data
INSERT INTO bronze.raw_transactions (txn_id, customer_id, account_id, txn_date, amount, txn_type, merchant_name, status, device_ip)
VALUES 
('TXN001', 'CUST001', 'ACC001', NOW() - INTERVAL '1 day', 1250.75, 'purchase', 'Amazon', 'completed', '192.168.1.1'),
('TXN002', 'CUST002', 'ACC002', NOW() - INTERVAL '2 hours', 450.00, 'transfer', 'Internal', 'completed', '10.0.0.5'),
('TXN003', 'CUST001', 'ACC001', NOW() - INTERVAL '30 minutes', -89.99, 'refund', 'Walmart', 'completed', '172.16.0.1')
ON CONFLICT DO NOTHING;

INSERT INTO bronze.raw_accounts (account_id, customer_id, account_type, balance, status, opened_date)
VALUES 
('ACC001', 'CUST001', 'checking', 5420.50, 'active', '2023-01-15'),
('ACC002', 'CUST002', 'savings', 12500.00, 'active', '2023-06-01')
ON CONFLICT DO NOTHING;

INSERT INTO bronze.raw_customers (customer_id, full_name, email, kyc_status, country, signup_date)
VALUES 
('CUST001', 'Alice Johnson', 'alice@example.com', 'verified', 'US', '2023-01-10'),
('CUST002', 'Bob Smith', 'bob@example.com', 'pending', 'CA', '2023-05-20')
ON CONFLICT DO NOTHING;
