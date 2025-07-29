-- Add description field to idp_clients table
ALTER TABLE idp_clients ADD COLUMN IF NOT EXISTS description TEXT;
