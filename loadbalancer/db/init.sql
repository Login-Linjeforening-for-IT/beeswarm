DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'beeswarm') THEN
        CREATE DATABASE "beeswarm";
    END IF;
END $$;

\c "beeswarm"

DO $$
DECLARE
    user_password text;
BEGIN
    user_password := current_setting('db_password', true);

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'beeswarm') THEN
        EXECUTE format('CREATE USER "beeswarm" WITH ENCRYPTED PASSWORD %L', user_password);
        EXECUTE 'GRANT ALL PRIVILEGES ON DATABASE "beeswarm" TO "beeswarm"';
    END IF;
END $$;

-- Links
CREATE TABLE IF NOT EXISTS links (
    id TEXT PRIMARY KEY,
    path TEXT NOT NULL,
    visits INT NOT NULL DEFAULT 0,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
