ALTER TABLE tenants DROP COLUMN IF EXISTS redis_pruned_at;
ALTER TABLE tenants DROP COLUMN IF EXISTS deleted_at;
