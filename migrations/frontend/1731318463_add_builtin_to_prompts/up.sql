ALTER TABLE prompts ADD COLUMN IF NOT EXISTS builtin BOOLEAN NOT NULL DEFAULT FALSE;

CREATE OR REPLACE VIEW prompts_view AS
 SELECT prompts.id,
    prompts.name,
    prompts.description,
    prompts.definition_text,
    prompts.draft,
    prompts.visibility_secret,
    prompts.owner_user_id,
    prompts.owner_org_id,
    prompts.created_by,
    prompts.created_at,
    prompts.updated_by,
    prompts.updated_at,
    CASE WHEN builtin IS FALSE THEN (((COALESCE(users.username, orgs.name, ''))::text || '/'::text) || (prompts.name)::text) ELSE prompts.name::text END AS name_with_owner,
    prompts.auto_submit,
    prompts.mode,
    prompts.recommended,
    prompts.deleted_at,
    prompts.builtin
   FROM ((prompts
     LEFT JOIN users ON ((users.id = prompts.owner_user_id)))
     LEFT JOIN orgs ON ((orgs.id = prompts.owner_org_id)));


ALTER TABLE prompts DROP CONSTRAINT IF EXISTS prompts_has_valid_owner;
ALTER TABLE prompts ADD CONSTRAINT prompts_has_valid_owner CHECK ((owner_user_id IS NOT NULL AND owner_org_id IS NULL AND builtin IS FALSE) OR (owner_org_id IS NOT NULL AND owner_user_id IS NULL AND builtin IS FALSE) OR (builtin IS TRUE AND owner_user_id IS NULL AND owner_org_id IS NULL));

CREATE UNIQUE INDEX IF NOT EXISTS prompts_name_is_unique_for_builtins ON prompts(name, tenant_id) WHERE builtin IS TRUE;
