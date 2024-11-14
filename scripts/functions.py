import os
import subprocess
import time

import psycopg2

dbname = os.getenv('POSTGRES_DB', 'metchem')
user = os.getenv('POSTGRES_USER', 'postgres')
host = os.getenv('POSTGRES_IP', '127.0.0.1')
password = os.getenv('POSTGRES_PASSWORD', 'DATABASE_PASSWORD')
metchemro_password = os.getenv('METCHEMRO_PASSWORD', 'metchemro')


def wait_for_database():
    while True:
        try:
            conn = psycopg2.connect(dbname='postgres', user=user, password=password, host=host)
            conn.close()
            break
        except psycopg2.OperationalError:
            print("Postgres is unavailable - sleeping")
            time.sleep(1)
    print("Postgres is up - executing command")


def check_database_exists():
    conn = psycopg2.connect(dbname='postgres', user=user, password=password, host=host)
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,))
    exists = cur.fetchone() is not None
    cur.close()
    conn.close()
    return exists


def check_log_folder(log_type):
    log_folder = os.getenv('LOG_FOLDER')
    if log_folder:
        log_path = os.path.join(log_folder, log_type)
        if os.path.exists(log_path):
            subprocess.run(['rm', '-rf', log_path])
        os.makedirs(log_path)
        return log_path


def init_database():
    conn = psycopg2.connect(dbname=dbname, user=user, host=host)
    cur = conn.cursor()
    with open('/schema/MetChemSchema.sql', 'r') as f:
        cur.execute(f.read())
    cur.close()
    conn.commit()
    conn.close()
    check_database_user()


def check_database_user():
    conn = psycopg2.connect(dbname=dbname, user=user, host=host)
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_roles WHERE rolname = 'metchemro'")
    user_exists = cur.fetchone() is not None
    if not user_exists:
        cur.execute("CREATE USER metchemro WITH PASSWORD %s", (metchemro_password,))
        cur.execute("GRANT SELECT ON compound TO metchemro")
        cur.execute("GRANT SELECT ON substance TO metchemro")
        cur.execute("GRANT SELECT ON name TO metchemro")
        cur.execute("GRANT SELECT ON library TO metchemro")
    cur.close()
    conn.commit()
    conn.close()


def write_entries(file, library_id):
    conn = psycopg2.connect(dbname=dbname, user=user, host=host)
    cur = conn.cursor()
    cur.execute("SELECT max(compound_id) FROM compound")
    currentcompoundid = cur.fetchone()[0] or 0
    currentcompoundid += 1

    with open(file, 'r') as f:
        lines = f.readlines()
    numlines = len(lines)

    # compound table
    compound_data = [
        (currentcompoundid + i, *line.split('|')[1:8], line.split('|')[9])
        for i, line in enumerate(lines)
    ]
    cur.executemany(
        "COPY compound FROM STDIN WITH (FORMAT CSV, DELIMITER '|')",
        compound_data
    )

    # substance table
    substance_data = [
        (currentcompoundid + i, library_id, currentcompoundid + i, line.split('|')[0])
        for i, line in enumerate(lines)
    ]
    cur.executemany(
        "COPY substance FROM STDIN WITH (FORMAT CSV, DELIMITER '|')",
        substance_data
    )

    # name table
    name_data = [
        (line.split('|')[8].replace('"', '').replace("'", "''"), currentcompoundid + i)
        for i, line in enumerate(lines)
    ]
    cur.executemany(
        "COPY name FROM STDIN WITH (FORMAT CSV, DELIMITER '|')",
        name_data
    )

    cur.close()
    conn.commit()
    conn.close()


def create_index():
    conn = psycopg2.connect(dbname=dbname, user=user, host=host)
    cur = conn.cursor()
    with open('/schema/MetChemIndex.sql', 'r') as f:
        cur.execute(f.read())
    cur.close()
    conn.commit()
    conn.close()


def remove_duplicates():
    conn = psycopg2.connect(dbname=dbname, user=user, host=host)
    cur = conn.cursor()
    query = """
    BEGIN;
    CREATE TEMP TABLE duplicates AS
    SELECT * FROM (
        SELECT inchi_key, ROW_NUMBER() OVER(PARTITION BY inchi_key ORDER BY inchi_key ASC) AS Row
        FROM compound
    ) dups WHERE dups.Row > 1;
    CREATE OR REPLACE FUNCTION check_duplicates() RETURNS VOID AS $$
    DECLARE
        key duplicates.inchi_key%TYPE;
    BEGIN
        FOR key IN SELECT inchi_key FROM duplicates
        LOOP
            UPDATE substance SET compound_id = (
                SELECT compound_id FROM compound WHERE inchi_key = key LIMIT 1
            ) WHERE compound_id IN (
                SELECT compound_id FROM compound WHERE inchi_key = key
            );
            DELETE FROM compound WHERE inchi_key = key AND compound_id != (
                SELECT compound_id FROM compound WHERE inchi_key = key LIMIT 1
            );
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;
    SELECT check_duplicates();
    COMMIT;
    """
    cur.execute(query)
    cur.close()
    conn.commit()
    conn.close()
