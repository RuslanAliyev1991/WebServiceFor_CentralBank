/**** Create ACL ****/
begin
    DBMS_NETWORK_ACL_ADMIN.create_acl(
      acl         => 'allow_cbar_access.xml',
      description => 'Allow web access for XML HTTP calls',
      principal   => 'SCOTT',
      is_grant    => TRUE,
      privilege   => 'connect',
      start_date => null,
      end_date => null
    );
    
    DBMS_NETWORK_ACL_ADMIN.assign_acl(
        acl  => 'allow_cbar_access.xml',
        host => 'www.cbar.az'
    );
    commit;
end;
------------------------------------------------------------------------

-- check acl:
select
    httpuritype('http://localhost:5000/cbar.xml').getblob() as response
from dual;

select
    httpuritype('http://localhost:5000/cbar.xml').getclob() as response
from dual;
/**************************************************************************************************/




/****** Create convert (from blob to clob) function *******/
create or replace function convert_blob_to_clob(url varchar2)
return clob
is
    l_blob blob;
    l_clob clob;
    l_dest_offset pls_integer := 1;
    l_src_offset pls_integer := 1;
    l_lang_ctx pls_integer := dbms_lob.default_lang_ctx;
    l_warning pls_integer;
begin
    l_blob := httpuritype(url).getblob();
    -- create empty object for clob:
    dbms_lob.createtemporary(l_clob, true);

    -- BLOB → CLOB converting:
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
    return l_clob;
end;
------------------------------------------------------------------------

-- check function:
select convert_blob_to_clob('http://localhost:5000/cbar.xml') from dual;

select extract(value(x), '/Valute/Name/text()').getstringval() as name_val
from table(
    xmlsequence(
        xmltype(convert_blob_to_clob('http://localhost:5000/cbar.xml')).extract('/ValCurs/ValType/Valute')
    )
) x;
/*************************************************************************************************************/


-- fetch xml data from cbar:
set serveroutput on;
declare
    request utl_http.req;
    response utl_http.resp;
    buffer varchar2(1000);
    c_buffer varchar2(2000);
    converted varchar2(35);
begin
    request:=utl_http.begin_request(
        url  => 'http://localhost:5000/cbar.xml',
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
    
    /*utl_http.set_header(
        r     => request,
        name  => 'Content-Type',
        value => 'application/xml; charset=UTF-8'
    ); */
    
    response:=utl_http.get_response(request);
    begin
        loop
            utl_http.read_text(
                r  => response,
                data  => buffer,
                len  => 1000
            );
            c_buffer:=convert(buffer, 'AL32UTF8', 'UTF8');
            dbms_output.put_line(c_buffer);
        end loop;
    exception
        when utl_http.end_of_body or no_data_found
            then dbms_output.put_line('End Of File!!!');
    end;

    /* converted:=convert('abş dolları', 'UTF8', 'AL32UTF8');
    dbms_output.put_line(converted);*/

    utl_http.end_response(r  => response);
end;


















