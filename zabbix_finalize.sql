-- create one daily partition
-- child name example: history_part_20260313
CREATE OR REPLACE FUNCTION public.create_daily_partition(
    p_parent text,
    p_day    date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_child_name text;
    v_from_epoch bigint;
    v_to_epoch   bigint;
BEGIN
    v_child_name := format('%s_part_%s', p_parent, to_char(p_day, 'YYYYMMDD'));
    v_from_epoch := extract(epoch FROM p_day::timestamp)::bigint;
    v_to_epoch   := extract(epoch FROM (p_day + 1)::timestamp)::bigint;

    IF to_regclass(format('public.%I', v_child_name)) IS NULL THEN
        EXECUTE format(
            'CREATE TABLE public.%I PARTITION OF public.%I
             FOR VALUES FROM (%s) TO (%s)',
            v_child_name, p_parent, v_from_epoch, v_to_epoch
        );
    END IF;
END;
$$;

-- create one monthly partition
-- child name example: trends_part_202603

CREATE OR REPLACE FUNCTION public.create_monthly_partition(
    p_parent text,
    p_month  date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_month_start date;
    v_next_month  date;
    v_child_name  text;
    v_from_epoch  bigint;
    v_to_epoch    bigint;
BEGIN
    v_month_start := date_trunc('month', p_month)::date;
    v_next_month  := (date_trunc('month', p_month) + interval '1 month')::date;
    v_child_name  := format('%s_part_%s', p_parent, to_char(v_month_start, 'YYYYMM'));
    v_from_epoch  := extract(epoch FROM v_month_start::timestamp)::bigint;
    v_to_epoch    := extract(epoch FROM v_next_month::timestamp)::bigint;

    IF to_regclass(format('public.%I', v_child_name)) IS NULL THEN
        EXECUTE format(
            'CREATE TABLE public.%I PARTITION OF public.%I
             FOR VALUES FROM (%s) TO (%s)',
            v_child_name, p_parent, v_from_epoch, v_to_epoch
        );
    END IF;
END;
$$;

-- rename tables

begin;

ALTER TABLE public.trends      RENAME TO trends_old;
ALTER TABLE public.trends_part RENAME TO trends;

ALTER TABLE public.trends_uint      RENAME TO trends_uint_old;
ALTER TABLE public.trends_uint_part RENAME TO trends_uint;

ALTER TABLE public.history      RENAME TO history_old;
ALTER TABLE public.history_part RENAME TO history;

ALTER TABLE public.history_uint      RENAME TO history_uint_old;
ALTER TABLE public.history_uint_part RENAME TO history_uint;

ALTER TABLE public.history_log      RENAME TO history_log_old;
ALTER TABLE public.history_log_part RENAME TO history_log;

ALTER TABLE public.history_str      RENAME TO history_str_old;
ALTER TABLE public.history_str_part RENAME TO history_str;

ALTER TABLE public.history_text      RENAME TO history_text_old;
ALTER TABLE public.history_text_part RENAME TO history_text;

ALTER TABLE public.history_bin      RENAME TO history_bin_old;
ALTER TABLE public.history_bin_part RENAME TO history_bin;

ALTER TABLE public.auditlog      RENAME TO auditlog_old;
ALTER TABLE public.auditlog_part RENAME TO auditlog;

commit;