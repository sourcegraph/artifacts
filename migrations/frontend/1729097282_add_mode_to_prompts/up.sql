-- mode: CHAT, EDIT, INSERT
ALTER TABLE prompts ADD COLUMN IF NOT EXISTS mode VARCHAR NOT NULL DEFAULT 'CHAT';

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
    prompts.mode
   FROM ((prompts
     LEFT JOIN users ON ((users.id = prompts.owner_user_id)))
     LEFT JOIN orgs ON ((orgs.id = prompts.owner_org_id)));
