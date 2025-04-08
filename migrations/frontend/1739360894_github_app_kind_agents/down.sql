DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'AGENTS_REVIEW'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'github_app_kind')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM github_apps
        WHERE kind::text = 'AGENTS_REVIEW'
    ) THEN
        ALTER TYPE github_app_kind RENAME TO github_app_kind_old;
        CREATE TYPE github_app_kind AS ENUM (
            'COMMIT_SIGNING',
            'REPO_SYNC',
            'USER_CREDENTIAL',
            'SITE_CREDENTIAL'
        );

        -- Drop the default first
        ALTER TABLE github_apps ALTER COLUMN kind DROP DEFAULT;

        -- Convert the column type
        ALTER TABLE github_apps
            ALTER COLUMN kind TYPE github_app_kind
            USING kind::text::github_app_kind;

        -- Add the default back
        ALTER TABLE github_apps ALTER COLUMN kind SET DEFAULT 'REPO_SYNC'::github_app_kind;

        DROP TYPE github_app_kind_old;
    END IF;
END $$;
