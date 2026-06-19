#!/usr/bin/env python3
"""
Fintech Ingestion Script - Simulates loading new transactions from payment gateway / API into Bronze layer.
Production-grade: Idempotent, batch, logging, error handling.
"""

import os
import sys
import logging
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import execute_values

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

DB_CONFIG = {
    'dbname': os.getenv('POSTGRES_DB', 'pipeline_db'),
    'user': os.getenv('POSTGRES_USER', 'postgres'),
    'password': os.getenv('POSTGRES_PASSWORD', 'postgres'),
    'host': os.getenv('POSTGRES_HOST', 'postgres'),
    'port': os.getenv('POSTGRES_PORT', '5432')
}

def generate_sample_transactions(num=50):
    """Generate realistic fintech transactions for ingestion."""
    import random
    transactions = []
    base_time = datetime.now() - timedelta(hours=1)
    
    for i in range(num):
        txn = {
            'txn_id': f'TXN{datetime.now().strftime("%Y%m%d%H%M")}{i:04d}',
            'customer_id': random.choice(['CUST001', 'CUST002', 'CUST003']),
            'account_id': random.choice(['ACC001', 'ACC002']),
            'txn_date': (base_time - timedelta(minutes=random.randint(0, 120))).isoformat(),
            'amount': round(random.uniform(-500, 5000), 2),
            'currency': 'USD',
            'txn_type': random.choice(['purchase', 'transfer', 'refund', 'withdrawal']),
            'merchant_name': random.choice(['Amazon', 'Starbucks', 'Internal Transfer', 'Uber']),
            'status': random.choice(['completed', 'pending', 'flagged']),
            'device_ip': f'192.168.{random.randint(1,255)}.{random.randint(1,255)}',
            'user_agent': 'Mozilla/5.0 (Fintech Simulator)'
        }
        transactions.append(txn)
    return transactions

def ingest_to_bronze(transactions):
    """Load transactions into bronze.raw_transactions (idempotent)."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    try:
        # Prepare data for batch insert
        values = [
            (
                t['txn_id'], t['customer_id'], t['account_id'], t['txn_date'],
                t['amount'], t['currency'], t['txn_type'], t['merchant_name'],
                t['status'], t['device_ip'], t['user_agent']
            ) for t in transactions
        ]
        
        insert_query = """
        INSERT INTO bronze.raw_transactions 
            (txn_id, customer_id, account_id, txn_date, amount, currency, 
             txn_type, merchant_name, status, device_ip, user_agent)
        VALUES %s
        ON CONFLICT (txn_id) DO NOTHING
        """
        
        execute_values(cur, insert_query, values)
        conn.commit()
        logger.info(f"Successfully ingested {len(transactions)} transactions into Bronze layer.")
        
    except Exception as e:
        conn.rollback()
        logger.error(f"Ingestion failed: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    num_txns = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    txns = generate_sample_transactions(num_txns)
    ingest_to_bronze(txns)
    logger.info("Ingestion completed successfully.")