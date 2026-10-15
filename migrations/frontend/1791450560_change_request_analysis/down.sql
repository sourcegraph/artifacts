DROP TRIGGER IF EXISTS change_request_analysis_enqueue ON change_requests;
DROP FUNCTION IF EXISTS enqueue_change_request_analysis();
DROP TABLE IF EXISTS change_request_file_groupings;
DROP TABLE IF EXISTS change_request_analysis_jobs;
