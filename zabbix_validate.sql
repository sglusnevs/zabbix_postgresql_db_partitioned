

-- chack if all data has been copied into partitioned tables

SELECT 'trends' AS tbl, count(*) FROM public.trends
UNION ALL
SELECT 'trends_part', count(*) FROM public.trends_part;

SELECT 'history' AS tbl, count(*) FROM public.history
UNION ALL
SELECT 'history_part', count(*) FROM public.history_part;

SELECT 'history_uint' AS tbl, count(*) FROM public.history_uint
UNION ALL
SELECT 'history_uint_part', count(*) FROM public.history_uint_part;

SELECT 'history_bin' AS tbl, count(*) FROM public.history_bin
UNION ALL
SELECT 'history_bin_part', count(*) FROM public.history_bin_part;

SELECT 'history_str' AS tbl, count(*) FROM public.history_str
UNION ALL
SELECT 'history_str_part', count(*) FROM public.history_str_part;

SELECT 'history_log' AS tbl, count(*) FROM public.history_log
UNION ALL
SELECT 'history_log_part', count(*) FROM public.history_log_part;

SELECT 'history_text' AS tbl, count(*) FROM public.history_text
UNION ALL
SELECT 'history_text_part', count(*) FROM public.history_text_part;

SELECT 'auditlog' AS tbl, count(*) FROM public.auditlog
UNION ALL
SELECT 'auditlog_part', count(*) FROM public.auditlog_part;

-- check how many partition have been created for each parent table
SELECT
    parent.relname  AS parent_table,
    child.relname   AS partition_name
FROM pg_inherits i
JOIN pg_class parent ON parent.oid = i.inhparent
JOIN pg_class child  ON child.oid  = i.inhrelid
JOIN pg_namespace n  ON n.oid = parent.relnamespace
WHERE n.nspname = 'public'
  AND parent.relname IN (
      'trends_part','trends_uint_part',
      'history_part','history_uint_part','history_log_part',
      'history_str_part','history_text_part','history_bin_part',
      'auditlog_part'
  )
ORDER BY 1,2;
