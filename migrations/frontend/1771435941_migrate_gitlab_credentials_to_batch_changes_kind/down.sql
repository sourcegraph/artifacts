-- Re-point credentials back to the original AUTH accounts and delete the
-- duplicated BATCH_CHANGES accounts.
--
-- We identify the original AUTH account by matching on the same
-- (tenant_id, user_id, service_type, service_id, client_id, account_id)
-- tuple with kind = 'AUTH'.
WITH bc_accounts AS (
    SELECT
        uc.id AS credential_id,
        uea_bc.id AS bc_account_id,
        uea_auth.id AS auth_account_id
    FROM user_credentials uc
    JOIN user_external_accounts uea_bc
        ON  uea_bc.id = uc.user_external_account_id
        AND uea_bc.kind = 'BATCH_CHANGES'
        AND uea_bc.service_type = 'gitlab'
        AND uea_bc.deleted_at IS NULL
    JOIN user_external_accounts uea_auth
        ON  uea_auth.user_id      = uea_bc.user_id
        AND uea_auth.service_type  = uea_bc.service_type
        AND uea_auth.service_id    = uea_bc.service_id
        AND uea_auth.account_id    = uea_bc.account_id
        AND uea_auth.client_id     = uea_bc.client_id
        AND uea_auth.tenant_id     = uea_bc.tenant_id
        AND uea_auth.kind          = 'AUTH'
        AND uea_auth.deleted_at IS NULL
    WHERE uc.external_service_type = 'gitlab'
),
repointed AS (
    UPDATE user_credentials uc
    SET user_external_account_id = bc.auth_account_id,
        updated_at = now()
    FROM bc_accounts bc
    WHERE uc.id = bc.credential_id
    RETURNING bc.bc_account_id
)
DELETE FROM user_external_accounts
WHERE id IN (SELECT bc_account_id FROM repointed);
