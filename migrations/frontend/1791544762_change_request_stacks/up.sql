-- Stack membership as reported by the code host. Both are NULL for a change
-- request that is not part of a stack.
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS stack_id TEXT;
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS stack_position INTEGER;

ALTER TABLE change_requests DROP CONSTRAINT IF EXISTS change_requests_stack_check;
ALTER TABLE change_requests ADD CONSTRAINT change_requests_stack_check
    CHECK ((stack_id IS NULL) = (stack_position IS NULL) AND (stack_position IS NULL OR stack_position > 0));

CREATE INDEX IF NOT EXISTS change_requests_stack_idx
    ON change_requests (tenant_id, external_service_type, code_host_url, external_repository_id, stack_id)
    WHERE stack_id IS NOT NULL;
