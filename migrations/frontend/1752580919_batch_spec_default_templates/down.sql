-- Remove Amp batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'Amp free form prompt'
);

-- Remove Amp batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'Amp free form prompt';

-- Remove terraform-infrastructure-tags batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'terraform-infrastructure-tags'
);

-- Remove terraform-infrastructure-tags batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'terraform-infrastructure-tags';

-- Remove GitHub Actions: Pin Versions batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'GitHub Actions: Pin Versions'
);

-- Remove GitHub Actions: Pin Versions batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'GitHub Actions: Pin Versions';

-- Remove Ask Amp to fix CVE-2025-29927 batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'Ask Amp to fix CVE-2025-29927'
);

-- Remove Ask Amp to fix CVE-2025-29927 batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'Ask Amp to fix CVE-2025-29927';

-- Remove Hello World batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'Hello World'
);

-- Remove Hello World batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'Hello World';

-- Remove Text replacement batch spec library variables
DELETE FROM batch_spec_library_variables
WHERE batch_spec_library_record_id IN (
    SELECT id FROM batch_spec_library_records
    WHERE name = 'Text replacement'
);

-- Remove Text replacement batch spec library record
DELETE FROM batch_spec_library_records
WHERE name = 'Text replacement';
