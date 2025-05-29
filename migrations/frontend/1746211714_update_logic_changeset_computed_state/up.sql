CREATE OR REPLACE FUNCTION changesets_computed_state_ensure() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN

    NEW.computed_state = CASE
        WHEN NEW.reconciler_state = 'errored' THEN 'RETRYING'
        WHEN NEW.reconciler_state = 'failed' THEN 'FAILED'
        WHEN NEW.reconciler_state = 'scheduled' THEN 'SCHEDULED'
        WHEN NEW.reconciler_state != 'completed' THEN 'PROCESSING'
        WHEN NEW.ui_publication_state = 'PUSHED_ONLY' THEN 'PUSHED_ONLY'
        WHEN NEW.publication_state = 'UNPUBLISHED' THEN 'UNPUBLISHED'
        ELSE NEW.external_state
    END AS computed_state;

    RETURN NEW;
END $$;
