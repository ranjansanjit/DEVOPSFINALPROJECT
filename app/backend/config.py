import os

class Config:
    DB_USER = "postgres"
    DB_PASSWORD = "postgres"   # must match docker-compose env
    DB_HOST = "db"             # service name from docker-compose
    DB_PORT = "5432"
    DB_NAME = "contactdb"

    SQLALCHEMY_DATABASE_URI = (
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )