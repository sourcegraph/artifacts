DELETE FROM contributor_data WHERE true;
DELETE FROM contributor_jobs WHERE true;
DELETE FROM contributor_repos WHERE true;

ALTER TABLE contributor_data ALTER COLUMN author_email SET DATA TYPE TEXT USING author_email::text;
ALTER TABLE contributor_data ALTER COLUMN author_name SET DATA TYPE TEXT USING author_name::text;
