-- archived_insight_series_recording_times

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'archived_insight_series_recording_times_pkey'
        AND conrelid = 'archived_insight_series_recording_times'::regclass
    ) THEN
        -- Use combined primary key from unique constraint
        ALTER TABLE archived_insight_series_recording_times ADD PRIMARY KEY (insight_series_id, recording_time);
    END IF;

END;
$$;

-- PK has the same properties so we can now drop the excessive unique constraint.
ALTER TABLE archived_insight_series_recording_times DROP CONSTRAINT IF EXISTS archived_insight_series_recor_insight_series_id_recording_t_key;

COMMIT AND CHAIN;

-- archived_series_points
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'archived_series_points_pkey'
        AND conrelid = 'archived_series_points'::regclass
    ) THEN
        ALTER TABLE archived_series_points ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- insight_series_recording_times
DELETE FROM insight_series_recording_times WHERE insight_series_id IS NULL;
DELETE FROM insight_series_recording_times WHERE recording_time IS NULL;
ALTER TABLE insight_series_recording_times ALTER COLUMN insight_series_id SET NOT NULL;
ALTER TABLE insight_series_recording_times ALTER COLUMN recording_time SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'insight_series_recording_times_pkey'
        AND conrelid = 'insight_series_recording_times'::regclass
    ) THEN
        -- Use combined primary key from unique constraint
        ALTER TABLE insight_series_recording_times ADD PRIMARY KEY (insight_series_id, recording_time);
    END IF;

END;
$$;

-- PK has the same properties so we can now drop the excessive unique constraint.
ALTER TABLE insight_series_recording_times DROP CONSTRAINT IF EXISTS insight_series_recording_time_insight_series_id_recording_t_key;

COMMIT AND CHAIN;

-- series_points
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'series_points_pkey'
        AND conrelid = 'series_points'::regclass
    ) THEN
        ALTER TABLE series_points ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- series_points_snapshots
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'series_points_snapshots_pkey'
        AND conrelid = 'series_points_snapshots'::regclass
    ) THEN
        ALTER TABLE series_points_snapshots ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;
