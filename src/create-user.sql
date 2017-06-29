-- USER SQL
CREATE USER cqn IDENTIFIED BY welcome1
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- QUOTAS
ALTER USER cqn QUOTA UNLIMITED ON USERS;

-- ROLES
GRANT "CONNECT" TO cqn ;
GRANT "RESOURCE" TO cqn ;

-- SYSTEM PRIVILEGES

grant execute on DBMS_CQ_NOTIFICATION to cqn;
GRANT CHANGE NOTIFICATION TO cqn;

-- for logger:
grant connect,create view, create job, create table, create sequence, create trigger, create procedure, create any context to cqn;

grant select on soe.customers to cqn;
