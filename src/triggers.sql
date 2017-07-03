create or replace trigger biu_logger_prefs
  before insert or update on logger_prefs
  for each row
begin
  if :new.pref_name not in (
      'SPLUNK_HOST',
      'SPLUNK_HTTP_PREFIX',
      'SPLUNK_PORT',
      'HEC_TOKEN',
      'HEC_ACK',
      'BATCH_EVENTS',
      'BATCH_INTERVAL'
    )
  then
    raise_application_error (-20000, 'Setting system level preferences are restricted to a set list.');
  end if;
end;
/
show errors
