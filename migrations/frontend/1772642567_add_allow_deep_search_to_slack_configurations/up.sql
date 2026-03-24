ALTER TABLE slack_configurations ADD COLUMN IF NOT EXISTS allow_deep_search boolean NOT NULL DEFAULT true;
