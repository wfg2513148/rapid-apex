-- Example call:
-- $ORACLE_HOME/bin/sqlplus sys/oracle@localhost/XEPDB1 as sysdba @apex-install.sql Welc0me@1

-- Must be run as SYS
whenever sqlerror exit sql.sqlcode

-- Parameters: If using to create another user later on, just modify this section
define admin_name = '&1'
define admin_pass = '&2'
define admin_email = '&3'

-- Validate parameters
declare
begin
  if '&admin_name' is null then
    raise_application_error(-20001, 'Param 1: admin_name missing');
  end if;

  if '&admin_pass' is null then
    raise_application_error(-20001, 'Param 2: admin_pass missing');
  end if;

  if '&admin_email' is null then
    raise_application_error(-20001, 'Param 3: admin_email missing');
  end if;
end;
/

-- From Joels blog: http://joelkallman.blogspot.ca/2017/05/apex-and-ords-up-and-running-in2-steps.html
declare
  l_acl_path varchar2(4000);
  l_apex_schema varchar2(100);
begin

  for c1 in (
    select schema
    from sys.dba_registry
    where comp_id = 'APEX') loop
      l_apex_schema := c1.schema;
  end loop;
  
  sys.dbms_network_acl_admin.append_host_ace(
    host => '*',
    ace => xs$ace_type(privilege_list => xs$name_list('connect'),
    principal_name => l_apex_schema,
    principal_type => xs_acl.ptype_db));
  commit;
end;
/


-- Setup APEX Admin password
begin
  apex_util.set_security_group_id( 10 );
  apex_util.create_user(
    p_user_name => '&admin_name',
    p_email_address => '&admin_email',
    p_web_password => '&admin_pass',
    p_developer_privs => 'ADMIN',
    p_change_password_on_first_use => 'N');
  apex_util.set_security_group_id( null );
  commit;
end;
/

-- Unlimit account password expire time
alter profile DEFAULT limit PASSWORD_REUSE_TIME unlimited;
alter profile DEFAULT limit PASSWORD_LIFE_TIME  unlimited;

-- Required for ORDS install
alter user apex_public_user identified by oracle account unlock;
/

-- Exit SQL
exit