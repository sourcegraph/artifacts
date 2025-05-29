-- Add auto_merge_method column to changesets table
ALTER TABLE changesets ADD COLUMN IF NOT EXISTS auto_merge_method text DEFAULT NULL;
