-- Must be run as SYS after APEX installation.
whenever sqlerror exit sql.sqlcode

define workspace_name = '&1'
define schema_name = '&2'
define workspace_pass = '&3'

declare
  l_count number;
begin
  select count(*)
    into l_count
    from sys.dba_users
   where username = upper('&schema_name');

  if l_count = 0 then
    execute immediate 'create user ' || dbms_assert.simple_sql_name(upper('&schema_name')) ||
      ' identified by "' || replace('&workspace_pass', '"', '""') || '" quota unlimited on users';
  else
    execute immediate 'alter user ' || dbms_assert.simple_sql_name(upper('&schema_name')) ||
      ' identified by "' || replace('&workspace_pass', '"', '""') || '" account unlock';
    execute immediate 'alter user ' || dbms_assert.simple_sql_name(upper('&schema_name')) ||
      ' quota unlimited on users';
  end if;
end;
/

grant create session, resource, create view, create procedure, create sequence, create trigger to &schema_name;

declare
  l_workspace_id number;
begin
  begin
    select workspace_id
      into l_workspace_id
      from apex_workspaces
     where workspace = upper('&workspace_name');
  exception
    when no_data_found then
      l_workspace_id := null;
  end;

  if l_workspace_id is null then
    apex_instance_admin.add_workspace(
      p_workspace => upper('&workspace_name'),
      p_primary_schema => upper('&schema_name'));
    commit;
  end if;
end;
/

declare
  l_workspace_id number;
begin
  select workspace_id
    into l_workspace_id
    from apex_workspaces
   where workspace = upper('&workspace_name');

  apex_util.set_security_group_id(l_workspace_id);

  begin
    apex_util.remove_user(p_user_name => lower('&schema_name'));
  exception
    when others then
      null;
  end;

  apex_util.create_user(
    p_user_name => lower('&schema_name'),
    p_email_address => lower('&schema_name') || '@example.com',
    p_web_password => '&workspace_pass',
    p_default_schema => upper('&schema_name'),
    p_allow_access_to_schemas => upper('&schema_name'),
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N');

  apex_util.set_security_group_id(null);
  commit;
end;
/

exit
