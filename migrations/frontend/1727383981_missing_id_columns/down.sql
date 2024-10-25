-- the down migrations don't undo the setting of tenant_id since that is useful data.

ALTER TABLE names DROP CONSTRAINT IF EXISTS names_pkey;
ALTER TABLE names ADD CONSTRAINT names_pkey PRIMARY KEY (name);
ALTER TABLE names ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE names ALTER COLUMN tenant_id DROP NOT NULL;
COMMIT AND CHAIN;

ALTER TABLE global_state DROP CONSTRAINT IF EXISTS global_state_site_id_unique;
ALTER TABLE global_state DROP CONSTRAINT IF EXISTS global_state_pkey;
ALTER TABLE global_state DROP COLUMN IF EXISTS id;
ALTER TABLE global_state ADD CONSTRAINT global_state_pkey PRIMARY KEY (site_id);
ALTER TABLE global_state ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE global_state ALTER COLUMN tenant_id DROP NOT NULL;
COMMIT AND CHAIN;

ALTER TABLE discussion_mail_reply_tokens DROP CONSTRAINT IF EXISTS discussion_mail_reply_tokens_pkey;
ALTER TABLE discussion_mail_reply_tokens ADD CONSTRAINT discussion_mail_reply_tokens_pkey PRIMARY KEY (token);
ALTER TABLE discussion_mail_reply_tokens ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE discussion_mail_reply_tokens ALTER COLUMN tenant_id DROP NOT NULL;
COMMIT AND CHAIN;

ALTER TABLE feature_flags DROP CONSTRAINT IF EXISTS feature_flags_pkey;
ALTER TABLE feature_flags ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (flag_name);
ALTER TABLE feature_flags ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE feature_flags ALTER COLUMN tenant_id DROP NOT NULL;
COMMIT AND CHAIN;

ALTER TABLE syntactic_scip_last_index_scan DROP CONSTRAINT IF EXISTS syntactic_scip_last_index_scan_pkey;
ALTER TABLE syntactic_scip_last_index_scan ADD CONSTRAINT syntactic_scip_last_index_scan_pkey PRIMARY KEY (repository_id);
ALTER TABLE syntactic_scip_last_index_scan ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE syntactic_scip_last_index_scan ALTER COLUMN tenant_id DROP NOT NULL;
COMMIT AND CHAIN;
