-- Remove redirect_uris column from idp_user_consents table
ALTER TABLE idp_user_consents DROP COLUMN IF EXISTS redirect_uris;
