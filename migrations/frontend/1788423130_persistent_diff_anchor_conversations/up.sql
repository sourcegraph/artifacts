CREATE TABLE IF NOT EXISTS diff_anchors (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    repo_id INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    deepsearch_conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    base_ref TEXT NOT NULL,
    head_ref TEXT NOT NULL,
    base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL,
    old_path TEXT,
    new_path TEXT,
    src_oid TEXT,
    dst_oid TEXT,
    start_line INTEGER NOT NULL,
    start_side TEXT NOT NULL,
    end_line INTEGER NOT NULL,
    end_side TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT diff_anchors_valid_sides CHECK (
        start_side IN ('base', 'head') AND end_side IN ('base', 'head')
    ),
    CONSTRAINT diff_anchors_valid_line_range CHECK (
        start_line > 0 AND end_line > 0
        AND (start_side <> end_side OR end_line >= start_line)
    ),
    CONSTRAINT diff_anchors_selected_sides_exist CHECK (
        ((start_side <> 'base' AND end_side <> 'base') OR (old_path IS NOT NULL AND src_oid IS NOT NULL))
        AND ((start_side <> 'head' AND end_side <> 'head') OR (new_path IS NOT NULL AND dst_oid IS NOT NULL))
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS diff_anchors_unique_conversation_idx
    ON diff_anchors (tenant_id, deepsearch_conversation_id)
    WHERE deepsearch_conversation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS diff_anchors_comparison_idx
    ON diff_anchors (user_id, repo_id, base_ref, head_ref, created_at DESC, id DESC, tenant_id);

ALTER TABLE diff_anchors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON diff_anchors;
CREATE POLICY tenant_isolation_policy ON diff_anchors AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
