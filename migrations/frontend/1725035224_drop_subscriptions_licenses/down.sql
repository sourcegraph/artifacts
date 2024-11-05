CREATE TABLE IF NOT EXISTS product_subscriptions (
    id uuid NOT NULL PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users(id),
    billing_subscription_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    archived_at timestamp with time zone,
    account_number text,
    cody_gateway_enabled boolean DEFAULT false NOT NULL,
    cody_gateway_chat_rate_limit bigint,
    cody_gateway_chat_rate_interval_seconds integer,
    cody_gateway_embeddings_api_rate_limit bigint,
    cody_gateway_embeddings_api_rate_interval_seconds integer,
    cody_gateway_embeddings_api_allowed_models text[],
    cody_gateway_chat_rate_limit_allowed_models text[],
    cody_gateway_code_rate_limit bigint,
    cody_gateway_code_rate_interval_seconds integer,
    cody_gateway_code_rate_limit_allowed_models text[],
    tenant_id integer DEFAULT 1 REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON COLUMN product_subscriptions.cody_gateway_embeddings_api_rate_limit IS 'Custom requests per time interval allowed for embeddings';

COMMENT ON COLUMN product_subscriptions.cody_gateway_embeddings_api_rate_interval_seconds IS 'Custom time interval over which the embeddings rate limit is applied';

COMMENT ON COLUMN product_subscriptions.cody_gateway_embeddings_api_allowed_models IS 'Custom override for the set of models allowed for embedding';

CREATE TABLE IF NOT EXISTS product_licenses (
    id uuid NOT NULL PRIMARY KEY,
    product_subscription_id uuid NOT NULL REFERENCES product_subscriptions(id),
    license_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    license_version integer,
    license_tags text[],
    license_user_count integer,
    license_expires_at timestamp with time zone,
    access_token_enabled boolean DEFAULT true NOT NULL,
    site_id uuid,
    license_check_token bytea,
    revoked_at timestamp with time zone,
    salesforce_sub_id text,
    salesforce_opp_id text,
    revoke_reason text,
    tenant_id integer DEFAULT 1 REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON COLUMN product_licenses.access_token_enabled IS 'Whether this license key can be used as an access token to authenticate API requests';

CREATE UNIQUE INDEX IF NOT EXISTS product_licenses_license_check_token_idx ON product_licenses USING btree (license_check_token);
