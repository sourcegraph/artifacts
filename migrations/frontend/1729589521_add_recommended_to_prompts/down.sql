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
    prompts.mode
   FROM ((prompts
     LEFT JOIN users ON ((users.id = prompts.owner_user_id)))
     LEFT JOIN orgs ON ((orgs.id = prompts.owner_org_id)));

ALTER TABLE prompts DROP COLUMN IF EXISTS recommended;
