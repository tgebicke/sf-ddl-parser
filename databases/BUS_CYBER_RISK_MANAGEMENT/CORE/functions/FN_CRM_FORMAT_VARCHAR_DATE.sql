CREATE OR REPLACE FUNCTION "FN_CRM_FORMAT_VARCHAR_DATE"("P_STRING" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Given format Tue Aug 22 06:52:26 2023, yield 08/22/2023 06:52:26'
AS '

case upper(SUBSTRING(P_STRING,5,3))
    when ''JAN'' then ''01''
    when ''JAN'' then ''01''
	when ''FEB'' then ''02''
	when ''MAR'' then ''03''
	when ''APR'' then ''04''
	when ''MAY'' then ''05''
	when ''JUN'' then ''06''
	when ''JUL'' then ''07''
	when ''AUG'' then ''08''
	when ''SEP'' then ''09''
	when ''OCT'' then ''10''
	when ''NOV'' then ''11''
	when ''DEC'' then ''12''
end || ''/'' || SUBSTRING(P_STRING,9,2) || ''/'' || SUBSTRING(P_STRING,21,4) 
|| SUBSTRING(P_STRING,11,9)

';