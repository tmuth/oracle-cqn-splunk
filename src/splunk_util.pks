create or replace package splunk_util as

  /* TODO enter package declarations (types, exceptions, methods etc) here */

  procedure change_callback(ntfnds IN CQ_NOTIFICATION$_DESCRIPTOR);

  function convert_row_json( p_table_name in varchar2,
                              p_rowid in VARCHAR2)
  return clob;

  procedure save_row( p_table_name in varchar2,
                      p_rowid in VARCHAR2);

  procedure push_event(p_event_id in number default null,
                       p_event_clob in clob,
                       p_event_operation in varchar2,
                       p_remove_pushed in boolean default false);



end splunk_util;
/
show errors
