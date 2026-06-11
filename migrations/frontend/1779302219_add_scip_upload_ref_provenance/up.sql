ALTER TABLE scip_uploads
    ADD COLUMN IF NOT EXISTS ref TEXT,
    ADD COLUMN IF NOT EXISTS ref_type TEXT;

COMMENT ON COLUMN scip_uploads.ref IS
'The Git ref-like (tag, branch, etc.) provenance for this upload, used for upload supersession. This is not a commit SHA.';

COMMENT ON COLUMN scip_uploads.ref_type IS
'The kind of ref provenance stored in ref. Expected values are BRANCH, TAG, and OTHER.';
