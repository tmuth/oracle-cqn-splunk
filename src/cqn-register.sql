DECLARE
  reginfo CQ_NOTIFICATION$_REG_INFO;
  mgr_id  NUMBER;
  dept_id NUMBER;
  v_cursor SYS_REFCURSOR;
  regid NUMBER;
BEGIN
  /* Register two queries for QRNC: */
  /* 1. Construct registration information. chnf_callback is name of notification handler. QOS_QUERY specifies result-set-change notifications. */
  reginfo := cq_notification$_reg_info ( 'SPLUNK_UTIL.change_callback', DBMS_CQ_NOTIFICATION.QOS_BEST_EFFORT+ DBMS_CQ_NOTIFICATION.QOS_ROWIDS + DBMS_CQ_NOTIFICATION.QOS_QUERY, 0, 0, 0 );
  /* 2. Create registration. */
  regid := DBMS_CQ_NOTIFICATION.new_reg_start(reginfo);
  /*
  OPEN v_cursor FOR SELECT dbms_cq_notification.CQ_NOTIFICATION_QUERYID, manager_id FROM HR.EMPLOYEES WHERE employee_id = 7902;
  CLOSE v_cursor;
  OPEN v_cursor FOR SELECT dbms_cq_notification.CQ_NOTIFICATION_QUERYID, department_id FROM HR.departments WHERE department_name = 'IT';
  CLOSE v_cursor;
  */

  OPEN v_cursor FOR SELECT dbms_cq_notification.CQ_NOTIFICATION_QUERYID,CUSTOMER_ID,
  CUST_FIRST_NAME,
  CUST_LAST_NAME
  from soe.customers c;
  CLOSE v_cursor;

  DBMS_CQ_NOTIFICATION.REG_END;
END;
/
