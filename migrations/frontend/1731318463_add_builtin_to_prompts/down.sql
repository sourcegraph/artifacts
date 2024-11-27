DROP VIEW IF EXISTS prompts_view;

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
    (((COALESCE(users.username, orgs.name))::text || '/'::text) || (prompts.name)::text) AS name_with_owner,
    prompts.auto_submit,
    prompts.mode,
    prompts.recommended,
    prompts.deleted_at
   FROM ((prompts
     LEFT JOIN users ON ((users.id = prompts.owner_user_id)))
     LEFT JOIN orgs ON ((orgs.id = prompts.owner_org_id)));


DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'prompts'
        AND column_name = 'builtin'
    ) THEN
        DELETE FROM prompts
        WHERE builtin IS TRUE;
    END IF;
END $$;


ALTER TABLE prompts DROP CONSTRAINT IF EXISTS prompts_has_valid_owner;
ALTER TABLE prompts ADD CONSTRAINT prompts_has_valid_owner CHECK ((owner_user_id IS NOT NULL AND owner_org_id IS NULL ) OR (owner_org_id IS NOT NULL AND owner_user_id IS NULL));

DROP INDEX IF EXISTS prompts_name_is_unique_for_builtins;

ALTER TABLE prompts DROP COLUMN IF EXISTS builtin;
