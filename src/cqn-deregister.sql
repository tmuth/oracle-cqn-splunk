--SELECT REGID, TABLE_NAME FROM USER_CHANGE_NOTIFICATION_REGS;


declare
  l_regid number;
begin
  for c1 in (SELECT regid FROM USER_CHANGE_NOTIFICATION_REGS where table_name = 'SOE.CUSTOMERS')
  loop
    l_regid := c1.regid;
    DBMS_CQ_NOTIFICATION.DEREGISTER(l_regid);
  end loop; --c1
end;
/
