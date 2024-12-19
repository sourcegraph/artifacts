-- With RLS enabled postgres can't use any index involving the name column. It
-- can't use it since citext relies on functions which are not marked
-- LEAKPROOF. So we introduce a new column name_lower which we will only ever
-- query in the WHERE clause but not return.

-- GENERATED ALWAYS AS is like a view but for a column. STORED so its written
-- to disk so we avoid RLS policies. lower COLLATE "C" we used previously, but
-- it also means we can do simple byte by byte lowering in go.

-- This migration is split into several to try and avoid taking table locks.
-- Unfortunetly the adding of the column does require a table lock.

ALTER TABLE repo ADD COLUMN IF NOT EXISTS name_lower text
  GENERATED ALWAYS AS (lower(name::text) COLLATE "C") STORED;

-- Later migrations add repo_name_lower_unique and repo_name_lower_trgm_idx

-- Other indexes
--  Do not need, won't be used on MT so can keep querying name
--   "repo_hashed_name_idx" btree (sha256(lower(name::text)::bytea)) WHERE deleted_at IS NULL
--
--  I don't know why this one exists. I guess case:yes type:repo searches? I will defer fixing this then to a migration where we port name to text. Need to think more though.
--   "repo_name_case_sensitive_trgm_idx" gin ((name::text) gin_trgm_ops)
--
--  This index seems like it shouldn't include name? Maybe was useful when minimalrepo was just id and name
--   "repo_non_deleted_id_name_idx" btree (id, name) WHERE deleted_at IS NULL

-- indexes we can drop once the app no longer queries name:
--  "repo_name_idx" btree (lower(name::text) COLLATE "C")
--  "repo_name_trgm" gin (lower(name::text) gin_trgm_ops)
