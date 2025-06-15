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
/*********************************************************************************************************/


/*** create table ****/
create table cbar_currency_rates (
    rate_date date,
    valtype varchar2(100),
    code varchar2(20),
    nominal varchar2(100),
    name varchar2(100),
    value number(20,4)
);
drop table cbar_currency_rates;
truncate table cbar_currency_rates;
/*************************************************************************/



/***** create procedure ************************/
create or replace procedure cbar_upsert(message out varchar2)
is
begin
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
    commit;
    message:='Emeliyyat icra olundu!!!';
exception
    when others then
    begin
        rollback;
        message:='Xeta bas verdi: '|| sqlerrm;
    end;
end;


/********* Main Block ********/
declare
    message varchar2(50);
begin
    cbar_upsert(message);
    dbms_output.put_line(message);
end;


-- check procedure:
update cbar_currency_rates
set value=3 where code='USD';
commit;



/*
    Oracle Wallet ile bagli problem oldugu ucun python proxy server istifade etdim
*/
from flask import Flask, Response
import requests

app = Flask(__name__)

@app.route("/cbar.xml")
def proxy():
    url = "https://www.cbar.az/currencies/13.06.2025.xml"
    r = requests.get(url)
    xml_text = r.text

    '''
    print("----------- XML TEXT -----------")
    print(xml_text)
    print("----------- END OF XML -----------")
    '''
    #if not xml_text.startswith('<?xml'):
        #xml_text = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_text

    return Response(
        xml_text,
        status=r.status_code,
        mimetype="application/xml",
        #content_type='application/xml; charset=UTF-8'
    )

app.run(host='localhost', port=5000)















