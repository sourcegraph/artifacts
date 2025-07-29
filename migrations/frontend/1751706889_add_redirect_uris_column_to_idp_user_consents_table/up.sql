-- Add redirect_uris column to idp_user_consents table
-- This allows us to track which redirect URIs were consented to,
-- requiring new consent when clients add new redirect URIs
ALTER TABLE idp_user_consents ADD COLUMN IF NOT EXISTS redirect_uris text[] NOT NULL DEFAULT '{}';
