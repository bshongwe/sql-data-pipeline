#!/usr/bin/env python3
"""
Main Entry Point for Fintech Data Pipeline
Orchestrates ingestion + dbt transformations locally or in CI.
"""

import os
import subprocess
import sys
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def run_command(cmd, cwd=None):
    """Run shell command with logging."""
    logger.info(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        logger.error(f"Command failed: {result.stderr}")
        sys.exit(1)
    logger.info(result.stdout)
    return result

def main():
    logger.info("=== Starting Fintech Data Pipeline ===")
    
    project_root = os.path.dirname(os.path.abspath(__file__))
    
    # 1. Ingestion
    logger.info("Step 1: Data Ingestion to Bronze")
    run_command(f"python3 scripts/ingest_transactions.py 50", cwd=project_root)
    
    # 2. dbt Transformations (Incremental)
    logger.info("Step 2: dbt Run & Test")
    dbt_dir = os.path.join(project_root, "dbt")
    run_command("dbt run --select staging marts --profiles-dir .", cwd=dbt_dir)
    run_command("dbt test --select staging marts --profiles-dir .", cwd=dbt_dir)
    
    # 3. Optional: Generate docs
    run_command("dbt docs generate --profiles-dir .", cwd=dbt_dir)
    
    logger.info("=== Pipeline completed successfully! ===")
    logger.info(f"Check data in Postgres or Airflow UI.")

if __name__ == "__main__":
    main()