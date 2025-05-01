-- archived_insight_series_recording_times

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'archived_insight_series_recor_insight_series_id_recording_t_key'
        AND conrelid = 'archived_insight_series_recording_times'::regclass
    ) THEN
        ALTER TABLE archived_insight_series_recording_times ADD CONSTRAINT archived_insight_series_recor_insight_series_id_recording_t_key UNIQUE (insight_series_id, recording_time);
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'archived_insight_series_recording_times_pkey'
        AND conrelid = 'archived_insight_series_recording_times'::regclass
    ) THEN
        ALTER TABLE archived_insight_series_recording_times DROP CONSTRAINT archived_insight_series_recording_times_pkey;
    END IF;
END;
$$;

-- archived_series_points

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'archived_series_points_pkey'
        AND conrelid = 'archived_series_points'::regclass
    ) THEN
        ALTER TABLE archived_series_points DROP CONSTRAINT archived_series_points_pkey;
        ALTER TABLE archived_series_points DROP COLUMN id;
    END IF;
END;
$$;

-- insight_series_recording_times

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'insight_series_recording_time_insight_series_id_recording_t_key'
        AND conrelid = 'insight_series_recording_times'::regclass
    ) THEN
        ALTER TABLE insight_series_recording_times ADD CONSTRAINT insight_series_recording_time_insight_series_id_recording_t_key UNIQUE (insight_series_id, recording_time);
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'insight_series_recording_times_pkey'
        AND conrelid = 'insight_series_recording_times'::regclass
    ) THEN
        ALTER TABLE insight_series_recording_times DROP CONSTRAINT insight_series_recording_times_pkey;
    END IF;
END;
$$;

ALTER TABLE insight_series_recording_times ALTER COLUMN insight_series_id DROP NOT NULL;
ALTER TABLE insight_series_recording_times ALTER COLUMN recording_time DROP NOT NULL;

-- series_points
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'series_points_pkey'
        AND conrelid = 'series_points'::regclass
    ) THEN
        ALTER TABLE series_points DROP CONSTRAINT series_points_pkey;
        ALTER TABLE series_points DROP COLUMN id;
    END IF;
END;
$$;

-- series_points_snapshots
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'series_points_snapshots_pkey'
        AND conrelid = 'series_points_snapshots'::regclass
    ) THEN
        ALTER TABLE series_points_snapshots DROP CONSTRAINT series_points_snapshots_pkey;
        ALTER TABLE series_points_snapshots DROP COLUMN id;
    END IF;
END;
$$;
