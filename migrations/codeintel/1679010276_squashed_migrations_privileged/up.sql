CREATE EXTENSION IF NOT EXISTS intarray;

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';

DO $$
BEGIN
	CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
	COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';
EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE 'Failed to install optional extension, skipping: pg_stat_statements: %', SQLERRM;
END
$$;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';
