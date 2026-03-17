

Execuriton order:

1. Run zabbix_prepare.sql  -- creates helper functions, partitioned tables, initial partations
2. Stop Zabbix writing processes  
3. Run zabbix_migrate.sql  -- copies data from TimescaleDB to partitioned tables
4. Run zabbix_validate.sql -- compares number of records in original and partitoned tables; gives overview about all partitioned tables and their subtables
5. zabbix_finalize.sql -- prepares partition rotation procedures for renamed tables; renames *_part tables to original names used by Zabbex
6. Start Zabbix writing processes 

Script to execute daily to rotate partitions (execute per cron job)

export PGUSER=postgres
export PGPASSWORD=<password>
export HOST=localhost
manage_zabbix_partitions.sh

Adjust variables in manage_zabbix_partitions.sh accordingly to your retention policy.
