create or replace TABLE DEVICEROLES (
	DEVICEROLE VARCHAR(16777216) NOT NULL,
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	primary key (DEVICEROLE)
)COMMENT='Lists of device roles (e.g. endpoint, mobile, networking device, etc..)\t'
;