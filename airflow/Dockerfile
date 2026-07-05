FROM apache/airflow:2.10.0

# Switch to root to install system packages
USER root

# Install system dependencies for psycopg2
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
        libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to airflow user
USER airflow

# Install Python packages
RUN pip install --no-cache-dir psycopg2-binary