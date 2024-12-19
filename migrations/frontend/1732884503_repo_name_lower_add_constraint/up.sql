DO
$$
BEGIN
    IF to_regclass('repo_name_lower_unique_tmp') IS NOT NULL THEN
        ALTER TABLE repo DROP CONSTRAINT IF EXISTS repo_name_lower_unique;
        ALTER TABLE repo ADD CONSTRAINT repo_name_lower_unique UNIQUE USING INDEX repo_name_lower_unique_tmp DEFERRABLE;
   END IF;
END
$$;
COMMIT AND CHAIN;
