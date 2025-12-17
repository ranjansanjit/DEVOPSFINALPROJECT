import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from config import Config

def create_database():
    conn = psycopg2.connect(
        dbname="postgres",  # default system DB
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        host=Config.DB_HOST,
        port=Config.DB_PORT
    )

    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cursor = conn.cursor()

    cursor.execute(
        f"SELECT 1 FROM pg_database WHERE datname='{Config.DB_NAME}'"
    )
    exists = cursor.fetchone()

    if not exists:
        cursor.execute(f"CREATE DATABASE {Config.DB_NAME}")
        print(f"Database '{Config.DB_NAME}' created.")
    else:
        print(f"Database '{Config.DB_NAME}' already exists.")

    cursor.close()
    conn.close()
