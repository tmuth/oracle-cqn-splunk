REM Create a table to record notification events.
CREATE TABLE cqn_events
  (
    time_stamp      timestamp(6),
    regid      NUMBER,
    event_type NUMBER
  );

REM Create a table to record notification queries.
CREATE TABLE cqn_queries
  (
    time_stamp      timestamp(6),
    qid NUMBER,
    qop NUMBER
  );

REM Create a table to record changes to registered tables.
CREATE TABLE cqn_table_changes
  (
    time_stamp      timestamp(6),
    qid             NUMBER,
    table_name      VARCHAR2(100),
    table_operation NUMBER,
    table_op_desc   varchar2(100),
    numrows         number
  );
REM Create a table to record ROWIDs of changed rows.
CREATE TABLE cqn_row_changes
  (
    time_stamp      timestamp(6),
    qid        NUMBER,
    table_name VARCHAR2(100),
    row_id     VARCHAR2(2000),
    table_op_desc   varchar2(100)
  );
