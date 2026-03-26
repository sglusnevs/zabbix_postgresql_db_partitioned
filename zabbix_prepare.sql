SET TIME ZONE 'UTC';

drop table public.trends_part;
CREATE TABLE public.trends_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    num         integer          DEFAULT '0'                 NOT NULL,
    value_min   double precision DEFAULT '0.0000'           NOT NULL,
    value_avg   double precision DEFAULT '0.0000'           NOT NULL,
    value_max   double precision DEFAULT '0.0000'           NOT NULL
) PARTITION BY RANGE (clock);

CREATE INDEX trends_part_itemid_clock_idx 
ON public.trends_part (itemid, clock);

drop table public.trends_uint_part;
CREATE TABLE IF NOT EXISTS public.trends_uint_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    num         integer          DEFAULT '0'                 NOT NULL,
    value_min   numeric(20)      DEFAULT '0'                 NOT NULL,
    value_avg   numeric(20)      DEFAULT '0'                 NOT NULL,
    value_max   numeric(20)      DEFAULT '0'                 NOT NULL
) PARTITION BY RANGE (clock);

CREATE INDEX trends_uint_part_clock_idx 
ON public.trends_uint_part (itemid, clock);

drop table public.history_part;
CREATE TABLE IF NOT EXISTS public.history_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       double precision DEFAULT '0.0000'           NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
	PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE INDEX history_clock_idx1
ON public.history_part (clock DESC);

drop table public.history_uint_part;
CREATE TABLE IF NOT EXISTS public.history_uint_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       numeric(20)      DEFAULT '0'                 NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);
CREATE INDEX history_uint_clock_idx1
ON public.history_uint_part (clock DESC);

drop table public.history_log_part;
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

CREATE INDEX history_log_part_idx1
ON public.history_log_part (clock DESC);

drop table public.history_str_part;
CREATE TABLE IF NOT EXISTS public.history_str_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       varchar(255)     DEFAULT ''                  NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE INDEX history_str_part_idx1
ON public.history_str_part (clock DESC);

drop table public.history_text_part;
CREATE TABLE IF NOT EXISTS public.history_text_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       text             DEFAULT ''                  NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE INDEX history_text_part_idx1
ON public.history_text_part (clock DESC);

drop table public.history_bin_part;
CREATE TABLE IF NOT EXISTS public.history_bin_part (
    itemid      bigint                                       NOT NULL,
    clock       integer          DEFAULT '0'                 NOT NULL,
    value       bytea                                        NOT NULL,
    ns          integer          DEFAULT '0'                 NOT NULL,
    PRIMARY KEY (itemid, clock, ns)
) PARTITION BY RANGE (clock);

CREATE INDEX history_bin_part_idx1
ON public.history_bin_part (clock DESC);

drop table public.auditlog_part;
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

CREATE INDEX auditlog_part_1 ON public.auditlog_part (userid, clock);
CREATE INDEX auditlog_part_2 ON public.auditlog_part (clock);
CREATE INDEX auditlog_part_3 ON public.auditlog_part (resourcetype, resourceid);
CREATE INDEX auditlog_part_4 ON public.auditlog_part (recordsetid);
CREATE INDEX auditlog_part_5 ON public.auditlog_part (ip);


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

