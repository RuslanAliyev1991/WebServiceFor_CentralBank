@Procedures.sql;
/********* Main Block ********/
set serveroutput on;
begin
    dbms_scheduler.create_job (
        job_name        => 'job_run_main_block_daily_0910',
        job_type        => 'stored_procedure',
        job_action      => 'main_block_procedure',
        start_date      => trunc(systimestamp) + interval '9' hour + interval '10' minute,
        repeat_interval => 'freq=daily;byhour=9;byminute=10',
        enabled         => true,
        comments        => 'main block hər gün saat 09:10-da avtomatik icra olunur'
    );
end;


/**** main_block_procedure for main blocks *******/
create or replace procedure main_block_procedure
is
begin
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
end;



/*
jobu deaktiv, aktiv etmek hemcinin silmek:
*/
begin
    dbms_scheduler.disable('job_run_main_block_daily_0910');
end;

begin
    dbms_scheduler.enable('job_run_main_block_daily_0910');
end;

begin
    dbms_scheduler.drop_job('job_run_main_block_daily_0910');
end;

select job_name, enabled, state, next_run_date
from dba_scheduler_jobs
where job_name = upper('job_run_main_block_daily_0910');

-- check procedure:
/*
update cbar_currency_rates
set value=3 where code='USD';
commit;
*/
