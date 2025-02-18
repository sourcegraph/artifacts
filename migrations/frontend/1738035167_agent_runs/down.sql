DROP TABLE IF EXISTS agent_runs CASCADE;
DROP TABLE IF EXISTS agent_run_logs CASCADE;
DROP FUNCTION IF EXISTS update_agent_runs_updated_at();
DROP TRIGGER IF EXISTS update_agent_runs_updated_at ON agent_runs;
