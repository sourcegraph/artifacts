ALTER TABLE tenants ALTER COLUMN id DROP DEFAULT;

DROP SEQUENCE IF EXISTS tenants_id_seq;
