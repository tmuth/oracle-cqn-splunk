create or replace package body splunk_util as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';

  function timestamp_to_epoch(p_timestamp in timestamp)
  return number
  as
    l_unix_epoch number;
  begin
    --l_unix_epoch := ( p_timestamp - to_timestamp('1970-01-01','YYYY-MM-DD' )) * 60 * 60 * 24;
    l_unix_epoch := extract(day from(sys_extract_utc(p_timestamp) - to_timestamp('1970-01-01', 'YYYY-MM-DD'))) * 86400000
            + to_number(to_char(sys_extract_utc(p_timestamp), 'SSSSSFF3'));
    return l_unix_epoch;
  end timestamp_to_epoch;

  procedure change_callback(ntfnds in cq_notification$_descriptor)
  as
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
    l_row_json     clob;
    l_scope logger_logs.scope%type := gc_scope_prefix || 'change_callback';
BEGIN
  regid      := ntfnds.registration_id;
  event_type := ntfnds.event_type;
  INSERT INTO cqn_events VALUES
    (systimestamp,regid, event_type);
  numqueries    :=0;
  IF (event_type = DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    numqueries  := ntfnds.query_desc_array.count;
    FOR i IN 1..numqueries
    LOOP
      qid := ntfnds.query_desc_array(i).queryid;
      qop := ntfnds.query_desc_array(i).queryop;
      INSERT INTO cqn_queries VALUES
        (systimestamp,qid, qop);
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
          (systimestamp,qid, tbname, operation_type, operation_type_desc, numrows);

        -- Body of loop does not execute when numrows is zero
        FOR k IN 1..numrows
        LOOP
          Row_id := ntfnds.query_desc_array(i).table_desc_array(j).row_desc_array(k).row_id;
          INSERT INTO cqn_row_changes VALUES
            (systimestamp,qid, tbname, Row_id, operation_type_desc);

            l_row_json := convert_row_json(p_table_name => tbname, p_rowid=> Row_id);
            push_event(
                p_event_clob      => l_row_json,
                p_event_operation => operation_type_desc,
                p_table_name      => tbname,
                p_row_id          => Row_id);


            /*
            for c1 in (select customer_id from soe.customers where rowid = row_id)
            loop
              logger.log('customer_id:' || c1.customer_id||', rowid: '|| row_id,l_scope);
            end loop; --c1
            */

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
    l_out         clob;
    qrycontext   DBMS_XMLGEN.ctxHandle;
  begin
    qrycontext := DBMS_XMLGEN.newcontext('select * from '||p_table_name||' where rowid = :1 ');
    DBMS_XMLGEN.setbindvalue (qrycontext, '1', p_rowid);
   -- dbms_xmlgen.setRowTag(qrycontext,NULL);
    dbms_xmlgen.setRowSetTag(qrycontext,NULL);
    l_out := DBMS_XMLGEN.getxml (qrycontext);
    dbms_xmlgen.closecontext(qrycontext);
/*
    l_out := replace(l_out,'<?xml version="1.0"?>');
    l_out := replace(l_out,'<ROW>');
    l_out := replace(l_out,'</ROW>');
    l_out := ltrim(l_out,chr(10)||chr(32));
    l_out := rtrim(l_out,chr(10)||chr(32));
    -- remove the trailing XML tag from each column
    l_out := regexp_replace(l_out,'<(\w+)>(.+)</\1>','"\1" : "\2",',1,0,'n');
    l_out := rtrim(l_out,',');
*/

    -- remove header and row XML
    l_out := regexp_replace(l_out,'(^.+<ROW>)(.*)(</ROW>.*)','\2',1,1,'n');
    -- remove the trailing XML tag from each column
    l_out := regexp_replace(l_out,'<(\w+)>(.+)</\1>','"\1" : "\2",',1,0,'n');
    -- turn the XML tags into JSON attribute names
    l_out := regexp_replace(l_out,'(.+),.+$','\1',1,1,'n');

    return l_out;
  end convert_row_json;


  procedure save_row( p_table_name in varchar2,
                      p_rowid in varchar2) as
  begin
    -- TODO: Implementation required for procedure SPLUNK_UTIL.save_row
    null;
  end save_row;

  procedure push_event(p_event_id in number default null,
                       p_event_clob in clob,
                       p_event_operation in varchar2,
                       p_table_name in varchar2,
                       p_row_id     in varchar2,
                       p_event_timestamp in timestamp default systimestamp,
                       p_remove_pushed in boolean default false)
  as
    l_splunk_hec_token varchar2(64) := 'FCF35C06-9428-430C-BDBC-E26E901ECBA9';
    l_splunk_host varchar2(100)  := '192.168.56.1';
    l_splunk_port number         := 8088;
    l_splunk_ssl   boolean       := false;

    l_http_prefix varchar2(10)   := 'http';
    l_url         varchar2(255);

    l_body CLOB;
    l_result CLOB;
    l_db_host varchar2(200);
    l_unix_epoch number;

    l_scope logger_logs.scope%type := gc_scope_prefix || 'push_event';
  begin

    l_db_host :=  sys_context('USERENV','SERVER_HOST')||'.'||sys_context('USERENV','DB_NAME');
    l_unix_epoch := timestamp_to_epoch(p_event_timestamp);

    apex_web_service.g_request_headers(1).name := 'Authorization';
    apex_web_service.g_request_headers(1).value := 'Splunk '||l_splunk_hec_token;

                 l_body := '{ "time": '||l_unix_epoch || ','||
                            ' "host": "' || l_db_host  || '",'||
                            ' "source": "' || p_table_name || '",'||
                            ' "event": '||
                            --'{ "event_id" : '||p_event_id||' }'||
                            '{"@cqn_operation": "'|| p_event_operation||'", '||
                            '"@cqn_rowid": "'|| p_row_id||'", '||
                            p_event_clob ||
                            '}}';
    -- logger.log('l_body:' || l_body,l_scope);

    if l_splunk_ssl then
      l_http_prefix := 'https';
    end if;

    l_url := l_http_prefix ||'://'||l_splunk_host||':'||l_splunk_port||
      '/services/collector';
     l_result := apex_web_service.make_rest_request(
      p_url            => l_url
     ,p_http_method    => 'POST'
     ,p_body =>  l_body
     );

     -- logger.log('l_result:' || l_result,l_scope);

  end push_event;

end splunk_util;
/
show errors
