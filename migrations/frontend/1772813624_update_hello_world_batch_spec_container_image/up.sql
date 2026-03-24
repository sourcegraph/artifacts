UPDATE batch_spec_library_records
SET spec = REPLACE(spec, 'container: ubuntu:18.04', 'container: ubuntu:22.04')
WHERE name IN ('hello-world', 'Hello World')
  AND spec LIKE '%container: ubuntu:18.04%';
