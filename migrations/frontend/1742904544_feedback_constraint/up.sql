-- Update existing data to set null values for invalid confusion labels
UPDATE agent_review_diagnostic_feedback 
SET data = jsonb_set(data, '{confusion_label}', 'null'::jsonb) 
WHERE data->>'confusion_label' IS NOT NULL 
AND data->>'confusion_label' NOT IN ('true-positive', 'false-positive', 'true-negative', 'false-negative');

ALTER TABLE agent_review_diagnostic_feedback DROP CONSTRAINT IF EXISTS check_confusion_label;
ALTER TABLE agent_review_diagnostic_feedback ADD CONSTRAINT check_confusion_label CHECK ((data->>'confusion_label' IS NULL) OR (data->>'confusion_label' IN ('true-positive', 'false-positive', 'true-negative', 'false-negative')));


-- Update existing data to set null values for invalid likert labels
UPDATE agent_review_diagnostic_feedback 
SET data = jsonb_set(data, '{helpfulness_label}', 'null'::jsonb)
WHERE data->>'helpfulness_label' IS NOT NULL 
AND data->>'helpfulness_label' NOT IN ('strongly-agree', 'agree', 'neutral', 'disagree', 'strongly-disagree');

ALTER TABLE agent_review_diagnostic_feedback DROP CONSTRAINT IF EXISTS check_helpfulness_label;
ALTER TABLE agent_review_diagnostic_feedback ADD CONSTRAINT check_helpfulness_label CHECK ((data->>'helpfulness_label' IS NULL) OR (data->>'helpfulness_label' IN ('strongly-agree', 'agree', 'neutral', 'disagree', 'strongly-disagree')));
