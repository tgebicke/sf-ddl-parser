create or replace view VW_DEVICETYPEDETAIL(
	DATACENTER_ACRONYM,
	DEVICETYPE,
	OS,
	OS_TYPE,
	ASSETTATTOOPRESENT,
	TOTAL
) COMMENT='Shows total asset across DATACENTER_ACRONYM,DEVICETYPE,OS,OS_TYPE,ASSETTATTOOPRESENT.'
 as
SELECT 
a.DataCenter_Acronym,a.DeviceType,a.OS,os.OS_Type
,CASE coalesce(a.asset_id_tattoo,'ITSNULL')
	when 'ITSNULL' then 'No'
	Else 'Yes'
End assetTattooPresent
,COUNT(1) as Total
FROM CORE.VW_Assets a
LEFT OUTER JOIN (
select distinct OS 
,case OS
	when 'Amazon Linux' then 'Linux'
	when 'Amazon Linux AMI' then 'Linux'
	when 'Debian GNU/Linux' then 'Linux'
	when 'Linux Red Hat Enterprise Server 6.10 (2.6.32-696.30.1.el6.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 6.10 (2.6.32-754.27.1.el6.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 6.10 (2.6.32-754.35.1.el6.s390x)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 6.10 (2.6.32-754.35.1.el6.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.4 (3.10.0-693.11.6.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.5 (3.10.0-862.14.4.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.6 (3.10.0-957.21.2.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.6 (3.10.0-957.27.2.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.7 (3.10.0-1062.1.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.7 (3.10.0-1062.12.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.7 (3.10.0-1062.9.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.7 (3.10.0-957.27.2.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.8 (3.10.0-1062.12.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.8 (3.10.0-1127.13.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.8 (3.10.0-1127.19.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.8 (3.10.0-1127.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.8 (3.10.0-957.21.2.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.9 (3.10.0-1160.2.1.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.9 (3.10.0-1160.2.2.el7.x86_64)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.9 (3.10.0-1160.6.1.el7.s390x)' then 'Linux'
	when 'Linux Red Hat Enterprise Server 7.9 (3.10.0-1160.6.1.el7.x86_64)' then 'Linux'
	when 'Mac OS X 10.13.6 (17G14033)' then 'Mac'
	when 'Mac OS X 10.13.6 (17G14042)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G103)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G3020)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G4032)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G5033)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G6020)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G6032)' then 'Mac'
	when 'Mac OS X 10.14.6 (18G6042)' then 'Mac'
	when 'Mac OS X 10.15.3 (19D76)' then 'Mac'
	when 'Mac OS X 10.15.4 (19E287)' then 'Mac'
	when 'Mac OS X 10.15.6 (19G2021)' then 'Mac'
	when 'Mac OS X 10.15.7 (19H15)' then 'Mac'
	when 'Mac OS X 10.15.7 (19H2)' then 'Mac'
	when 'Mac OS X 10.16 (20B29)' then 'Mac'
	when 'Microsoft Windows Server 2012 R2 Standard' then 'Windows'
	when 'Microsoft Windows Server 2016 Datacenter' then 'Windows'
	when 'Microsoft Windows Server 2019 Datacenter' then 'Windows'
	when 'Red Hat Enterprise Linux Server' then 'Linux'
	when 'SunOS 5.10 (Generic_150400-69)' then 'SunOS'
	when 'SunOS 5.10 (Generic_153153-01)' then 'SunOS'
	when 'SunOS 5.10 (Generic_Virtual)' then 'SunOS'
	when 'SunOS 5.11 (11.3)' then 'SunOS'
	when 'SunOS 5.11 (11.4.24.75.2)' then 'SunOS'
	when 'SunOS 5.11 (11.4.26.75.4)' then 'SunOS'
	when 'Ubuntu' then 'Ubuntu'
	when 'Win10 10.0.14393.2791 (1607)' then 'Windows'
	when 'Win10 10.0.15063.2106 (1703)' then 'Windows'
	when 'Win10 10.0.15063.2253 (1703)' then 'Windows'
	when 'Win10 10.0.15063.2375 (1703)' then 'Windows'
	when 'Win10 10.0.17134.1006 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1009 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1184 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1246 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1276 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1304 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1365 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1425 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1488 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1550 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1553 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1610 (1803)' then 'Windows'
	when 'Win10 10.0.17134.165 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1667 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1726 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1792 (1803)' then 'Windows'
	when 'Win10 10.0.17134.1845 (1803)' then 'Windows'
	when 'Win10 10.0.18362.1016 (1909)' then 'Windows'
	when 'Win10 10.0.18362.1082 (1909)' then 'Windows'
	when 'Win10 10.0.18362.1139 (1903)' then 'Windows'
	when 'Win10 10.0.18362.418 (1909)' then 'Windows'
	when 'Win10 10.0.18362.959 (1903)' then 'Windows'
	when 'Win10 10.0.18363.1016 (1909)' then 'Windows'
	when 'Win10 10.0.18363.1198 (1909)' then 'Windows'
	when 'Win2008 6.0.6003' then 'Windows'
	when 'Win2008R2 6.1.7601' then 'Windows'
	when 'Win2012 6.2.9200' then 'Windows'
	when 'Win2012R2 6.3.9600' then 'Windows'
	when 'Win2016 10.0.14393.3866 (1607)' then 'Windows'
	when 'Win2016 10.0.14393.3930 (1607)' then 'Windows'
	when 'Win2016 10.0.14393.3986 (1607)' then 'Windows'
	when 'Win2016 10.0.14393.4046 (1607)' then 'Windows'
	when 'Win2019 10.0.17763.1282 (1809)' then 'Windows'
	when 'Win2019 10.0.17763.1518 (1809)' then 'Windows'
	when 'Win2019 10.0.17763.1554 (1809)' then 'Windows'
	when 'Win2019 10.0.17763.1577 (1809)' then 'Windows'
	when 'Win7 6.1.7601' then 'Windows'
	when 'Win8.1 6.3.9600' then 'Windows'
Else 'UNKNOWN'
End as OS_Type
from CORE.VW_Assets
) os on os.os = a.OS
GROUP BY a.DataCenter_Acronym,a.DeviceType,a.OS,os.OS_Type
,CASE coalesce(a.asset_id_tattoo,'ITSNULL')
	when 'ITSNULL' then 'No'
	Else 'Yes'
End 
order by a.DataCenter_Acronym,a.DeviceType,a.OS,os.OS_Type
,CASE coalesce(a.asset_id_tattoo,'ITSNULL')
	when 'ITSNULL' then 'No'
	Else 'Yes'
End;