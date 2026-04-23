-- Creates the hq_test database alongside the main yumyums database.
-- Mounted as a docker-entrypoint-initdb.d script so it runs on first container start.
SELECT 'CREATE DATABASE hq_test'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hq_test')\gexec
