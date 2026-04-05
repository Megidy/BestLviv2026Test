DELETE FROM allocations WHERE created_at > NOW() - INTERVAL '9 days';
DELETE FROM delivery_request_items WHERE created_at > NOW() - INTERVAL '9 days';
DELETE FROM delivery_requests WHERE created_at > NOW() - INTERVAL '9 days';
