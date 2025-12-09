# Database Migrations

This guide covers all requirements and best practices for creating database migrations in the Sourcegraph monolith.

## Creating Migrations

### Command

```bash
sg migration add -db=<dbname> <description>
```

After adding a migration and filling in the up and down migration code, **always run**:

```bash
sg generate
```

### Database Names

- `frontend` - Main database (use this unless there's a specific reason not to)
- `codeintel` - Processed SCIP data only
- `codeinsights` - Code Insights time series data only

### Migration Structure

Each migration creates three files in a timestamped directory:

- `up.sql` - Forward migration
- `down.sql` - Rollback migration
- `metadata.yaml` - Migration metadata

### metadata.yaml Fields

The `metadata.yaml` file controls migration behavior with these fields:

```yaml
name: my_migration_name # Required: Human-readable migration name
parents: [1234567890, 1234567891] # Required: Parent migration IDs
```

**Field Details:**

- **`name`** (string, required): Short description of what the migration does
- **`parents`** (array of integers, required): IDs of parent migrations. Multiple parents occur when merging branches
- **`privileged`** (boolean, optional): Set to `true` only for migrations requiring PostgreSQL superuser privileges (e.g., creating extensions). Avoid if possible.
- **`nonIdempotent`** (boolean, optional): Set to `true` if running the migration multiple times causes problems. Should almost never be used except for squash migrations.
- **`createIndexConcurrently`** (boolean, optional): Set to `true` when using `CREATE INDEX CONCURRENTLY`. This:
  - Runs the migration outside a transaction
  - Allows the index to be built without blocking writes
  - Use for large tables in production
  - **Important**: The up.sql must use `CREATE INDEX CONCURRENTLY`, not regular `CREATE INDEX`
- **`bestEffortTerminateBlockingTransactions`** (boolean, optional): Set to `true` to periodically kill transactions blocking the migration. Use for:
  - Long-running migrations on high-traffic tables
  - RLS policy changes
  - Constraint additions that need exclusive locks

## Critical Requirements

### 1. Idempotency (REQUIRED)

**Both `up.sql` and `down.sql` must be idempotent** - they can be run multiple times safely.

Always use:

- `CREATE TABLE IF NOT EXISTS ...`
- `DROP TABLE IF EXISTS ...`
- `ALTER TABLE ... ADD COLUMN IF NOT EXISTS ...`
- `ALTER TABLE ... DROP COLUMN IF EXISTS ...`
- `CREATE INDEX IF NOT EXISTS ...`
- `DROP INDEX IF EXISTS ...`
- `DROP POLICY IF EXISTS ... ON ...`

### 2. Tenant Isolation (REQUIRED)

🚨 **SECURITY**: All tables and views must be tenant-isolated unless explicitly exempted.

#### Tables Must Have tenant_id

Every table **must** include a `tenant_id` column with:

```sql
tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
```

**Example:**

```sql
CREATE TABLE IF NOT EXISTS my_table (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- other columns...
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

#### Tables Must Have Row Level Security (RLS)

Every table **must** enable RLS with a tenant isolation policy:

```sql
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON my_table;
CREATE POLICY tenant_isolation_policy ON my_table AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer));
```

#### Views Must Use security_invoker

Views **must** be created with `WITH (security_invoker = true)`:

```sql
DROP VIEW IF EXISTS my_view;

CREATE VIEW my_view WITH (security_invoker = true) AS
SELECT
    t1.id,
    t1.name
FROM my_table t1
WHERE t1.deleted_at IS NULL;
```

This ensures the view uses the calling user's permissions, not the view creator's.

#### Exemptions (Rare)

Only tables critical to system operation can be exempted. See `tablesWithoutTenant` and `viewsWithoutTenant` in `internal/database/connections/live/migration_test.go`:

- `tenants` (the tenant table itself)
- `migration_logs` (maintained by migrator)
- `versions` (maintained by migrator)
- `out_of_band_migrations` (migrator system table)
- `critical_and_site_config` (global instance config)
- `pg_stat_statements` and `pg_stat_statements_info` (system views)

### 3. Uniqueness Constraints Must Include tenant_id

🚨 **SECURITY**: Unique constraints **must include tenant_id** to prevent cross-tenant data leakage.

**Bad (leaks data across tenants):**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS my_table_unique_email ON my_table (email);
```

**Good (isolated by tenant):**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS my_table_unique_email ON my_table (tenant_id, email);
```

**For conditional unique indexes:**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS my_table_unique_active
    ON my_table (tenant_id, user_id, client_id)
    WHERE revoked_at IS NULL;
```

### 4. Primary Keys (REQUIRED)

Every table **must** have a primary key, and the primary key must either be a SERIAL, BIGSERIAL, UUID, or be a composite key that includes tenant_id (try to avoid composite keys):

```sql
CREATE TABLE IF NOT EXISTS my_table (
    id BIGSERIAL PRIMARY KEY,
    -- ...
);
```

### 5. Backwards Compatibility (REQUIRED)

**DB-first migrations**: Old code must be able to run against new database versions.

When **removing** features:

1. First PR: Remove all code dependencies
2. Later PR (separate migration): Remove database schema

When **adding** features:

- New columns should have defaults or allow NULL initially
- New tables won't break old code
- Renaming requires multi-step approach (add new, migrate, remove old)

### 6. Transactions

Migrations **automatically run in transactions**. No need to wrap in `BEGIN`/`COMMIT`. If you need to break two statements to release locks and avoid long-held locks, use `COMMIT AND CHAIN;`.

## Additional Resources

- [Writing database migrations](https://sourcegraph.sourcegraph.com/github.com/sourcegraph/sourcegraph/-/blob/doc/dev/background-information/sql/migrations.md) - Developer documentation
- `internal/database/AGENTS.md` - Database conventions and general guidance
- `internal/database/schema.*.md` - Current schema documentation for each database
- `internal/database/connections/live/migration_test.go` - All validation rules
