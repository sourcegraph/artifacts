ALTER TABLE external_services ADD COLUMN IF NOT EXISTS suspended boolean NOT NULL DEFAULT false;
