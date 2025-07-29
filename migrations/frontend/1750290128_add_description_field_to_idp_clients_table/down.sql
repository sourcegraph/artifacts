-- Remove description field from idp_clients table
ALTER TABLE idp_clients DROP COLUMN IF EXISTS description;
