-- Related to bug fixed in https://github.com/sourcegraph/sourcegraph/pull/3699
TRUNCATE TABLE rockskip_ancestry CASCADE;
TRUNCATE TABLE rockskip_repos CASCADE;
TRUNCATE TABLE rockskip_symbols CASCADE;
