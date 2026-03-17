SET TIME ZONE 'UTC';

CREATE TABLE IF NOT EXISTS public.trends_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    num         integer          DEFAULT '0'                 NOT NULL,
    value_min   double precision DEFAULT '0.0000'           NOT NULL,
    value_avg   double precision DEFAULT '0.0000'           NOT NULL,
    value_max   double precision DEFAULT '0.0000'           NOT NULL,
    PRIMARY KEY (itemid, clock)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.trends_uint_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    num         integer          DEFAULT '0'                 NOT NULL,
    value_min   numeric(20)      DEFAULT '0'                 NOT NULL,
    value_avg   numeric(20)      DEFAULT '0'                 NOT NULL,
    value_max   numeric(20)      DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       double precision DEFAULT '0.0000'           NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_uint_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       numeric(20)      DEFAULT '0'                 NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_log_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    "timestamp" integer          DEFAULT '0'                 NOT NULL,
    source      varchar(64)      DEFAULT ''                  NOT NULL,
    severity    integer          DEFAULT '0'                 NOT NULL,
    value       text             DEFAULT ''                  NOT NULL,
    logeventid  integer          DEFAULT '0'                 NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_str_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       varchar(255)     DEFAULT ''                  NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_text_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       text             DEFAULT ''                  NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.history_bin_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       bytea                                        NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE TABLE IF NOT EXISTS public.auditlog_part (
    auditid       varchar(25)                                NOT NULL,
    userid        bigint                                     NULL,
    username      varchar(100)     DEFAULT ''                NOT NULL,
    clock         integer          DEFAULT '0'               NOT NULL,
    ip            varchar(39)      DEFAULT ''                NOT NULL,
    action        integer          DEFAULT '0'               NOT NULL,
    resourcetype  integer          DEFAULT '0'               NOT NULL,
    resourceid    bigint                                     NULL,
    resource_cuid varchar(25)                                NULL,
    resourcename  varchar(255)     DEFAULT ''                NOT NULL,
    recordsetid   varchar(25)                                NOT NULL,
    details       text             DEFAULT ''                NOT NULL,
    PRIMARY KEY (auditid, clock)
) PARTITION BY RANGE (clock);

-- helps for big tables
CREATE INDEX IF NOT EXISTS auditlog_part_clock_idx
    ON public.auditlog_part (clock DESC);

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
    v_child_name := format('%s_%s', p_parent, to_char(p_day, 'YYYYMMDD'));
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
    v_child_name  := format('%s_%s', p_parent, to_char(v_month_start, 'YYYYMM'));
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

CREATE OR REPLACE FUNCTION public.ensure_daily_partitions(
    p_parent   text,
    p_from_day date,
    p_to_day   date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    d date;
BEGIN
    d := p_from_day;
    WHILE d <= p_to_day LOOP
        PERFORM public.create_daily_partition(p_parent, d);
        d := d + 1;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_monthly_partitions(
    p_parent   text,
    p_from_day date,
    p_to_day   date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    d date;
BEGIN
    d := date_trunc('month', p_from_day)::date;
    WHILE d <= date_trunc('month', p_to_day)::date LOOP
        PERFORM public.create_monthly_partition(p_parent, d);
        d := (d + interval '1 month')::date;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.drop_daily_partitions_older_than(
    p_parent    text,
    p_keep_from date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    r record;
    v_part_date date;
BEGIN
    FOR r IN
        SELECT c.relname AS child_name
        FROM pg_inherits i
        JOIN pg_class p ON p.oid = i.inhparent
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND p.relname = p_parent
    LOOP
        IF r.child_name ~ ('^' || p_parent || '_[0-9]{8}$') THEN
            v_part_date := to_date(right(r.child_name, 8), 'YYYYMMDD');

            IF v_part_date < p_keep_from THEN
                EXECUTE format(
                    'ALTER TABLE public.%I DETACH PARTITION public.%I',
                    p_parent, r.child_name
                );
                EXECUTE format(
                    'DROP TABLE IF EXISTS public.%I',
                    r.child_name
                );
            END IF;
        END IF;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.drop_monthly_partitions_older_than(
    p_parent    text,
    p_keep_from date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    r record;
    v_month_start date;
    v_month_end   date;
BEGIN
    FOR r IN
        SELECT c.relname AS child_name
        FROM pg_inherits i
        JOIN pg_class p ON p.oid = i.inhparent
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND p.relname = p_parent
    LOOP
        IF r.child_name ~ ('^' || p_parent || '_[0-9]{6}$') THEN
            v_month_start := to_date(right(r.child_name, 6) || '01', 'YYYYMMDD');
            v_month_end   := (v_month_start + interval '1 month')::date;

            IF v_month_end <= p_keep_from THEN
                EXECUTE format(
                    'ALTER TABLE public.%I DETACH PARTITION public.%I',
                    p_parent, r.child_name
                );
                EXECUTE format(
                    'DROP TABLE IF EXISTS public.%I',
                    r.child_name
                );
            END IF;
        END IF;
    END LOOP;
END;
$$;


-- create partitions covering current source data range
-- after the parent tables/functions are in place.

SELECT public.ensure_monthly_partitions(
    'trends_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.trends), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.trends), current_date)
);

SELECT public.ensure_monthly_partitions(
    'trends_uint_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.trends_uint), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.trends_uint), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_bin_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_bin), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_bin), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_uint_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_uint), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_uint), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_log_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_log), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_log), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_str_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_str), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_str), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_text_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_text), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_text), current_date)
);

SELECT public.ensure_daily_partitions(
    'history_bin_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.history_bin), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.history_bin), current_date)
);

-- auditlog
SELECT public.ensure_monthly_partitions(
    'auditlog_part',
    COALESCE((SELECT to_timestamp(min(clock))::date FROM public.auditlog), current_date),
    COALESCE((SELECT to_timestamp(max(clock))::date FROM public.auditlog), current_date)
);

