#!/usr/bin/env bash

# This script rolls partitions for postgresql tables for Zabbix
#
#    Example usage:
#      export PGUSER=zabbix
#      export PGPASSWORD='secret'
#      export DEBUG=1
#      ./manage_zabbix_partitions.sh
#
#    Optional environemnt variables:
#      DB=zabbix
#      HOST=127.0.0.1
#      PORT=5432
#      RETENTION_HISTORY_DAYS=60
#      RETENTION_TRENDS_DAYS=548
#      CREATE_AHEAD_DAYS=14
#

set -euo pipefail

# PostgreSQL connection settings
PSQL="${PSQL:-psql}"
DB="${DB:-zabbix}"
HOST="${HOST:-}"
PORT="${PORT:-}"
DEBUG="${DEBUG:-0}"

# postgresl authentication:
# export PGUSER=...
# export PGPASSWORD=...
USER_OPT="${PGUSER:+-U $PGUSER}"
HOST_OPT="${HOST:+-h $HOST}"
PORT_OPT="${PORT:+-p $PORT}"

# retention defaults
RETENTION_HISTORY_DAYS="${RETENTION_HISTORY_DAYS:-60}"
RETENTION_TRENDS_DAYS="${RETENTION_TRENDS_DAYS:-548}"

# how many days ahead to pre-create partitions
CREATE_AHEAD_DAYS="${CREATE_AHEAD_DAYS:-14}"

# postregres command line
PSQL_CMD=("$PSQL" $HOST_OPT $PORT_OPT $USER_OPT -d "$DB" -v ON_ERROR_STOP=1 -X)

if [ "$DEBUG" == "1" ]; then

  echo "==> Runnging in DEBUG mode, nothing will be changed"

  run_sql() {
    echo "${PSQL_CMD[@]} -c $1"
  }

else

  run_sql() {
    "${PSQL_CMD[@]}" -c "$1"
  }
fi

TODAY_UTC="$(date -u +%F)"
HISTORY_KEEP_FROM="$(date -u -d "$TODAY_UTC - ${RETENTION_HISTORY_DAYS} days" +%F)"
TRENDS_KEEP_FROM="$(date -u -d "$TODAY_UTC - ${RETENTION_TRENDS_DAYS} days" +%F)"

HISTORY_AHEAD_TO="$(date -u -d "$TODAY_UTC + ${CREATE_AHEAD_DAYS} days" +%F)"
MONTHLY_AHEAD_TO="$(date -u -d "$TODAY_UTC + ${CREATE_AHEAD_DAYS} days" +%F)"

history_tables=(
  history
  history_uint
  history_log
  history_str
  history_text
  #history_bin
)

monthly_tables=(
  trends
  trends_uint
  auditlog
)

echo "==> UTC today:                 $TODAY_UTC"
echo "==> Keep history from:         $HISTORY_KEEP_FROM"
echo "==> Keep trends from:          $TRENDS_KEEP_FROM"
echo "==> Create partitions ahead to $HISTORY_AHEAD_TO"

echo "==> Creating daily partitions ahead"
for t in "${history_tables[@]}"; do
  run_sql "SET TIME ZONE 'UTC'; SELECT public.ensure_daily_partitions('$t', DATE '$TODAY_UTC', DATE '$HISTORY_AHEAD_TO');"
done

echo "==> Creating monthly partitions ahead"
for t in "${monthly_tables[@]}"; do
  run_sql "SET TIME ZONE 'UTC'; SELECT public.ensure_monthly_partitions('$t', DATE '$TODAY_UTC', DATE '$MONTHLY_AHEAD_TO');"
done

echo "==> Dropping expired daily partitions"
for t in "${history_tables[@]}"; do
  run_sql "SET TIME ZONE 'UTC'; SELECT public.drop_daily_partitions_older_than('$t', DATE '$HISTORY_KEEP_FROM');"
done

echo "==> Dropping expired monthly partitions"
for t in "${monthly_tables[@]}"; do
  run_sql "SET TIME ZONE 'UTC'; SELECT public.drop_monthly_partitions_older_than('$t', DATE '$TRENDS_KEEP_FROM');"
done

echo "==> Done"

