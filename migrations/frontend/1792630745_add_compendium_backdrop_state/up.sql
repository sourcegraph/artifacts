ALTER TABLE compendia ADD COLUMN IF NOT EXISTS backdrop jsonb;

COMMENT ON COLUMN compendia.backdrop IS 'One-time backdrop attempt and media type. Image bytes live in sourcegraphobjects; ready is set after upload.';
