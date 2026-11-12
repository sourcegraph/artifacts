-- Search jobs pending deletion have no initiator and cannot satisfy NOT NULL.
-- Their results stay in object storage.
DELETE FROM exhaustive_search_jobs WHERE initiator_id IS NULL;

ALTER TABLE exhaustive_search_jobs DROP CONSTRAINT IF EXISTS exhaustive_search_jobs_initiator_id_fkey;
ALTER TABLE exhaustive_search_jobs
    ADD CONSTRAINT exhaustive_search_jobs_initiator_id_fkey
    FOREIGN KEY (initiator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;

ALTER TABLE exhaustive_search_jobs ALTER COLUMN initiator_id SET NOT NULL;
