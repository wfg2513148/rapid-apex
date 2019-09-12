-- Example call:
-- $ORACLE_HOME/bin/sqlplus sys/oracle@localhost/XEPDB1 as sysdba @apex-install.sql Welc0me@1
--
-- Takes in 2 parameters:
-- 1: admin_email ex: wfgdlut@gmail.com
-- 2: admin_pass ex: Welc0me@1

-- Must be run as SYS
whenever sqlerror exit sql.sqlcode

-- Parameters: If using to create another user later on, just modify this section
define admin_email = '&1'
define admin_pass = '&2'

-- Validate parameters
declare
begin
  if '&admin_email' is null then
    raise_application_error(-20001, 'Param 1: admin_email missing');
  end if;

  if '&admin_pass' is null then
    raise_application_error(-20001, 'Param 2: admin_pass missing');
  end if;

end;
/

-- Install APEX
@apexins.sql SYSAUX SYSAUX TEMP /i/

-- APEX REST configuration
-- In APEX 18.2 they're 3 parameters for this file
@apex_rest_config_core.sql @ oracle oracle

-- Required for ORDS install
alter user apex_public_user identified by oracle account unlock;


-- Exit SQL
exit