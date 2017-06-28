CREATE OR REPLACE PROCEDURE chnf_callback(
    ntfnds IN CQ_NOTIFICATION$_DESCRIPTOR )
IS
  regid          NUMBER;
  tbname         VARCHAR2(60);
  event_type     NUMBER;
  numtables      NUMBER;
  operation_type NUMBER;
  numrows        NUMBER;
  row_id         VARCHAR2(2000);
  numqueries     NUMBER;
  qid            NUMBER;
  qop            NUMBER;
BEGIN
  regid      := ntfnds.registration_id;
  event_type := ntfnds.event_type;
  INSERT INTO nfevents VALUES
    (regid, event_type);
  numqueries    :=0;
  IF (event_type = DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    numqueries  := ntfnds.query_desc_array.count;
    FOR i IN 1..numqueries
    LOOP
      qid := ntfnds.query_desc_array(i).queryid;
      qop := ntfnds.query_desc_array(i).queryop;
      INSERT INTO nfqueries VALUES
        (qid, qop);
      numtables := 0;
      numtables := ntfnds.query_desc_array(i).table_desc_array.count;
      FOR j IN 1..numtables
      LOOP
        tbname := ntfnds.query_desc_array(i).table_desc_array(j).table_name;
        operation_type := ntfnds.query_desc_array(i).table_desc_array(j).Opflags;
        INSERT INTO nftablechanges VALUES
          (qid, tbname, operation_type);
        IF (bitand(operation_type, DBMS_CQ_NOTIFICATION.ALL_ROWS) = 0) THEN
          numrows := ntfnds.query_desc_array(i).table_desc_array(j).numrows;
        ELSE
          numrows :=0; -- ROWID info not available
        END IF;
        /* Body of loop does not execute when numrows is zero */
        FOR k IN 1..numrows
        LOOP
          Row_id := ntfnds.query_desc_array(i).table_desc_array(j).row_desc_array(k).row_id;
          INSERT INTO nfrowchanges VALUES
            (qid, tbname, Row_id);
        END LOOP; -- loop over rows (k)
      END LOOP;   -- loop over tables (j)
    END LOOP;     -- loop over queries (i)
  END IF;
  COMMIT;
END;
/
