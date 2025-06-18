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
/*
select
    httpuritype('http://localhost:5000/cbar.xml').getblob() as response
from dual;

select
    httpuritype('http://localhost:5000/cbar.xml').getclob() as response
from dual;
*/