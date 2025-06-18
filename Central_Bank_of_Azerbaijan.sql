@Procedures.sql;
/********* Main Block ********/
set serveroutput on;
declare
    message varchar2(50);
begin
    log_to_all(
        p_message=>'main blocks are starting...',
        p_proc=>'main blocks',
        p_level=>'DEBUG'
    );
    cbar_upsert(message);
    commit;
    log_to_all(
        p_message=>'main blocks ended...',
        p_proc=>'main blocks',
        p_level=>'INFO'
    );
    dbms_output.put_line(message);
exception
    when others then rollback;
end;


-- check procedure:
/*
update cbar_currency_rates
set value=3 where code='USD';
commit;
*/
