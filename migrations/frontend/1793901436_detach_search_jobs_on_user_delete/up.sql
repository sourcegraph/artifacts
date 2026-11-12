-- A search job without an initiator is pending deletion: the worker deletes
-- its results from object storage before deleting the row. Deleting a user
-- detaches their search jobs instead of deleting the rows, which would leave
-- their results in object storage with nothing referencing them.
ALTER TABLE exhaustive_search_jobs ALTER COLUMN initiator_id DROP NOT NULL;

ALTER TABLE exhaustive_search_jobs DROP CONSTRAINT IF EXISTS exhaustive_search_jobs_initiator_id_fkey;
ALTER TABLE exhaustive_search_jobs
    ADD CONSTRAINT exhaustive_search_jobs_initiator_id_fkey
    FOREIGN KEY (initiator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE;
