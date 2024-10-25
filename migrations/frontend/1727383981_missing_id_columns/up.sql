-- we migrate all tables that are missing a primary key or need tenant_id to
-- be included. We currently exclude two tables:
-- - codeintel_commit_dates :: very large (7 million rows on dotcom)
-- - telemetry_events_export_queue :: high churn so hard to get hold of locks

ALTER TABLE names ALTER COLUMN tenant_id SET DEFAULT (COALESCE(current_setting('app.current_tenant', true), '1'))::integer;
COMMIT AND CHAIN;
UPDATE names SET tenant_id = 1 WHERE tenant_id IS NULL;
ALTER TABLE names DROP CONSTRAINT IF EXISTS names_pkey;
ALTER TABLE names ADD PRIMARY KEY (name, tenant_id);
COMMIT AND CHAIN;

UPDATE global_state SET tenant_id = 1 WHERE tenant_id IS NULL;
ALTER TABLE global_state ADD COLUMN IF NOT EXISTS id SERIAL NOT NULL;
ALTER TABLE global_state DROP CONSTRAINT IF EXISTS global_state_pkey;
ALTER TABLE global_state ADD PRIMARY KEY (id);
DO $$
BEGIN

  BEGIN
    ALTER TABLE global_state ADD CONSTRAINT global_state_site_id_unique UNIQUE (site_id, tenant_id);
  EXCEPTION
    WHEN duplicate_table THEN  -- postgres raises duplicate_table at surprising times. Ex.: for UNIQUE constraints.
    WHEN duplicate_object THEN
      RAISE NOTICE 'Table constraint global_state_site_id_unique already exists, skipping';
  END;

END $$;
COMMIT AND CHAIN;

UPDATE discussion_mail_reply_tokens SET tenant_id = 1 WHERE tenant_id IS NULL;
ALTER TABLE discussion_mail_reply_tokens DROP CONSTRAINT IF EXISTS discussion_mail_reply_tokens_pkey;
ALTER TABLE discussion_mail_reply_tokens ADD PRIMARY KEY (token, tenant_id);
ALTER TABLE discussion_mail_reply_tokens ALTER COLUMN tenant_id SET DEFAULT (COALESCE(current_setting('app.current_tenant', true), '1'))::integer;
COMMIT AND CHAIN;

ALTER TABLE feature_flags ALTER COLUMN tenant_id SET DEFAULT (COALESCE(current_setting('app.current_tenant', true), '1'))::integer;
COMMIT AND CHAIN;
UPDATE feature_flags SET tenant_id = 1 WHERE tenant_id IS NULL;
ALTER TABLE feature_flags DROP CONSTRAINT IF EXISTS feature_flags_pkey;
ALTER TABLE feature_flags ADD PRIMARY KEY (flag_name, tenant_id);
COMMIT AND CHAIN;

ALTER TABLE syntactic_scip_last_index_scan ALTER COLUMN tenant_id SET DEFAULT (COALESCE(current_setting('app.current_tenant', true), '1'))::integer;
COMMIT AND CHAIN;
UPDATE syntactic_scip_last_index_scan SET tenant_id = 1 WHERE tenant_id IS NULL;
ALTER TABLE syntactic_scip_last_index_scan DROP CONSTRAINT IF EXISTS syntactic_scip_last_index_scan_pkey;
ALTER TABLE syntactic_scip_last_index_scan ADD PRIMARY KEY (repository_id, tenant_id);
COMMIT AND CHAIN;
