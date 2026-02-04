CREATE OR REPLACE PROCEDURE "SP_CRM_FISMAREPORT"()
RETURNS TABLE ()
LANGUAGE SQL
COMMENT='Create quarterly fisma audit report'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_FismaReport'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
RECORD_COUNT number := 0;

d int; 
mindate  date; 
maxdate date; 
today date;
res RESULTSET;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

DROP TABLE IF EXISTS CORE.FismaReportTemp1;
DROP TABLE IF EXISTS CORE.FismaReportTemp2; 
DROP TABLE IF EXISTS CORE.FismaReportTemp3;

CREATE OR REPLACE TEMPORARY TABLE CORE.FismaReportTemp2(
    DW_ASSET_ID NUMBER(38,0) NOT NULL,
    DeviceRole VARCHAR(16777216) NULL,
    DeviceType VARCHAR(16777216) NOT NULL,
    Scanned int DEFAULT 0
);

CREATE TEMPORARY TABLE CORE.FismaReportTemp1 AS
SELECT * FROM CORE.Asset  
where Is_Applicable = 1 
and DATACENTER_ID in (select SYSTEM_ID from CORE.systems where ACRONYM IN (''EDC4'',''CDS VDC GSS'',''HIGLAS'',''NGS VDC'',''Q-Net'',''PESVDC'',''CMS-ESSM''));
--and (LASTMODIFIEDBY_FORESCOUT is not null or UPPER(SOURCE_TOOL_CREATE) = ''FORESCOUT'' or UPPER(SOURCE_TOOL_HWAM)=''FORESCOUT'');

INSERT INTO CORE.FismaReportTemp2(DW_ASSET_ID,DeviceRole,DeviceType)
with a as (
SELECT a.DW_ASSET_ID, dr.DeviceRole,a.os,a.os_cpe,
IFF(UPPER(a.DeviceType) in (''DESKTOP'',''SERVER'',''WORKSTATION'') OR (UPPER(dr.DeviceRole)<>''NETWORKING DEVICE'' AND UPPER(a.DeviceType)=''COMPUTER''),''Non-Portable Computers'',
IFF(UPPER(a.DeviceType) in (''LAPTOP''),''Laptops and Netbooks'',
IFF(UPPER(a.DeviceType) in (''HYPERVISOR''),''Addressable Virtual Machines'',
IFF(UPPER(a.DeviceType) in (''IP PHONE''),''Smartphones'',
IFF(UPPER(a.DeviceType) in (''ROUTER OR SWITCH'',''ROUTER'',''SWITCH'',''NETWORKING'',''NETWORK DEVICE'',''LOAD BALANCER'',''NAT'',''FIREWALL'') or (UPPER(dr.DeviceRole)=''NETWORKING DEVICE'' and UPPER(a.DeviceType)=''COMPUTER''),''Networking Devices'',
IFF(UPPER(a.DeviceType) in (''VOIP'',''ROUTER'',''NETWORK ACCESS CONTROL'',''WIRELESS ACCESS POINT'',''NETWORK MANAGEMENT'',''APPLIANCE''),''Other Communication Devices'',
IFF(UPPER(a.DeviceType) in (''PRINTER'',''NETWORK ATTACHED STORAGE''),''Other Input/Output Devices (with their own address)'',
IFF(UPPER(a.DeviceType) in (''STORAGE''),''Other Addressable Devices on the Network'',	
a.DeviceType)))))))) DeviceType
FROM CORE.FismaReportTemp1 a
left outer join CORE.DeviceTypes dr on upper(dr.DEVICETYPE) = upper(a.DEVICETYPE) 
),
b as (
SELECT a.DW_ASSET_ID, a.DeviceRole,
IFF(UPPER(a.DeviceType) not in (
 ''Addressable Virtual Machines''
,''Laptops and Netbooks''
,''Non-Portable Computers''
,''Smartphones''
,''Other Addressable Devices on the Network''
,''Other Input/Output Devices (with their own address)''
,''Networking Devices''
,''Other Communication Devices''	
),
IFF(UPPER(os_cpe) like ''%WINDOWS%'' or UPPER(os_cpe) like ''%REDHAT%'' or UPPER(os) like ''%WINDOWS%'' or UPPER(os) like ''%WIN%[1-9][1-9]%'' or UPPER(os) like ''%RED%HAT%'' 
or UPPER(os) like ''%UNIX%'' or UPPER(os) like ''%APPLE%OS%''  or UPPER(os) like ''%LINUX%'' or UPPER(os) like ''%UBUNTU%'' or UPPER(os) like ''%FEDORA%''
or UPPER(os) like ''%CENTOS%''  or UPPER(os) like ''%FREEBSD%'',	''Non-Portable Computers'',
IFF(UPPER(os) like ''%JUNOS%'' or UPPER(os) like ''%CISCO%'',''Networking Devices'',
IFF(UPPER(a.DeviceType) in (''Other'',''Not Provided'',''~NoData~''),''Unknown'',
a.DeviceType))),
a.DeviceType) DeviceType
FROM a 
)
select DW_ASSET_ID,
IFF( DeviceType in (''Non-Portable Computers'',''Laptops and Netbooks'',''Addressable Virtual Machines''), ''Endpoint'',
IFF( DeviceType in (''Smartphones''), ''Endpoints (Mobile Assets)'',
IFF( DeviceType in (''Networking Devices'',''Other Communication Devices''), ''Networking Devices'',
IFF( DeviceType in (''Other Input/Output Devices (with their own address)'',''Other Addressable Devices on the Network''), ''Input/Output Devices'',
IFF(DeviceRole in (''Other''),''Unknown'',
DeviceRole))))) DeviceRole
,DeviceType
from b;

set today:=(select max(report_date)::DATE  FROM CORE.Report_IDs);

FOR i IN 1 TO 3 DO
    SET d:=IFF(i=1,7,IFF(i=2,14,30));
    SET maxdate:=today;	
     
    CREATE OR REPLACE TEMPORARY TABLE  CORE.FismaReportTemp3 AS
    select DW_ASSET_ID from CORE.FismaReportTemp2;

    FOR r IN 1 TO 3 DO
        set mindate:=DATEADD(day,-d,maxdate);

        delete from CORE.FismaReportTemp3  
        WHERE DW_ASSET_ID not in
        (
         select t.DW_ASSET_ID  from CORE.AssetHist  ah join CORE.FismaReportTemp3 t on ah.DW_ASSET_ID = t.DW_ASSET_ID 
         WHERE ah.last_confirmed_time between :mindate and :maxdate group by t.DW_ASSET_ID 
        );

        SET maxdate:=mindate;

    END FOR;

    UPDATE CORE.FismaReportTemp2 t2
    set Scanned=BITOR(Scanned,IFF(:i=3,4,:i))
    FROM CORE.FismaReportTemp3 t3 WHERE t2.DW_ASSET_ID=t3.DW_ASSET_ID;

END FOR;

res:= (
with a AS(
SELECT DeviceRole ,DeviceType,count(1) Total FROM CORE.FismaReportTemp2 
group by DeviceRole ,DeviceType 
), 
c AS (
SELECT DeviceRole ,DeviceType,count(1) Total FROM CORE.FismaReportTemp2
where GETBIT(Scanned,0)=1
group by DeviceRole ,DeviceType 
),
d AS (
SELECT DeviceRole ,DeviceType,count(1) Total FROM CORE.FismaReportTemp2
where GETBIT(Scanned,1)=1
group by DeviceRole ,DeviceType 
),
e AS (
SELECT DeviceRole ,DeviceType,count(1) Total FROM CORE.FismaReportTemp2
where GETBIT(Scanned,2)=1
group by DeviceRole ,DeviceType 
)
select a.*,IFNULL(c.Total,0) day7, IFNULL(d.Total,0) day14,IFNULL(e.Total,0) day30 from a 
left join c on a.DeviceRole=c.DeviceRole and a.DeviceType=c.DeviceType
left join d on a.DeviceRole=d.DeviceRole and a.DeviceType=d.DeviceType
left join e on a.DeviceRole=e.DeviceRole and a.DeviceType=e.DeviceType
);

DROP TABLE IF EXISTS CORE.FismaReportTemp1;
DROP TABLE IF EXISTS CORE.FismaReportTemp2; 
DROP TABLE IF EXISTS CORE.FismaReportTemp3;

CALL CORE.SP_CRM_END_PROCEDURE (:Appl);

RETURN TABLE(res);

EXCEPTION
  when statement_error then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Statement_Error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when CRM_logic_exception then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''CRM_logic_exception'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when other then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Other error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
END;
';