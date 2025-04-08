--- Add conversation_id to agent_conversation_message_reactions
ALTER TABLE agent_conversation_message_reactions
    ADD COLUMN IF NOT EXISTS conversation_id INT GENERATED ALWAYS AS ((data->>'conversation_id')::int) STORED REFERENCES agent_conversations(id) ON DELETE CASCADE;

UPDATE agent_conversation_message_reactions cmr
SET data = jsonb_set(cmr.data, '{conversation_id}', to_jsonb(m.conversation_id))
FROM agent_conversation_messages m
WHERE cmr.message_id = m.id
AND cmr.tenant_id = m.tenant_id;


ALTER TABLE agent_conversation_message_reactions
    ALTER COLUMN conversation_id SET NOT NULL;

--- Add message_id, reaction_id, changeset_id to agent_review_diagnostic_feedback
ALTER TABLE agent_review_diagnostic_feedback
    ADD COLUMN IF NOT EXISTS message_id INT GENERATED ALWAYS AS ((data->>'message_id')::int) STORED REFERENCES agent_conversation_messages(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS reaction_id INT GENERATED ALWAYS AS ((data->>'reaction_id')::int) STORED REFERENCES agent_conversation_message_reactions(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS changeset_id INT GENERATED ALWAYS AS ((data->>'changeset_id')::int) STORED REFERENCES agent_changesets(id) ON DELETE CASCADE;

UPDATE agent_review_diagnostic_feedback rdf
SET data = jsonb_concat(
    rdf.data,
    jsonb_build_object(
        'message_id', cmr.message_id,
        'reaction_id', cmr.id,
        'changeset_id', c.changeset_id
    )
)
FROM agent_conversation_message_reactions cmr
JOIN agent_conversations c ON cmr.conversation_id = c.id
WHERE rdf.data->>'reaction_id' = cmr.id::text;

UPDATE agent_review_diagnostic_feedback rdf
SET data = jsonb_concat(
    rdf.data,
    jsonb_build_object(
        'message_id', cm.id,
        'changeset_id', c.changeset_id
    )
)
FROM agent_conversation_messages cm
JOIN agent_conversations c ON cm.conversation_id = c.id
WHERE rdf.data->>'message_id' = cm.id::text;
