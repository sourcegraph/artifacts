-- When the message's author last edited it, or null if they never did.
ALTER TABLE change_request_chat_messages ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;
