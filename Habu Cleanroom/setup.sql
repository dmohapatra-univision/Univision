
use role accountadmin;
call system$wait(10);

// CREATE WAREHOUSE 
create warehouse if not exists dcr_wh;

/* create role and add permissions required by role for installation of framework */
create role if not exists data_clean_room_role;

/* Setup roles */

use role accountadmin;
call system$wait(10);

// CREATE WAREHOUSE 
create warehouse if not exists dcr_wh;

/* create role and add permissions required by role for installation of framework */
create role if not exists data_clean_room_role_habu;
grant create database on account to role data_clean_room_role_habu;
grant role data_clean_room_role_habu to role sysadmin;
grant usage, operate on warehouse dcr_wh to role data_clean_room_role_habu;

/* Setup provider side objects */
use role data_clean_room_role_habu;
call system$wait(10);

/* cleanup */
drop database if exists dcr_homedepot_dev_provider_db;
/* create provider database and schemas */
create or replace database dcr_homedepot_dev_provider_db;
create or replace schema dcr_homedepot_dev_provider_db.cleanroom;
create or replace schema dcr_homedepot_dev_provider_db.source;

use warehouse dcr_wh;

/* create sample provider data */
create or replace table dcr_homedepot_dev_provider_db.source.customers comment='{"origin":"sf_ps_wls","name":"dcr","version":{"major":6, "minor":2},"attributes":{"component":"dcr"}}' as
select 'user'||seq4()||'_'||uniform(1, 3, random())||'@email.com' as email,
 replace(to_varchar(seq4() % 999, '000') ||'-'||to_varchar(seq4() % 888, '000')||'-'||to_varchar(seq4() % 777, '000')||uniform(1, 10, random()),' ','') as phone,
  case when uniform(1,10,random())>3 then 'MEMBER'
       when uniform(1,10,random())>5 then 'SILVER'
       when uniform(1,10,random())>7 then 'GOLD'
else 'PLATINUM' end as status,
round(18+uniform(0,10,random())+uniform(0,50,random()),-1)+5*uniform(0,1,random()) as age_band,
'REGION_'||uniform(1,20,random()) as region_code,
uniform(1,720,random()) as days_active
  from table(generator(rowcount => 5000000));

create or replace table dcr_homedepot_dev_provider_db.source.exposures comment='{"origin":"sf_ps_wls","name":"dcr","version":{"major":6, "minor":2},"attributes":{"component":"dcr"}}' as
select email, 'campaign_'||uniform(1,3,random()) as campaign,
  case when uniform(1,10,random())>3 then 'STREAMING'
       when uniform(1,10,random())>5 then 'MOBILE'
       when uniform(1,10,random())>7 then 'LINEAR'
else 'DISPLAY' end as device_type,
('2021-'||uniform(3,5,random())||'-'||uniform(1,30,random()))::date as exp_date,
uniform(1,60,random()) as sec_view,
uniform(0,2,random())+uniform(0,99,random())/100 as exp_cost
from dcr_homedepot_dev_provider_db.source.customers sample (20);

/* create views to share provider data with consumer */
create or replace view dcr_homedepot_dev_provider_db.cleanroom.provider_data comment='{"origin":"sf_ps_wls","name":"dcr","version":{"major":6, "minor":2},"attributes":{"component":"dcr"}}' as select * from dcr_homedepot_dev_provider_db.source.customers;
create or replace view dcr_homedepot_dev_provider_db.cleanroom.provider_exposure_data comment='{"origin":"sf_ps_wls","name":"dcr","version":{"major":6, "minor":2},"attributes":{"component":"dcr"}}' as select * from dcr_homedepot_dev_provider_db.source.exposures;
/* create additional views to share with the consumer as required */

GRANT USAGE ON DATABASE dcr_homedepot_dev_provider_db TO ROLE data_clean_room_role_habu;
GRANT USAGE ON SCHEMA dcr_homedepot_dev_provider_db.cleanroom TO ROLE data_clean_room_role_habu;
GRANT SELECT ON TABLE dcr_homedepot_dev_provider_db.cleanroom.provider_data TO ROLE data_clean_room_role_habu;

GRANT SELECT ON VIEW dcr_homedepot_dev_provider_db.cleanroom.provider_data TO ROLE data_clean_room_role_habu;
GRANT OPERATE ON WAREHOUSE dcr_wh TO ROLE data_clean_room_role_habu;

CREATE USER data_clean_room_habu PASSWORD='cleanroom123' DEFAULT_ROLE = data_clean_room_role_habu DEFAULT_WAREHOUSE = dcr_wh;
GRANT ROLE data_clean_room_role_habu TO USER data_clean_room_habu;

create or replace table DCR_HOMEDEPOT_DEV_PROVIDER_DB.SOURCE.univ_exposure_data as
select identifier,id_subtype,extern_tuhhid from ADSALES_MASTER_DB.RAW.UNIVISION_HHG2_LATEST
where id_subtype = 'HEM' limit 1000;

GRANT SELECT ON VIEW dcr_homedepot_dev_provider_db.cleanroom.univ_exposure_data_vw TO ROLE data_clean_room_role_habu;

select * from dcr_homedepot_dev_provider_db.cleanroom.univ_exposure_data_vw;

create or replace view dcr_homedepot_dev_provider_db.cleanroom.univ_exposure_data_vw comment='{"origin":"sf_ps_wls","name":"dcr","version":{"major":6, "minor":2},"attributes":{"component":"dcr"}}' as select * from DCR_HOMEDEPOT_DEV_PROVIDER_DB.SOURCE.univ_exposure_data;

dcr_homedepot_dev_provider_db.cleanroom.univ_exposure_data_vw;
select * from dcr_homedepot_dev_provider_db.cleanroom.provider_data limit 10;