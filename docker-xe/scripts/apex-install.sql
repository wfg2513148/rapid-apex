-- Must be run as SYS
whenever sqlerror exit sql.sqlcode


-- Install APEX
@apexins.sql SYSAUX SYSAUX TEMP /i/

-- APEX REST configuration
-- In APEX 18.2 they're 3 parameters for this file
@apex_rest_config_core.sql @ oracle oracle




-- Exit SQL
exit
