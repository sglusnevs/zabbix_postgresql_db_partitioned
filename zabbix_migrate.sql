

SET TIME ZONE 'UTC';

-- data migration commands
-- !!! stop writers before running the copy/swap.

INSERT INTO public.trends_part
SELECT * FROM public.trends;

INSERT INTO public.trends_uint_part
SELECT * FROM public.trends_uint;

INSERT INTO public.history_part
SELECT * FROM public.history;

INSERT INTO public.history_uint_part
SELECT * FROM public.history_uint;

INSERT INTO public.history_log_part
SELECT * FROM public.history_log;

INSERT INTO public.history_str_part
SELECT * FROM public.history_str;

INSERT INTO public.history_text_part
SELECT * FROM public.history_text;

INSERT INTO public.history_bin_part
SELECT * FROM public.history_bin;

INSERT INTO public.auditlog_part (
    auditid, userid, username, clock, ip, action, resourcetype,
    resourceid, resource_cuid, resourcename, recordsetid, details
)
SELECT
    auditid, userid, username, clock, ip, action, resourcetype,
    resourceid, resource_cuid, resourcename, recordsetid, details
FROM public.auditlog;

-- update query optimizer stats
ANALYZE public.trends_part;
ANALYZE public.trends_uint_part;
ANALYZE public.history_part;
ANALYZE public.history_uint_part;
ANALYZE public.history_log_part;
ANALYZE public.history_str_part;
ANALYZE public.history_text_part;
ANALYZE public.history_bin_part;
ANALYZE public.auditlog_part;


