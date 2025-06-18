/*** create table cbar_currency_rates ****/
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


/*** create table cbar_logs ****/
create table cbar_logs (
    log_id       number generated always as identity primary key,
    log_time     date default sysdate,
    log_level    varchar2(10),
    procedure_nm varchar2(100),
    message      varchar2(4000),
    error_detail varchar2(4000),
    created_by   varchar2(50) default user
);
drop table cbar_logs;
truncate table cbar_logs;