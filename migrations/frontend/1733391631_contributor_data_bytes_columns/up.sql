DELETE FROM contributor_data WHERE true;
DELETE FROM contributor_jobs WHERE true;
DELETE FROM contributor_repos WHERE true;

ALTER TABLE contributor_data ALTER COLUMN author_email SET DATA TYPE bytea USING author_email::bytea;
ALTER TABLE contributor_data ALTER COLUMN author_name SET DATA TYPE bytea USING author_name::bytea;
