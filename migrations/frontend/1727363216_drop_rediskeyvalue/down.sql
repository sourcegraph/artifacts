CREATE TABLE IF NOT EXISTS redis_key_value (
    namespace text NOT NULL,
    key text NOT NULL,
    value bytea NOT NULL,
    tenant_id integer,
    PRIMARY KEY (namespace, key) INCLUDE (value),
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE
);
