create or replace view VW_DESIRABEL_METADATA_PLUGINS(
	PLUGINID,
	PLUGINNAME,
	OS
) COMMENT='CRITICAL; View specifies Tenable plugins that represent metadata that is desireable\t'
 as
SELECT COLUMN1 as PluginID, COLUMN2 as PluginName,COLUMN3 as OS
FROM VALUES
('11936','OS Identification','All')
,('19506','Nessus Scan Information','All')
,('20811','Microsoft Windows Installed Software Enumeration (credentialed check)','Windows')
,('22869','Software Enumeration (SSH)','Linux')
,('25251','OS Identification : Unix uname','Linux') -- 230523 None found
,('45590','Common Platform Enumeration (CPE)','All')
,('90191','Amazon Web Services EC2 Instance Metadata Enumeration (Unix)','Unix')
,('90427','Amazon Web Services EC2 Instance Metadata Enumeration (Windows)','Windows')
,('1032381','Not seen on Nessus site. Perhaps a version of 1218405. Written in house?','Unknown')
,('1218405','Check for Empty FISMA Tattoo files. (Written in house)','Linux')
,('1221295','Print out FISMA registry keys. (Written in house)','Windows')
;