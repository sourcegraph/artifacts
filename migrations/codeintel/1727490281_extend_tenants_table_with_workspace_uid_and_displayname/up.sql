-- Delete all tenants except the default one, we're not in production yet so this is the
-- simplest.
DELETE FROM tenants where NOT id = 1;

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS workspace_id uuid;
-- Canonical workspace id for the default tenant.
UPDATE tenants SET workspace_id = '6a6b043c-ffed-42ec-b1f4-abc231cd7222' WHERE id = 1;

ALTER TABLE tenants ALTER COLUMN workspace_id SET NOT NULL;
DO $$
BEGIN

  BEGIN
    ALTER TABLE tenants ADD CONSTRAINT tenants_workspace_id_key UNIQUE (workspace_id);
  EXCEPTION
    WHEN duplicate_table THEN  -- postgres raises duplicate_table at surprising times. Ex.: for UNIQUE constraints.
    WHEN duplicate_object THEN
      RAISE NOTICE 'Table constraint lsif_last_retention_scan_unique already exists, skipping';
  END;
END $$;

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS display_name text;

COMMENT ON COLUMN tenants.workspace_id IS 'The ID in workspaces service of the tenant. This is used for identifying the link between tenant and workspace.';
COMMENT ON COLUMN tenants.display_name IS 'An optional display name for the tenant. This is used for rendering the tenant name in the UI.';
