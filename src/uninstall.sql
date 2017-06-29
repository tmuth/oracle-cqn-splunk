
drop package splunk_util;

drop table cqn_events;
drop table cqn_queries;
drop table cqn_table_changes;
drop table cqn_row_changes;

@../logger/drop_logger.sql
