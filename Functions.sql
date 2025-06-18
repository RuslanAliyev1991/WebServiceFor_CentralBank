/****** Create convert (from blob to clob) function *******/
create or replace function convert_blob_to_clob(url varchar2 default null)
return clob
is
    -- clob and blob:
    l_blob blob;
    l_clob clob;
    l_dest_offset pls_integer := 1;
    l_src_offset pls_integer := 1;
    l_lang_ctx pls_integer := dbms_lob.default_lang_ctx;
    l_warning pls_integer;

    -- utl_http:
    request utl_http.req;
    response utl_http.resp;
    buffer_raw raw(1000);
begin
    /* 
        httpuritype ile:
        l_blob := httpuritype(url).getblob(); daha sade ve qisa usul
    */
    log_to_all(
        p_message=>'function is starting...',
        p_proc=>'convert_blob_to_clob function',
        p_level=>'DEBUG',
        p_level_msg=>'GET request is starting...'
    );
    -- utl_http ile:
    request:=utl_http.begin_request(
        url  => convert_blob_to_clob.url,
        method  => 'GET',
        http_version  => 'HTTP/1.1',
        request_context  => null,
        https_host  => null
    );
    utl_http.set_header(
        r  => request,
        name  => 'user-agent',
        value  => 'mozilla/5.0'
    );
    response:=utl_http.get_response(request);
    log_to_all(
        p_message=>'function is executing...',
        p_proc=>'convert_blob_to_clob function',
        p_level=>'DEBUG',
        p_level_msg=>'an xml response was gotten'
    );

    /* gelen cavabi blob-a yaziriq */
    -- create empty object for blob:
    dbms_lob.createtemporary(l_blob, true);
    begin
        loop
            utl_http.read_raw(
                r  => response,
                data  => buffer_raw,
                len  => 1000
            );
            dbms_lob.writeappend(l_blob, utl_raw.length(buffer_raw), buffer_raw);            
        end loop;
        log_to_all(
            p_message=>'function is executing...',
            p_proc=>'convert_blob_to_clob function',
            p_level=>'DEBUG',
            p_level_msg=>'xml data was written to blob'
        );
    exception
        when utl_http.end_of_body or no_data_found
            then dbms_output.put_line('End Of File!!!');
    end;
    utl_http.end_response(r  => response);

    /* BLOB → CLOB converting: */
    -- create empty object for clob:
    dbms_lob.createtemporary(l_clob, true);
    dbms_lob.converttoclob(
        dest_lob     => l_clob,
        src_blob     => l_blob,
        amount       => dbms_lob.lobmaxsize,
        dest_offset  => l_dest_offset,
        src_offset   => l_src_offset,
        blob_csid    => 873, -- UTF8 = 873
        lang_context => l_lang_ctx,
        warning      => l_warning
    );
    log_to_all(
        p_message=>'function ended...',
        p_proc=>'convert_blob_to_clob function',
        p_level=>'INFO',
        p_level_msg=>'xml data was converted to blob'
    );
    return l_clob;
exception
    when utl_http.request_failed then
        begin
            log_to_all(
                p_message=>'function is stopping...',
                p_proc=>'convert_blob_to_clob function',
                p_level=>'ERROR',
                p_level_msg=>sqlerrm
            );
        end;
        return null;
end;




------------------------------------------------------------------------

-- check function:
/*
select convert_blob_to_clob('http://localhost:5000/cbar.xml') from dual;

select extract(value(x), '/Valute/Name/text()').getstringval() as name_val
from table(
    xmlsequence(
        xmltype(convert_blob_to_clob('http://localhost:5000/cbar.xml')).extract('/ValCurs/ValType/Valute')
    )
) x;
*/