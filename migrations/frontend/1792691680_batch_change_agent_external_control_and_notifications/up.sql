-- Frozen choices for this run. Attended runs predate these columns.
ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS run_mode text NOT NULL DEFAULT 'attended' CHECK (run_mode IN ('attended', 'unattended')),
    ADD COLUMN IF NOT EXISTS started_externally boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS scope_repository_ids integer[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS canary boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ci_repair boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN batch_change_agents.started_externally IS 'Whether an API caller started this run; fixed at creation.';
COMMENT ON COLUMN batch_change_agents.scope_repository_ids IS 'Repository boundary for planning and execution of an unattended run. Its publication grant has the same repositories, but the reconciler reads grants to authorize code-host writes.';

ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS start_request_id uuid;
COMMENT ON COLUMN batch_change_agents.start_request_id IS 'Caller-chosen key of an external Start (MCP or API). A retried Start with the same key returns this agent. NULL for UI starts.';
-- Keep the caller's goal separate from the first message's planning instructions.
ALTER TABLE batch_change_agents ADD COLUMN IF NOT EXISTS goal text;
COMMENT ON COLUMN batch_change_agents.goal IS 'Original caller goal, before planning instructions and supplied context are composed into the first message. NULL on older runs whose input cannot be recovered.';

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agents_owner_start_request_id_idx
    ON batch_change_agents (tenant_id, owner_user_id, start_request_id) WHERE start_request_id IS NOT NULL;

ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS stopped_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS stopped_by text CHECK (stopped_by IN ('owner', 'admin'));
COMMENT ON COLUMN batch_change_agents.stopped_at IS 'When the owner or an administrator stopped the agent.';

ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS notification_observed_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS notified_awaiting_merge_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS notified_done_at timestamp with time zone;
COMMENT ON COLUMN batch_change_agents.notification_observed_at IS 'Last notification outcome observation committed with delivery; newer activity is eligible for the sweep.';

ALTER TABLE batch_change_agent_tool_approvals
 ADD COLUMN IF NOT EXISTS publication_batch_spec_id BIGINT REFERENCES batch_specs(id) ON DELETE SET NULL,
 ADD COLUMN IF NOT EXISTS publication_mode TEXT CHECK (publication_mode IN ('branch', 'draft', 'ready')),
 ADD COLUMN IF NOT EXISTS publication_repository_ids INTEGER[],
 ADD COLUMN IF NOT EXISTS publication_workspace_ids BIGINT[],
 ADD COLUMN IF NOT EXISTS publication_scope TEXT CHECK (publication_scope IN ('this_agent', 'all_attended_agents'));

COMMENT ON COLUMN batch_change_agent_tool_approvals.publication_batch_spec_id IS 'Identity of the materialized spec reviewed at the publication gate.';
COMMENT ON COLUMN batch_change_agent_tool_approvals.publication_mode IS 'Publication mode reviewed at the gate; the linked grant records the approved mode.';
COMMENT ON COLUMN batch_change_agent_tool_approvals.publication_repository_ids IS 'Repository bound reviewed at the publication gate; independent of later plans.';
COMMENT ON COLUMN batch_change_agent_tool_approvals.publication_workspace_ids IS 'Workspace selection reviewed at the publication gate.';
COMMENT ON COLUMN batch_change_agent_tool_approvals.publication_scope IS 'Scope decided by the owner; independent of later standing approvals and their revocation.';

ALTER TABLE batch_change_agent_tool_approvals ADD COLUMN IF NOT EXISTS system_decision_reason TEXT CHECK (system_decision_reason IN ('unattended_secret'));
COMMENT ON COLUMN batch_change_agent_tool_approvals.system_decision_reason IS 'Why the server decided this approval without an owner decision; NULL for human decisions and pending approvals.';

ALTER TABLE changesets ADD COLUMN IF NOT EXISTS failure_code TEXT CHECK (failure_code IN ('grant_revoked', 'agent_stopped', 'repository_hidden'));
COMMENT ON COLUMN changesets.failure_code IS 'Classified publication authority failure, independent of display text.';
ALTER TABLE changesets ADD COLUMN IF NOT EXISTS pushed_commit_sha TEXT;
COMMENT ON COLUMN changesets.pushed_commit_sha IS 'Head last pushed from a changeset spec by the reconciler; distinct from code-host observations and follow-up pushes.';

DROP VIEW IF EXISTS reconciler_changesets;

CREATE VIEW reconciler_changesets WITH (security_invoker = true) AS
 SELECT c.id,
    c.batch_change_ids,
    c.repo_id,
    c.queued_at,
    c.created_at,
    c.updated_at,
    c.metadata,
    c.external_id,
    c.external_service_type,
    c.external_deleted_at,
    c.external_branch,
    c.external_updated_at,
    c.external_state,
    c.external_review_state,
    c.external_check_state,
    c.commit_verification,
    c.diff_stat_added,
    c.diff_stat_deleted,
    c.sync_state,
    c.current_spec_id,
    c.previous_spec_id,
    c.last_pushed_spec_id,
    c.publication_state,
    c.owned_by_batch_change_id,
    c.reconciler_state,
    c.computed_state,
    c.failure_message,
    c.started_at,
    c.finished_at,
    c.process_after,
    c.num_resets,
    c.closing,
    c.num_failures,
    c.log_contents,
    c.execution_logs,
    c.syncer_error,
    c.external_title,
    c.worker_hostname,
    c.ui_publication_state,
    c.last_heartbeat_at,
    c.external_fork_name,
    c.external_fork_namespace,
    c.detached_at,
    c.previous_failure_message,
    c.tenant_id,
    c.auto_merge_method,
    c.sync_skip_reason,
    c.publish_entitlement_window_started_at,
    c.publish_entitlement_user_id,
    c.expected_head_sha,
    c.failure_code,
    c.pushed_commit_sha
   FROM (changesets c
     JOIN repo r ON ((r.id = c.repo_id)))
WHERE ((r.deleted_at IS NULL) AND (EXISTS ( SELECT 1
           FROM ((batch_changes
             LEFT JOIN users namespace_user ON ((batch_changes.namespace_user_id = namespace_user.id)))
             LEFT JOIN orgs namespace_org ON ((batch_changes.namespace_org_id = namespace_org.id)))
          WHERE ((c.batch_change_ids ? (batch_changes.id)::text) AND (namespace_user.deleted_at IS NULL) AND (namespace_org.deleted_at IS NULL)))));

ALTER TABLE batch_change_agents ADD COLUMN IF NOT EXISTS version bigint NOT NULL DEFAULT 0;
ALTER TABLE batch_change_agents ADD COLUMN IF NOT EXISTS visible_hash text NOT NULL DEFAULT '';
COMMENT ON COLUMN batch_change_agents.version IS 'Monotonic counter of observed visible read changes.';
COMMENT ON COLUMN batch_change_agents.visible_hash IS 'Hash of the last observed read projection, excluding version.';

COMMENT ON COLUMN batch_change_agents.stopped_by IS 'Role of the first stop actor relative to the owner; retained if the actor account is deleted.';

COMMENT ON COLUMN batch_change_agents.notified_awaiting_merge_at IS 'When awaiting merge was first announced to the owner.';
COMMENT ON COLUMN batch_change_agents.notified_done_at IS 'When completion was first announced to the owner.';

COMMENT ON COLUMN batch_change_agents.run_mode IS 'Interaction policy fixed when the run starts: attended or unattended.';
COMMENT ON COLUMN batch_change_agents.started_externally IS 'Whether an external caller started the run; fixed for its lifetime.';
COMMENT ON COLUMN batch_change_agents.canary IS 'Unattended runs only: execute one repository before the rest.';
COMMENT ON COLUMN batch_change_agents.ci_repair IS 'Unattended CI repair switch. Attended repair is controlled by the batch spec hooks.';
