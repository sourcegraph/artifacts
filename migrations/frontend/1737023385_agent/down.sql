-- Undo the changes made in the up migration
DROP TABLE IF EXISTS agents CASCADE;
DROP TABLE IF EXISTS agent_connections CASCADE;
DROP TABLE IF EXISTS agent_programs CASCADE;
