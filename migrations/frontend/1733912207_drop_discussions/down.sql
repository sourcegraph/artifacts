CREATE TABLE IF NOT EXISTS discussion_comments (
    id BIGSERIAL PRIMARY KEY,
    thread_id bigint NOT NULL,
    author_user_id integer NOT NULL,
    contents text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    reports text[] DEFAULT '{}'::text[] NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE IF NOT EXISTS discussion_mail_reply_tokens (
    token text NOT NULL,
    user_id integer NOT NULL,
    thread_id bigint NOT NULL,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE IF NOT EXISTS discussion_threads (
    id BIGSERIAL PRIMARY KEY,
    author_user_id integer NOT NULL,
    title text,
    target_repo_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    archived_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE IF NOT EXISTS discussion_threads_target_repo (
    id BIGSERIAL PRIMARY KEY,
    thread_id bigint NOT NULL,
    repo_id integer NOT NULL,
    path text,
    branch text,
    revision text,
    start_line integer,
    end_line integer,
    start_character integer,
    end_character integer,
    lines_before text,
    lines text,
    lines_after text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE INDEX IF NOT EXISTS discussion_comments_author_user_id_idx ON discussion_comments USING btree (author_user_id);

CREATE INDEX IF NOT EXISTS discussion_comments_reports_array_length_idx ON discussion_comments USING btree (array_length(reports, 1));

CREATE INDEX IF NOT EXISTS discussion_comments_thread_id_idx ON discussion_comments USING btree (thread_id);

CREATE INDEX IF NOT EXISTS discussion_mail_reply_tokens_user_id_thread_id_idx ON discussion_mail_reply_tokens USING btree (user_id, thread_id);

CREATE INDEX IF NOT EXISTS discussion_threads_author_user_id_idx ON discussion_threads USING btree (author_user_id);

CREATE INDEX IF NOT EXISTS discussion_threads_target_repo_repo_id_path_idx ON discussion_threads_target_repo USING btree (repo_id, path);

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'discussion_comments_author_user_id_fkey'
  ) THEN
    ALTER TABLE discussion_mail_reply_tokens ADD CONSTRAINT discussion_mail_reply_tokens_pkey PRIMARY KEY (token, tenant_id);

    ALTER TABLE discussion_comments
        ADD CONSTRAINT discussion_comments_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE RESTRICT;

    ALTER TABLE discussion_comments
        ADD CONSTRAINT discussion_comments_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES discussion_threads(id) ON DELETE CASCADE;

    ALTER TABLE discussion_mail_reply_tokens
        ADD CONSTRAINT discussion_mail_reply_tokens_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES discussion_threads(id) ON DELETE CASCADE;

    ALTER TABLE discussion_mail_reply_tokens
        ADD CONSTRAINT discussion_mail_reply_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;

    ALTER TABLE discussion_threads
        ADD CONSTRAINT discussion_threads_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE RESTRICT;

    ALTER TABLE discussion_threads
        ADD CONSTRAINT discussion_threads_target_repo_id_fk FOREIGN KEY (target_repo_id) REFERENCES discussion_threads_target_repo(id) ON DELETE CASCADE;

    ALTER TABLE discussion_threads_target_repo
        ADD CONSTRAINT discussion_threads_target_repo_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

    ALTER TABLE discussion_threads_target_repo
        ADD CONSTRAINT discussion_threads_target_repo_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES discussion_threads(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE POLICY tenant_isolation_policy_new ON discussion_comments USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON discussion_comments;
ALTER POLICY tenant_isolation_policy_new ON discussion_comments RENAME TO tenant_isolation_policy;

CREATE POLICY tenant_isolation_policy_new ON discussion_mail_reply_tokens USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON discussion_mail_reply_tokens;
ALTER POLICY tenant_isolation_policy_new ON discussion_mail_reply_tokens RENAME TO tenant_isolation_policy;

CREATE POLICY tenant_isolation_policy_new ON discussion_threads USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON discussion_threads;
ALTER POLICY tenant_isolation_policy_new ON discussion_threads RENAME TO tenant_isolation_policy;

CREATE POLICY tenant_isolation_policy_new ON discussion_threads_target_repo USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON discussion_threads_target_repo;
ALTER POLICY tenant_isolation_policy_new ON discussion_threads_target_repo RENAME TO tenant_isolation_policy;
