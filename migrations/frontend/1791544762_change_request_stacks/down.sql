DROP INDEX IF EXISTS change_requests_stack_idx;
ALTER TABLE change_requests DROP CONSTRAINT IF EXISTS change_requests_stack_check;
ALTER TABLE change_requests DROP COLUMN IF EXISTS stack_position;
ALTER TABLE change_requests DROP COLUMN IF EXISTS stack_id;
