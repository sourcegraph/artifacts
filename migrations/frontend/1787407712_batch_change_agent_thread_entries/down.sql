DO $migration$
BEGIN
    IF to_regclass('batch_change_agent_thread_entries') IS NULL THEN
        RETURN;
    END IF;

-- Recreate the legacy message/turn and compaction hierarchy, then project the
-- canonical transcript back into it before removing thread entries. The old
-- shape cannot express provider-part interleaving, but it retains every part
-- in its legacy fields and remains replayable after rollback.
CREATE TABLE IF NOT EXISTS batch_change_agent_messages (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    sequence INTEGER NOT NULL,
    question TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'processing',
    answer TEXT,
    error TEXT,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    wake_kind TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_messages_status_check CHECK (status IN ('processing', 'completed', 'cancelled', 'failed')),
    CONSTRAINT batch_change_agent_messages_sequence_check CHECK (sequence > 0)
);

CREATE TABLE IF NOT EXISTS batch_change_agent_turns (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    message_id INTEGER NOT NULL REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE,
    sequence INTEGER NOT NULL,
    role TEXT NOT NULL,
    content JSONB NOT NULL DEFAULT '[]'::jsonb,
    reasoning TEXT NOT NULL DEFAULT '',
    thinking TEXT,
    thinking_signature TEXT,
    tool_calls JSONB NOT NULL DEFAULT '[]'::jsonb,
    tool_results JSONB NOT NULL DEFAULT '[]'::jsonb,
    error JSONB,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_turns_role_check CHECK (role IN ('system', 'user', 'assistant', 'tool')),
    CONSTRAINT batch_change_agent_turns_sequence_check CHECK (sequence > 0)
);

CREATE TABLE IF NOT EXISTS batch_change_agent_thread_compactions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    up_to_turn_id BIGINT NOT NULL REFERENCES batch_change_agent_turns(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    summary_stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE batch_change_agent_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_messages;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_messages AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_turns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_turns;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_turns AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_thread_compactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_thread_compactions;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_thread_compactions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

-- One user-message entry owns each legacy message. Derive terminal state from
-- the error entry in its segment, or from the thread's active entry for an
-- in-flight run. The latest assistant group supplies the legacy answer.
WITH message_segments AS (
    SELECT
        entry.*,
        LEAD(entry.sequence) OVER (PARTITION BY entry.thread_id ORDER BY entry.sequence) AS next_message_sequence,
        ROW_NUMBER() OVER (PARTITION BY entry.thread_id ORDER BY entry.sequence) AS message_sequence
    FROM batch_change_agent_thread_entries entry
    WHERE entry.kind = 'user_message'
)
INSERT INTO batch_change_agent_messages
    (id, tenant_id, thread_id, sequence, question, status, answer, error, stats, wake_kind, created_at, updated_at)
SELECT
    message.id::INTEGER,
    message.tenant_id,
    message.thread_id,
    message.message_sequence::INTEGER,
    COALESCE(message.payload->>'text', ''),
    CASE
        WHEN thread.active_entry_id = message.id THEN 'processing'
        WHEN terminal.payload->>'status' = 'cancelled' THEN 'cancelled'
        WHEN terminal.id IS NOT NULL THEN 'failed'
        ELSE 'completed'
    END,
    answer.text,
    terminal.payload->>'message',
    jsonb_build_object(
        'time_millis', COALESCE(run_stats.time_millis, 0),
        'tool_calls', COALESCE(run_stats.tool_calls, 0),
        'total_input_tokens', COALESCE(run_stats.total_input_tokens, 0),
        'cached_tokens', COALESCE(run_stats.cached_tokens, 0),
        'cache_creation_input_tokens', COALESCE(run_stats.cache_creation_input_tokens, 0),
        'prompt_tokens', COALESCE(run_stats.prompt_tokens, 0),
        'completion_tokens', COALESCE(run_stats.completion_tokens, 0),
        'total_tokens', COALESCE(run_stats.total_tokens, 0),
        'context_usage_percent', COALESCE(run_stats.context_usage_percent, 0)
    ),
    message.payload->>'wake_kind',
    message.created_at,
    COALESCE(segment.updated_at, message.created_at)
FROM message_segments message
JOIN batch_change_agent_threads thread ON thread.id = message.thread_id
LEFT JOIN LATERAL (
    SELECT entry.id, entry.payload
    FROM batch_change_agent_thread_entries entry
    WHERE entry.thread_id = message.thread_id
      AND entry.sequence > message.sequence
      AND entry.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
      AND entry.kind = 'error'
    ORDER BY entry.sequence DESC
    LIMIT 1
) terminal ON TRUE
LEFT JOIN LATERAL (
    SELECT STRING_AGG(entry.payload->>'text', '' ORDER BY entry.sequence) AS text
    FROM batch_change_agent_thread_entries entry
    WHERE entry.thread_id = message.thread_id
      AND entry.sequence > message.sequence
      AND entry.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
      AND entry.kind = 'assistant_text'
      AND entry.group_id = (
          SELECT latest.group_id
          FROM batch_change_agent_thread_entries latest
          WHERE latest.thread_id = message.thread_id
            AND latest.sequence > message.sequence
            AND latest.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
            AND latest.kind = 'assistant_text'
          ORDER BY latest.sequence DESC
          LIMIT 1
      )
) answer ON TRUE
LEFT JOIN LATERAL (
    SELECT
        SUM(COALESCE((entry.stats->>'time_millis')::BIGINT, 0)) AS time_millis,
        SUM(COALESCE((entry.stats->>'tool_calls')::INTEGER, 0)) AS tool_calls,
        MAX(COALESCE((entry.stats->>'total_input_tokens')::INTEGER, 0)) AS total_input_tokens,
        SUM(COALESCE((entry.stats->>'cached_tokens')::INTEGER, 0)) AS cached_tokens,
        SUM(COALESCE((entry.stats->>'cache_creation_input_tokens')::INTEGER, 0)) AS cache_creation_input_tokens,
        SUM(COALESCE((entry.stats->>'prompt_tokens')::INTEGER, 0)) AS prompt_tokens,
        SUM(COALESCE((entry.stats->>'completion_tokens')::INTEGER, 0)) AS completion_tokens,
        MAX(COALESCE((entry.stats->>'total_tokens')::INTEGER, 0)) AS total_tokens,
        MAX(COALESCE((entry.stats->>'context_usage_percent')::INTEGER, 0)) AS context_usage_percent
    FROM batch_change_agent_thread_entries entry
    WHERE entry.thread_id = message.thread_id
      AND entry.sequence >= message.sequence
      AND entry.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
      AND entry.kind NOT IN ('compaction', 'error')
) run_stats ON TRUE
LEFT JOIN LATERAL (
    SELECT MAX(entry.created_at) AS updated_at
    FROM batch_change_agent_thread_entries entry
    WHERE entry.thread_id = message.thread_id
      AND entry.sequence >= message.sequence
      AND entry.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
) segment ON TRUE;

-- Collapse each provider group back into legacy assistant and tool-result
-- turns. The canonical model keeps a provider response and its tool results in
-- one group, while the legacy model requires tool results in a separate user
-- turn. Using the first entry ID in each role as the turn ID preserves a
-- stable, globally unique identifier that compaction cutoffs can reference.
--
-- The legacy schema stores a single thinking text and signature per turn, so a
-- group with several thinking entries is collapsed the way the legacy codecs
-- did. The OpenAI Responses codec stores each reasoning item as a JSON array
-- with one element, and the legacy codec stored every reasoning item of a
-- response in one array, so those are merged without loss. Anthropic
-- signatures are opaque strings that sign exactly one thinking block, so a
-- concatenated text would no longer match any signature; keep the last block,
-- which is what the legacy decoder kept. Anthropic rejects modified thinking
-- blocks in the assistant turn immediately preceding tool results, so a
-- multi-block Anthropic tool-use turn may fail to resume after rollback.
WITH message_segments AS (
    SELECT
        entry.id AS message_id,
        entry.thread_id,
        entry.sequence,
        LEAD(entry.sequence) OVER (PARTITION BY entry.thread_id ORDER BY entry.sequence) AS next_message_sequence
    FROM batch_change_agent_thread_entries entry
    WHERE entry.kind = 'user_message'
), thinking_blocks AS (
    SELECT
        entry.thread_id,
        entry.group_id,
        entry.sequence,
        entry.payload->>'text' AS text,
        entry.payload->>'signature' AS signature,
        entry.payload->>'signature' LIKE '[%' AS mergeable
    FROM batch_change_agent_thread_entries entry
    WHERE entry.kind = 'thinking'
), group_thinking AS (
    SELECT
        block.thread_id,
        block.group_id,
        CASE WHEN BOOL_AND(block.mergeable)
            THEN STRING_AGG(block.text, '' ORDER BY block.sequence)
            ELSE (ARRAY_AGG(block.text ORDER BY block.sequence DESC))[1]
        END AS thinking,
        CASE WHEN BOOL_AND(block.mergeable)
            THEN (
                SELECT JSONB_AGG(item.value ORDER BY merged.sequence, item.ordinality)::TEXT
                FROM thinking_blocks merged
                CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(merged.signature::JSONB)
                    WITH ORDINALITY AS item(value, ordinality)
                WHERE merged.thread_id = block.thread_id AND merged.group_id = block.group_id
            )
            ELSE (ARRAY_AGG(block.signature ORDER BY block.sequence DESC)
                FILTER (WHERE block.signature IS NOT NULL))[1]
        END AS thinking_signature
    FROM thinking_blocks block
    GROUP BY block.thread_id, block.group_id
), grouped_entries AS (
    SELECT
        MIN(entry.id) AS id,
        entry.tenant_id,
        entry.thread_id,
        entry.group_id,
        message.message_id,
        MIN(entry.sequence) AS first_sequence,
        CASE entry_role.kind WHEN 'assistant' THEN 'assistant' ELSE 'user' END AS role,
        entry_role.kind AS entry_role,
        COALESCE(STRING_AGG(entry.payload->>'text', '' ORDER BY entry.sequence)
            FILTER (WHERE entry.kind IN ('user_message', 'assistant_text')), '') AS reasoning,
        CASE WHEN entry_role.kind = 'assistant' THEN group_thinking.thinking END AS thinking,
        CASE WHEN entry_role.kind = 'assistant' THEN group_thinking.thinking_signature END AS thinking_signature,
        COALESCE(JSONB_AGG(entry.payload ORDER BY entry.sequence)
            FILTER (WHERE entry.kind = 'tool_call'), '[]'::JSONB) AS tool_calls,
        COALESCE(JSONB_AGG(entry.payload ORDER BY entry.sequence)
            FILTER (WHERE entry.kind = 'tool_result'), '[]'::JSONB) AS tool_results,
        (ARRAY_AGG(entry.stats ORDER BY entry.sequence DESC))[1] AS stats,
        MIN(entry.created_at) AS created_at
    FROM batch_change_agent_thread_entries entry
    JOIN message_segments message
      ON message.thread_id = entry.thread_id
     AND entry.sequence >= message.sequence
     AND entry.sequence < COALESCE(message.next_message_sequence, 9223372036854775807)
    CROSS JOIN LATERAL (
        SELECT CASE
            WHEN entry.kind = 'user_message' THEN 'user_message'
            WHEN entry.kind = 'tool_result' THEN 'tool_result'
            ELSE 'assistant'
        END AS kind
    ) entry_role
    LEFT JOIN group_thinking
      ON group_thinking.thread_id = entry.thread_id AND group_thinking.group_id = entry.group_id
    WHERE entry.kind NOT IN ('compaction', 'error')
    GROUP BY entry.tenant_id, entry.thread_id, entry.group_id, message.message_id, entry_role.kind,
             group_thinking.thinking, group_thinking.thinking_signature
), grouped_content AS (
    SELECT
        grouped.id,
        COALESCE(JSONB_AGG(block.value ORDER BY entry.sequence, block.ordinality)
            FILTER (WHERE block.value IS NOT NULL), '[]'::JSONB) AS content
    FROM grouped_entries grouped
    LEFT JOIN batch_change_agent_thread_entries entry
      ON entry.thread_id = grouped.thread_id AND entry.group_id = grouped.group_id
     AND entry.kind = CASE grouped.entry_role
         WHEN 'user_message' THEN 'user_message'
         WHEN 'assistant' THEN 'assistant_text'
         ELSE NULL
     END
    LEFT JOIN LATERAL JSONB_ARRAY_ELEMENTS(COALESCE(entry.payload->'attachments', '[]'::JSONB))
        WITH ORDINALITY AS block(value, ordinality) ON TRUE
    GROUP BY grouped.id
)
INSERT INTO batch_change_agent_turns
    (id, tenant_id, message_id, sequence, role, content, reasoning, thinking, thinking_signature,
     tool_calls, tool_results, stats, created_at)
SELECT
    grouped.id,
    grouped.tenant_id,
    grouped.message_id::INTEGER,
    ROW_NUMBER() OVER (PARTITION BY grouped.message_id ORDER BY grouped.first_sequence)::INTEGER,
    grouped.role,
    content.content,
    grouped.reasoning,
    grouped.thinking,
    grouped.thinking_signature,
    grouped.tool_calls,
    grouped.tool_results,
    COALESCE(grouped.stats, '{}'::JSONB),
    grouped.created_at
FROM grouped_entries grouped
JOIN grouped_content content ON content.id = grouped.id;

-- Restore compactions and point each cutoff at the reconstructed turn that
-- contains the canonical cutoff entry. Assistant parts and tool results from
-- one canonical group map to different legacy turns.
INSERT INTO batch_change_agent_thread_compactions
    (id, tenant_id, thread_id, up_to_turn_id, summary, stats, summary_stats, created_at)
SELECT
    compaction.id,
    compaction.tenant_id,
    compaction.thread_id,
    cutoff_turn.id,
    COALESCE(compaction.payload->>'summary', ''),
    COALESCE(compaction.payload->'cumulative_stats', '{}'::JSONB),
    COALESCE(compaction.payload->'summary_stats', '{}'::JSONB),
    compaction.created_at
FROM batch_change_agent_thread_entries compaction
JOIN batch_change_agent_thread_entries cutoff ON cutoff.id = compaction.compacted_through_entry_id
JOIN LATERAL (
    SELECT MIN(entry.id) AS id
    FROM batch_change_agent_thread_entries entry
    WHERE entry.thread_id = cutoff.thread_id
      AND entry.group_id = cutoff.group_id
      AND entry.kind NOT IN ('compaction', 'error')
      AND CASE
          WHEN entry.kind = 'user_message' THEN 'user_message'
          WHEN entry.kind = 'tool_result' THEN 'tool_result'
          ELSE 'assistant'
      END = CASE
          WHEN cutoff.kind = 'user_message' THEN 'user_message'
          WHEN cutoff.kind = 'tool_result' THEN 'tool_result'
          ELSE 'assistant'
      END
) cutoff_turn ON cutoff_turn.id IS NOT NULL
WHERE compaction.kind = 'compaction';

PERFORM SETVAL('batch_change_agent_messages_id_seq',
    COALESCE((SELECT MAX(id) FROM batch_change_agent_messages), 1),
    EXISTS (SELECT 1 FROM batch_change_agent_messages));
PERFORM SETVAL('batch_change_agent_turns_id_seq',
    COALESCE((SELECT MAX(id) FROM batch_change_agent_turns), 1),
    EXISTS (SELECT 1 FROM batch_change_agent_turns));
PERFORM SETVAL('batch_change_agent_thread_compactions_id_seq',
    COALESCE((SELECT MAX(id) FROM batch_change_agent_thread_compactions), 1),
    EXISTS (SELECT 1 FROM batch_change_agent_thread_compactions));

ALTER TABLE batch_change_agent_jobs ADD COLUMN IF NOT EXISTS message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE;
ALTER TABLE batch_change_agent_tool_approvals ADD COLUMN IF NOT EXISTS message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE;
ALTER TABLE batch_change_agent_spec_drafts ADD COLUMN IF NOT EXISTS message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE SET NULL;
ALTER TABLE batch_change_agent_threads ADD COLUMN IF NOT EXISTS active_message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE SET NULL;

UPDATE batch_change_agent_jobs SET message_id = trigger_entry_id::INTEGER;
UPDATE batch_change_agent_tool_approvals approval
SET message_id = (
    SELECT user_entry.id
    FROM batch_change_agent_thread_entries user_entry
    JOIN batch_change_agent_thread_entries call ON call.id = approval.thread_entry_id
    WHERE user_entry.thread_id = call.thread_id
      AND user_entry.kind = 'user_message'
      AND user_entry.sequence <= call.sequence
    ORDER BY user_entry.sequence DESC
    LIMIT 1
)::INTEGER;
UPDATE batch_change_agent_spec_drafts SET message_id = trigger_entry_id::INTEGER WHERE trigger_entry_id IS NOT NULL;
UPDATE batch_change_agent_threads SET active_message_id = active_entry_id::INTEGER WHERE active_entry_id IS NOT NULL;

ALTER TABLE batch_change_agent_jobs ALTER COLUMN message_id SET NOT NULL;
ALTER TABLE batch_change_agent_tool_approvals ALTER COLUMN message_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS batch_change_agent_jobs_message_id_idx
    ON batch_change_agent_jobs (message_id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_message_id_idx
    ON batch_change_agent_spec_drafts (message_id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_tool_approvals_message_tool_call_idx
    ON batch_change_agent_tool_approvals (tenant_id, message_id, tool_call_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_messages_one_processing_idx
    ON batch_change_agent_messages (tenant_id, thread_id) WHERE status = 'processing';
CREATE INDEX IF NOT EXISTS batch_change_agent_messages_thread_id_idx
    ON batch_change_agent_messages (thread_id, id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_messages_thread_sequence_idx
    ON batch_change_agent_messages (tenant_id, thread_id, sequence);
CREATE INDEX IF NOT EXISTS batch_change_agent_turns_message_id_idx
    ON batch_change_agent_turns (message_id, id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_turns_message_sequence_idx
    ON batch_change_agent_turns (tenant_id, message_id, sequence);
CREATE INDEX IF NOT EXISTS batch_change_agent_thread_compactions_thread_id_idx
    ON batch_change_agent_thread_compactions (thread_id, id DESC, tenant_id);

ALTER TABLE batch_change_agent_jobs DROP COLUMN IF EXISTS trigger_entry_id, DROP COLUMN IF EXISTS thread_id;
ALTER TABLE batch_change_agent_tool_approvals DROP COLUMN IF EXISTS thread_entry_id;
ALTER TABLE batch_change_agent_spec_drafts DROP COLUMN IF EXISTS trigger_entry_id;
ALTER TABLE batch_change_agent_threads DROP COLUMN IF EXISTS active_entry_id;

DROP TABLE IF EXISTS batch_change_agent_thread_entries;

ALTER TABLE batch_change_agent_threads
    DROP CONSTRAINT IF EXISTS batch_change_agent_threads_state_check;
ALTER TABLE batch_change_agent_threads
    DROP COLUMN IF EXISTS active_message_id,
    DROP COLUMN IF EXISTS state;

END
$migration$;
