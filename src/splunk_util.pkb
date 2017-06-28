create or replace package body splunk_util as

  procedure change_callback(ntfnds in cq_notification$_descriptor) as
  regid          NUMBER;
  tbname         VARCHAR2(60);
  event_type     NUMBER;
  numtables      NUMBER;
  operation_type NUMBER;
  operation_type_desc varchar2(100);
  numrows        NUMBER;
  row_id         VARCHAR2(2000);
  numqueries     NUMBER;
  qid            NUMBER;
  qop            NUMBER;
BEGIN
  regid      := ntfnds.registration_id;
  event_type := ntfnds.event_type;
  INSERT INTO cqn_events VALUES
    (regid, event_type);
  numqueries    :=0;
  IF (event_type = DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    numqueries  := ntfnds.query_desc_array.count;
    FOR i IN 1..numqueries
    LOOP
      qid := ntfnds.query_desc_array(i).queryid;
      qop := ntfnds.query_desc_array(i).queryop;
      INSERT INTO cqn_queries VALUES
        (qid, qop);
      numtables := 0;
      numtables := ntfnds.query_desc_array(i).table_desc_array.count;
      FOR j IN 1..numtables
      LOOP
        tbname := ntfnds.query_desc_array(i).table_desc_array(j).table_name;
        operation_type := ntfnds.query_desc_array(i).table_desc_array(j).Opflags;

        operation_type_desc := CASE operation_type
                 WHEN 2 THEN 'INSERT'
                 WHEN 4 THEN 'UPDATE'
                 WHEN 8 THEN 'DELETE'
                 WHEN 16 THEN 'ALTER'
                 WHEN 32 THEN 'DROP'
                 WHEN 64 THEN 'UNKNOWN'
                 ELSE 'Unknown'
               END;


        IF (bitand(operation_type, DBMS_CQ_NOTIFICATION.ALL_ROWS) = 0) THEN
          numrows := ntfnds.query_desc_array(i).table_desc_array(j).numrows;
        ELSE
          numrows :=0; -- ROWID info not available
        END IF;

        INSERT INTO cqn_table_changes VALUES
          (qid, tbname, operation_type, operation_type_desc, numrows);

        /* Body of loop does not execute when numrows is zero */
        FOR k IN 1..numrows
        LOOP
          Row_id := ntfnds.query_desc_array(i).table_desc_array(j).row_desc_array(k).row_id;
          INSERT INTO cqn_row_changes VALUES
            (qid, tbname, Row_id, operation_type_desc);
        END LOOP; -- loop over rows (k)
      END LOOP;   -- loop over tables (j)
    END LOOP;     -- loop over queries (i)
  END IF;
  COMMIT;
  end change_callback;


  function convert_row_json( p_table_name in varchar2,
                              p_rowid in VARCHAR2)
  return clob
  is
  begin
    null;
    /*
    select regexp_replace(xml3,'(.+),.+$','{\1}',1,1,'n') xml4 from (
      select regexp_replace(xml2,'<(\w+)>(.+)</\1>','"\1" : "\2",',1,0,'n') xml3 from (
      select regexp_replace(xml,'(^.+<ROW>)(.*)(</ROW>.*)','\2',1,1,'n') xml2 from (
      SELECT dbms_xmlgen.getXML('SELECT * from soe.customers where rownum=1') xml
      FROM dual
      )
      )
      );

    */
  end convert_row_json;


  procedure save_row( p_table_name in varchar2,
                      p_rowid in varchar2) as
  begin
    -- TODO: Implementation required for procedure SPLUNK_UTIL.save_row
    null;
  end save_row;

  procedure push_event(p_event_id in number,
                       p_remove_pushed in boolean default false) as
  begin
    -- TODO: Implementation required for procedure SPLUNK_UTIL.push_event
    null;
  end push_event;

end splunk_util;
/
show errors
