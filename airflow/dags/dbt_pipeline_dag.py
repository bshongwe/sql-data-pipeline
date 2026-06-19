from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['alerts@example.com'],
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='fintech_dbt_pipeline',
    default_args=default_args,
    description='Fintech Payments Data Pipeline',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
) as dag:

    dbt_run = BashOperator(
        task_id='dbt_run_and_test',
        bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir . && dbt test',
        env={'DBT_PROFILES_DIR': '/opt/airflow/dbt'}
    )

    dbt_docs = BashOperator(
        task_id='dbt_generate_docs',
        bash_command='cd /opt/airflow/dbt && dbt docs generate',
    )

    dbt_run >> dbt_docs