-- compendia holds AI-generated code compendia (Compendia): one row per compendium, which
-- doubles as the dbworker job that generates (and regenerates) it.
CREATE TABLE IF NOT EXISTS compendia (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

    -- rand_id is the stable, non-enumerable public identifier the compendium's
    -- URL uses (/compendium/{rand_id}), so links never expose the serial id.
    rand_id UUID NOT NULL DEFAULT gen_random_uuid(),
    -- slug is an optional share name for the URL (/compendium/{slug}), set from
    -- the title when the first edition completes and editable afterwards. The
    -- rand_id URL keeps working whatever the slug is.
    slug TEXT,

    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    -- request is the free-text ask the compendium answers ("give me a compendium for the
    -- search backend"). Repositories it names are read from the text by the
    -- planner; nothing scopes it beyond that.
    request TEXT NOT NULL,

    -- compendium holds the current edition as an opaque JSON blob, NULL until the
    -- job completes. It is the copy the search document, the citations and the
    -- freshness check derive from; every edition stored, this one included, is
    -- also a row of compendium_editions.
    compendium JSONB,
    edition INTEGER NOT NULL DEFAULT 0,

    -- directions are the standing instructions distilled from readers' notes
    -- (see compendium_notes). They are fed to every agent that writes an edition,
    -- so a reader's preferences carry across regenerations.
    directions TEXT NOT NULL DEFAULT '',

    -- freshness records what the periodic check found when it compared the
    -- current edition's pinned commits (stored in the compendium blob) with the
    -- repositories' heads: which cited paths changed and which chapters that
    -- makes stale. NULL until checked; cleared whenever the edition changes.
    -- The columns beside it are the check's bookkeeping, which the worker
    -- schedules by: when it last ran, since when the edition has been stale
    -- (NULL while it is not), and, when the check could not compare the
    -- edition with the code (a cited repository gone, say), how many times
    -- in a row, since when, and why. The verdict in the blob is then the
    -- last one that succeeded.
    freshness JSONB,
    freshness_checked_at TIMESTAMP WITH TIME ZONE,
    freshness_stale_since TIMESTAMP WITH TIME ZONE,
    freshness_check_failures INTEGER NOT NULL DEFAULT 0,
    freshness_check_failed_at TIMESTAMP WITH TIME ZONE,
    freshness_check_error TEXT,

    -- revise_chapters, when set on a queued row, asks the worker to rewrite
    -- only these chapters of the current edition (keeping the edition number)
    -- instead of generating a new edition. NULL for a full generation.
    revise_chapters TEXT[],

    -- rewrite, when set on a queued row, asks the worker to write every
    -- chapter of the new edition afresh instead of carrying over the ones
    -- whose code did not change: for when the generator itself changed.
    -- Cleared when the edition is stored.
    rewrite BOOLEAN NOT NULL DEFAULT FALSE,

    -- auto_refresh keeps the compendium up to date without anyone asking,
    -- which new compendia are until someone opts them out: once the
    -- freshness check finds the edition has drifted and the drift has
    -- settled, the worker queues the remedy the check recommends (a revision
    -- of the stale chapters, or a new edition when the code was
    -- reorganized). auto_refreshed_at is when it last did so, which spaces
    -- automatic refreshes out.
    auto_refresh BOOLEAN NOT NULL DEFAULT TRUE,
    auto_refreshed_at TIMESTAMP WITH TIME ZONE,

    -- search is the full-text document for the directory's search box, kept
    -- by Postgres from the request and the current edition: headline and
    -- request weigh most, then the deck and chapter headings, then chapter
    -- decks, and the lede and chapter bodies least. websearch_to_tsquery
    -- matches it and ts_rank_cd orders the results.
    search TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', request), 'A') ||
        setweight(to_tsvector('english', COALESCE(compendium->>'title', '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(compendium->>'deck', '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(jsonb_path_query_array(compendium, '$.chapters[*].heading')::text, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(jsonb_path_query_array(compendium, '$.chapters[*].deck')::text, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(compendium->>'lede', '')), 'D') ||
        setweight(to_tsvector('english', COALESCE(jsonb_path_query_array(compendium, '$.chapters[*].body')::text, '')), 'D')
    ) STORED,

    -- search_text is the request and the current edition's headline as one
    -- string, for the directory's search box to match a fragment of a word
    -- (an identifier, a repository path) that the stemmed document cannot.
    -- Its trigram index serves ILIKE; matching other text columns in the
    -- same query would scan every row.
    search_text TEXT GENERATED ALWAYS AS (
        request || ' ' || COALESCE(compendium->>'title', '')
    ) STORED,

    -- When the generation the row is queued for was asked for. The
    -- dbworker moves queued_at when it reclaims a stalled attempt; this
    -- stays, so an edition stored after it is that generation's result.
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Standard workerutil columns.
    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE compendia ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendia;
CREATE POLICY tenant_isolation_policy ON compendia AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS compendia_dequeue_idx
    ON compendia USING btree (tenant_id, state, process_after, queued_at, id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX IF NOT EXISTS compendia_created_at_idx ON compendia (tenant_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS compendia_rand_id_unique ON compendia (tenant_id, rand_id);

CREATE UNIQUE INDEX IF NOT EXISTS compendia_slug_unique ON compendia (tenant_id, slug);

CREATE INDEX IF NOT EXISTS compendia_freshness_checked_at_idx ON compendia (tenant_id, freshness_checked_at) WHERE compendium IS NOT NULL;

CREATE INDEX IF NOT EXISTS compendia_search_idx ON compendia USING GIN (search);

CREATE INDEX IF NOT EXISTS compendia_search_text_trgm_idx ON compendia USING GIN (search_text gin_trgm_ops);

-- compendium_editions keeps every edition a compendium has had, the current one
-- included, so earlier editions can be compared and analyzed. One row is added
-- each time the worker stores a result; the compendia row's compendium column
-- is the newest row's blob. A chapter-level revision keeps the edition number,
-- so (compendium_id, edition) can repeat; id orders rows within a compendium.
CREATE TABLE IF NOT EXISTS compendium_editions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    edition INTEGER NOT NULL,
    -- kind is 'generation' for a new edition and 'revision' for a chapter-level
    -- revision of the edition before it.
    kind TEXT NOT NULL CHECK (kind IN ('generation', 'revision')),
    compendium JSONB NOT NULL,
    -- user_id is who requested the generation, when known.
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE compendium_editions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_editions;
CREATE POLICY tenant_isolation_policy ON compendium_editions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS compendium_editions_compendium_id_idx ON compendium_editions (tenant_id, compendium_id, id DESC);

-- current_edition_id is the compendium_editions row whose blob the compendium
-- column holds, set in the same statement. It names the edition a freshness
-- verdict was reached on, so a check that read an edition since replaced is
-- not recorded against its successor. NULL until the first edition. Not a
-- foreign key: editions are only ever deleted with their compendium.
ALTER TABLE compendia ADD COLUMN IF NOT EXISTS current_edition_id BIGINT;

-- compendium_citations indexes which repositories, directories and files a compendium's
-- current edition cites, so repository pages can list the compendia that cite
-- them. It is derived from the compendium blob and rewritten whenever it changes.
CREATE TABLE IF NOT EXISTS compendium_citations (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    repo_name TEXT NOT NULL,
    -- path is the cited file or directory path, or '' for the repository as a whole.
    path TEXT NOT NULL DEFAULT '',
    CONSTRAINT compendium_citations_unique UNIQUE (tenant_id, compendium_id, repo_name, path)
);

ALTER TABLE compendium_citations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_citations;
CREATE POLICY tenant_isolation_policy ON compendium_citations AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS compendium_citations_repo_path_idx ON compendium_citations (tenant_id, repo_name, path text_pattern_ops);

-- compendium_links indexes which other compendia a compendium's current
-- edition points at (as related reading or from its prose), so a compendium
-- page can list the compendia that cite it. Like compendium_citations it is
-- derived from the compendium blob and rewritten whenever it changes.
CREATE TABLE IF NOT EXISTS compendium_links (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    -- target_public_id is the rand_id of the compendium pointed at, as text
    -- and lowercased, so that a link to a compendium since deleted still
    -- says what it pointed at.
    target_public_id TEXT NOT NULL,
    CONSTRAINT compendium_links_unique UNIQUE (tenant_id, compendium_id, target_public_id)
);

ALTER TABLE compendium_links ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_links;
CREATE POLICY tenant_isolation_policy ON compendium_links AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS compendium_links_target_idx ON compendium_links (tenant_id, target_public_id, compendium_id DESC);

-- compendium_diagrams holds diagrams readers request on demand for a compendium ("draw
-- the request lifecycle"). Each row is its own dbworker job.
CREATE TABLE IF NOT EXISTS compendium_diagrams (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    request TEXT NOT NULL,
    diagram JSONB,

    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE compendium_diagrams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_diagrams;
CREATE POLICY tenant_isolation_policy ON compendium_diagrams AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS compendium_diagrams_dequeue_idx
    ON compendium_diagrams USING btree (tenant_id, state, process_after, queued_at, id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX IF NOT EXISTS compendium_diagrams_compendium_id_idx ON compendium_diagrams (tenant_id, compendium_id);

-- compendium_threads binds Deep Search conversations to the part of a compendium they
-- were asked about (a chapter or a diagram component), so they are shown
-- again next to it.
CREATE TABLE IF NOT EXISTS compendium_threads (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    deepsearch_conversation_id INTEGER NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    -- anchor_kind is 'compendium', 'chapter' or 'diagram_node'; anchor_id is the
    -- chapter or node id ('' for the compendium as a whole).
    anchor_kind TEXT NOT NULL,
    anchor_id TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT compendium_threads_conversation_unique UNIQUE (tenant_id, deepsearch_conversation_id)
);

ALTER TABLE compendium_threads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_threads;
CREATE POLICY tenant_isolation_policy ON compendium_threads AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS compendium_threads_compendium_id_idx ON compendium_threads (tenant_id, compendium_id);

-- compendium_notes holds what readers tell the generator to do differently next
-- time ("less on config, more on the retry loop"), optionally with an image
-- such as a hand-drawn diagram. Notes never appear in the compendium; before each
-- regeneration the pending ones are distilled into compendia.directions.
CREATE TABLE IF NOT EXISTS compendium_notes (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    compendium_id BIGINT NOT NULL REFERENCES compendia(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    body TEXT NOT NULL,
    image BYTEA,
    image_mime TEXT,

    -- applied_edition is the edition whose generation folded the note into
    -- the directions; NULL while the note is pending.
    applied_edition INTEGER,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE compendium_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON compendium_notes;
CREATE POLICY tenant_isolation_policy ON compendium_notes AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS compendium_notes_compendium_id_idx ON compendium_notes (tenant_id, compendium_id);
