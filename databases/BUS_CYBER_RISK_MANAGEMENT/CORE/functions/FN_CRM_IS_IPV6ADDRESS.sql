CREATE OR REPLACE FUNCTION "FN_CRM_IS_IPV6ADDRESS"("P_IPv6Address" VARCHAR(16777216))
RETURNS BOOLEAN
LANGUAGE SQL
COMMENT='Return true for a correct IPv6 format'
AS '
CASE
    WHEN (P_IPv6Address = '''' or P_IPv6Address= '''') THEN FALSE
    
    -- :: (implies all 8 segments are zero)
    WHEN (P_IPv6Address = ''::'') THEN TRUE
    
    -- Format is y:y:y:y:y:y:y:y where y is any hexadecimal value between 0 and FFFF
    WHEN ((CONTAINS(P_IPv6Address,''.'') = FALSE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',5) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',6) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',7) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',8) REGEXP ''[0-9,a-f,A-F]{1,4}''))  THEN TRUE
    
    -- Format is y:y:y::y:y:y (implies that the middle two segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = FALSE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',4)= '''') AND (split_part(P_IPv6Address,'':'',5) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',-0) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (RIGHT(P_IPv6Address,1) REGEXP ''[0-9,a-f,A-F]'') )   THEN TRUE
    
    -- Format is y:y::y:y (implies that the middle four segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = FALSE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3)= '''') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',5) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',-0) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (RIGHT(P_IPv6Address,1) REGEXP ''[0-9,a-f,A-F]'') )   THEN TRUE
        
    -- Format is y:y:: (implies that the last six segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = FALSE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (RIGHT(P_IPv6Address,2)= ''::'') AND (RIGHT(P_IPv6Address,3) != '':::'')  )   THEN TRUE
        
    -- Format is ::y:y (implies that the first six segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = FALSE) AND (LEFT(P_IPv6Address,2)= ''::'') AND (split_part(P_IPv6Address,'':'',3) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (RIGHT(P_IPv6Address,1) REGEXP ''[0-9,a-f,A-F]'')) THEN TRUE
        
    -- Format is y:y:y:y:y:y:x.x.x.x  where y is any hexadecimal value between 0 and FFFF, x is any number between 0 and 255
    WHEN ((CONTAINS(P_IPv6Address,''.'') = TRUE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',5) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',6) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(split_part(P_IPv6Address,'':'',7),''.'',1) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',7),''.'',2) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',7),''.'',3) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',7),''.'',4) REGEXP ''[0-9]{1,3}'')  )  THEN  TRUE
        
    -- Format is y:y::y:y:5.6.7.8 (implies that the middle two IPv6 segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = TRUE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3)= '''') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',5) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(split_part(P_IPv6Address,'':'',6),''.'',1) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',6),''.'',2) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',6),''.'',3) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',6),''.'',4) REGEXP ''[0-9]{1,3}'')  )  THEN  TRUE
    
    -- Format is ::y:y:91.123.4.56 (implies that the first four IPv6 segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = TRUE) AND (LEFT(P_IPv6Address,2)= ''::'') AND (split_part(P_IPv6Address,'':'',3) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',4) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(split_part(P_IPv6Address,'':'',5),''.'',1) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',5),''.'',2) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',5),''.'',3) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',5),''.'',4) REGEXP ''[0-9]{1,3}'') ) THEN TRUE
    
    -- Format is y:y::123.123.123.123 (implies that the last four IPv6 segments are zero)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = TRUE) AND (split_part(P_IPv6Address,'':'',1) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',2) REGEXP ''[0-9,a-f,A-F]{1,4}'') AND (split_part(P_IPv6Address,'':'',3)= '''') AND (split_part(split_part(P_IPv6Address,'':'',4),''.'',1) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',4),''.'',2) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',4),''.'',3) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',4),''.'',4) REGEXP ''[0-9]{1,3}'') ) THEN  TRUE
    
    -- Format is ::11.22.33.44 (implies all six IPv6 segments are zero with a IPv4 ending)
    WHEN ((CONTAINS(P_IPv6Address,''.'') = TRUE) AND (LEFT(P_IPv6Address,2)= ''::'') AND (split_part(split_part(P_IPv6Address,'':'',3),''.'',1) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',3),''.'',2) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',3),''.'',3) REGEXP ''[0-9]{1,3}'') AND (split_part(split_part(P_IPv6Address,'':'',3),''.'',4) REGEXP ''[0-9]{1,3}'') ) THEN TRUE

    ELSE FALSE
END    
';