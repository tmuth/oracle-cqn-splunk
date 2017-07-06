declare
  l_row_json     clob;
  l_table_name varchar2(100) := 'SOE.CUSTOMERS';
begin
  for c1 in (select rowid from SOE.CUSTOMERS where rownum <=1000)
  loop
    l_row_json := splunk_util.convert_row_json(p_table_name => l_table_name, p_rowid=> c1.rowid);

            splunk_util.push_event(
                p_event_clob      => l_row_json,
                p_event_operation => 'test',
                p_table_name      => l_table_name,
                p_row_id          => c1.rowid);

    -- dbms_output.put_line(l_row_json);
   -- l_row_json := replace(l_row_json,'<?xml version="1.0"?>');
   --  dbms_output.put_line(l_row_json);
   --LOGGER.LOG_CHARACTER_CODES(l_row_json);
  end loop; --c1
end;
/
