@Functions.sql;

/***** create procedure cbar_upsert for upsert ************************/
create or replace procedure cbar_upsert(message out varchar2)
is
begin
    log_to_all(
        p_message=>'procedure is starting...',
        p_proc=>'cbar_upsert procedure',
        p_level=>'DEBUG',
        p_level_msg=>'information is inserted'
    );
    -- Merge(insert or update):
    merge into cbar_currency_rates cbar_table
    using (
        select
            to_date(z.date_cbar, 'dd.mm.yyyy') as date_cbar,
            y.type_cbar as type_cbar,
            x.code as code,
            x.nominal as nominal,
            x.name as name_cbar,
            x.value as value_cbar
        from xmltable(
            '/ValCurs'
            passing xmltype(convert_blob_to_clob('http://localhost:5000/cbar.xml')) columns
                date_cbar varchar2(100) path '@Date',
                type_cbar xmltype path 'ValType'
        ) z, xmltable(
            '/ValType'
            passing z.type_cbar columns
                type_cbar varchar2(30) path '@Type',
                valutes xmltype path 'Valute'

        ) y, xmltable(
            '/Valute'
            passing y.valutes columns
                code     varchar2(10)  path '@Code',
                nominal  varchar2(10)  path 'Nominal',
                name     varchar2(100) path 'Name',
                value    number        path 'Value'
        ) x
    ) cbar_xml
    on (cbar_table.code = cbar_xml.code and cbar_table.rate_date = cbar_xml.date_cbar)
    when matched then
        update set value = cbar_xml.value_cbar
    when not matched then
        insert (rate_date, valtype, code, nominal, name, value)
        values (
            cbar_xml.date_cbar, cbar_xml.type_cbar, cbar_xml.code, cbar_xml.nominal, cbar_xml.name_cbar, cbar_xml.value_cbar
        );
    message:='Emeliyyat icra olundu!!!';
    log_to_all(
        p_message=>'procedure ended...',
        p_proc=>'cbar_upsert procedure',
        p_level=>'INFO',
        p_level_msg=>'information was inserted'
    );
exception
    when others then
        begin
            rollback;
            log_to_all(
                p_message=>'procedure is stopping...',
                p_proc=>'cbar_upsert procedure',
                p_level=>'ERROR',
                p_level_msg=>sqlerrm
            );
        end;
end;



/***** create procedure log_to_file for log file *****************/
create or replace procedure log_to_file(
    p_message  varchar2 default null,
    p_level  varchar2 default 'INFO',
    p_level_msg varchar2 default null,
    p_proc varchar2 default 'UNKNOWN'
) 
is
    write_file utl_file.file_type;
    log_text_line varchar2(600);
begin
    if p_level='ERROR' then
        log_text_line:='['||to_char(sysdate, 'dd-mm-yyyy hh24:mi:ss')||'] ['
            ||p_level||'] ['||p_level_msg||'] ['||p_proc||'] '||p_message;
    else
        log_text_line:='['||to_char(sysdate, 'dd-mm-yyyy hh24:mi:ss')||'] ['
            ||p_level||'] ['||p_level_msg||'] ['||p_proc||'] '||p_message;
    end if;
    write_file:=utl_file.fopen(
        location  => 'DBMS_DIR',
        filename  => 'cbar_log.txt',
        open_mode  => 'a',
        max_linesize  => null
    );
    utl_file.put_line(
        file  => write_file,
        buffer  => log_text_line
    );
    utl_file.fclose(write_file);
exception
    when no_data_found or utl_file.invalid_path then
        begin
            write_file:=utl_file.fopen(
                location  => 'DBMS_DIR',
                filename  => 'cbar_log.txt',
                open_mode  => 'w',
                max_linesize  => null
            );
            utl_file.put_line(
                file  => write_file,
                buffer  => log_text_line
            );
            utl_file.fclose(write_file);
        end;
    when others then
        dbms_output.put_line('loga yaza bilmedi');
end;



/***** create procedure log_to_table for log table *****************/
create or replace procedure log_to_table(
    p_message  varchar2 default null,
    p_level  varchar2 default 'INFO',
    p_level_msg varchar2 default null,
    p_proc varchar2 default 'UNKNOWN'
)is
    pragma autonomous_transaction;
begin
    insert into cbar_logs(log_level, procedure_nm, message, error_detail)
    values(p_level, p_proc, p_message, p_level_msg);
    commit;
end;



/***** create procedure log_to_all for all log *****************/
create or replace procedure log_to_all(
    p_message  varchar2 default null,
    p_level  varchar2 default 'INFO',
    p_level_msg varchar2 default null,
    p_proc varchar2 default 'UNKNOWN'
)is
begin
    log_to_table(
        p_message=>log_to_all.p_message,
        p_level=>log_to_all.p_level,
        p_level_msg=>log_to_all.p_level_msg,
        p_proc=>log_to_all.p_proc
    );

    log_to_file(
        p_message=>log_to_all.p_message,
        p_level=>log_to_all.p_level,
        p_level_msg=>log_to_all.p_level_msg,
        p_proc=>log_to_all.p_proc
    );
end;



