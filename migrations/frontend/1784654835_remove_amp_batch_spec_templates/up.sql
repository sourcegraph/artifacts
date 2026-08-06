-- Remove the Amp-specific batch spec templates that were seeded by
-- 1752580919_batch_spec_default_templates. Associated rows in
-- batch_spec_library_variables are removed via ON DELETE CASCADE.
-- Only seeded records (created_by_user_id IS NULL) are removed, so
-- user-created records with the same name are left untouched.
DELETE FROM batch_spec_library_records
WHERE name IN ('Amp free form prompt', 'Ask Amp to fix CVE-2025-29927')
  AND created_by_user_id IS NULL;
