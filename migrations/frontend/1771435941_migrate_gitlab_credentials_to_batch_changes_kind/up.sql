-- For each user_credentials row that references an AUTH external account on
-- GitLab, duplicate the external account with kind = 'BATCH_CHANGES' and
-- re-point the credential to the new row.
--
-- Multiple credentials may reference the same AUTH account, so we deduplicate
-- the insert set to avoid unique-index violations and ambiguous updates.
WITH candidates AS (
    SELECT
        uc.id AS credential_id,
        uea.id AS original_account_id,
        uea.user_id,
        uea.service_type,
        uea.service_id,
        uea.account_id,
        uea.auth_data,
        uea.account_data,
        uea.client_id,
        uea.expired_at,
        uea.last_valid_at,
        uea.encryption_key_id,
        uea.tenant_id,
        uea.scopes
    FROM user_credentials uc
    JOIN user_external_accounts uea ON uea.id = uc.user_external_account_id
    WHERE uc.user_external_account_id IS NOT NULL
      AND uc.external_service_type = 'gitlab'
      AND uea.service_type = 'gitlab'
      AND uea.kind = 'AUTH'
      AND uea.deleted_at IS NULL
),
accounts_to_duplicate AS (
    SELECT DISTINCT ON (original_account_id)
        original_account_id,
        user_id, service_type, service_id, account_id,
        auth_data, account_data, client_id,
        expired_at, last_valid_at, encryption_key_id,
        tenant_id, scopes
    FROM candidates
),
inserted AS (
    INSERT INTO user_external_accounts (
        user_id, service_type, service_id, account_id,
        auth_data, account_data, client_id,
        expired_at, last_valid_at, encryption_key_id,
        tenant_id, scopes, kind
    )
    SELECT
        a.user_id, a.service_type, a.service_id, a.account_id,
        a.auth_data, a.account_data, a.client_id,
        a.expired_at, a.last_valid_at, a.encryption_key_id,
        a.tenant_id, a.scopes, 'BATCH_CHANGES'
    FROM accounts_to_duplicate a
    RETURNING id, user_id, service_type, service_id, account_id, client_id, tenant_id
)
UPDATE user_credentials uc
SET user_external_account_id = ins.id,
    updated_at = now()
FROM inserted ins
JOIN candidates c
    ON  c.user_id      = ins.user_id
    AND c.service_type  = ins.service_type
    AND c.service_id    = ins.service_id
    AND c.account_id    = ins.account_id
    AND c.client_id     = ins.client_id
    AND c.tenant_id     = ins.tenant_id
WHERE uc.id = c.credential_id;
