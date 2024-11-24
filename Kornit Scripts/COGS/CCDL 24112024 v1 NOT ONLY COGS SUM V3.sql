SELECT SUM ( nvl ( FOR_SUM_LAYER.MATERIAL_LEDGER_AMOUNT, 0 )  )   MATERIAL_LEDGER_AMOUNT
,      SUM ( NVL ( FOR_SUM_LAYER.OVERHEAD_LEDGER_AMOUNT  , 0 ) )  OVERHEAD_LEDGER_AMOUNT
,      SUM ( NVL ( FOR_SUM_LAYER.RESOURCE_LEDGER_AMOUNT , 0 ) )   RESOURCE_LEDGER_AMOUNT
,      SUM ( NVL ( FOR_SUM_LAYER.PROFIT_IN_INV_LEDGER_AMOUNT, 0 ))  PROFIT_IN_INV_LEDGER_AMOUNT
,      SUM   ( NVL ( FOR_SUM_LAYER.TOTAL_LEDGER_AMOUNT, 0))           TOTAL_LEDGER_AMOUNT
,      FOR_SUM_LAYER.DOO_FULLFILL_LINE_ID
,      FOR_SUM_LAYER.EVENT_TYPE_CODE	
,      FOR_SUM_LAYER.GL_DATE	
,      FOR_SUM_LAYER.DOO_ORDER_TYPE	
,      FOR_SUM_LAYER.SO_ORDER_NUMBER	
,      FOR_SUM_LAYER.TRANSFER_ORDER_NUMBER	
,      FOR_SUM_LAYER.RMA_ORDER_NUMBER	
,      FOR_SUM_LAYER.PERIOD_NAME
,      FOR_SUM_LAYER.DIST_ADDITIONAL_PROCESSING_CODE
,      FOR_SUM_LAYER.TRANSACTION_NUMBER
,      FOR_SUM_LAYER.COST_ORG_NAME	
,      FOR_SUM_LAYER.ACCOUNTING_LINE_TYPE	
,      FOR_SUM_LAYER.LEDGER_NAME
,      FOR_SUM_LAYER.ITEM_NUMBER	
,      FOR_SUM_LAYER.ITEM_DESCRIPTION
,      FOR_SUM_LAYER.COGS_DCOGS_LINE_CALC
,      ( NVL ( FOR_SUM_LAYER.FULFILLED_QTY	, 0 ))   FULFILLED_QTY
,       ( NVL (   FOR_SUM_LAYER.SHIPPED_QTY , 0 ))    SHIPPED_QTY

,       ( FOR_SUM_LAYER.FULFILLMENT_DATE )   FULFILLMENT_DATE
,       ( FOR_SUM_LAYER.ORDER_LINE_NUMBER	)   ORDER_LINE_NUMBER 
,       (  FOR_SUM_LAYER.ORDER_DISPLAY_LINE_NUMBER	 )  ORDER_DISPLAY_LINE_NUMBER
,       ( FOR_SUM_LAYER.FULFILL_LINE_NUMBER	 )  FULFILL_LINE_NUMBER

,      FOR_SUM_LAYER.ACCOUNT_NUMBER  



/*
,      HCU.ACCOUNT_NAME   
,      HCU.CUSTOMER_CLASS_CODE 
,      HZP.PARTY_NUMBER
,      HZP.PARTY_NAME
*/
FROM ( 

WITH FROM_PERIOD AS
        (
                SELECT
                        GPS.EFFECTIVE_PERIOD_NUM FROM_EFFECTIVE_PERIOD_NUM
                FROM
                        GL_PERIOD_STATUSES GPS ,
                        GL_LEDGERS         GLD
                WHERE
                        1                   = 1
                AND     GPS.PERIOD_NAME     = (:From_Period_Name )
                AND     GPS.APPLICATION_ID  = 101
                AND     GPS.SET_OF_BOOKS_ID = GLD.LEDGER_ID
                AND     (
                                GLD.NAME IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
                AND     EXISTS
                        (
                                SELECT
                                        1
                                FROM
                                        GL_PERIODS GP
                                WHERE
                                        1                  = 1
                                AND     GP.PERIOD_NAME     = GPS.PERIOD_NAME
                                AND     GP.PERIOD_TYPE     = GPS.PERIOD_TYPE
                                AND     GP.PERIOD_SET_NAME = 'XXKD_ACCT_CALEN'
                                AND     GP.PERIOD_TYPE     = 'MONTH2380721164'
                                --                  AND    GP.ADJUSTMENT_PERIOD_FLAG = 'N'
                        ) ) 
, TO_PERIOD AS
        (
                SELECT
                        GPS.EFFECTIVE_PERIOD_NUM TO_EFFECTIVE_PERIOD_NUM
                FROM
                        GL_PERIOD_STATUSES GPS ,
                        GL_LEDGERS         GLD
                WHERE
                        1                   = 1
                AND     GPS.APPLICATION_ID  = 101
                AND     GPS.PERIOD_NAME     = (:TO_Period_Name )
                AND     GPS.SET_OF_BOOKS_ID = GLD.LEDGER_ID
                AND     (
                                GLD.NAME IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
                AND     EXISTS
                        (
                                SELECT
                                        1
                                FROM
                                        GL_PERIODS GP
                                WHERE
                                        1                  = 1
                                AND     GP.PERIOD_NAME     = GPS.PERIOD_NAME
                                AND     GP.PERIOD_TYPE     = GPS.PERIOD_TYPE
                                AND     GP.PERIOD_SET_NAME = 'XXKD_ACCT_CALEN'
                                AND     GP.PERIOD_TYPE     = 'MONTH2380721164'
                                --                  AND    GP.ADJUSTMENT_PERIOD_FLAG = 'N'
                        ) )
 , PERIOD_PARAM AS
      (
                SELECT
                        GPS.PERIOD_NAME                 ,
                        GPS.START_DATE PARAM_START_DATE ,
                        GPS.END_DATE   PARAM_END_DATE
                FROM
                        GL_PERIOD_STATUSES GPS         ,
                        GL_LEDGERS         GLD         ,
                        FROM_PERIOD        FROM_PERIOD ,
                        TO_PERIOD          TO_PERIOD
                WHERE
                        1                   = 1
                AND     GPS.APPLICATION_ID  = 101
                AND     GPS.SET_OF_BOOKS_ID = GLD.LEDGER_ID
                AND     (
                                GLD.NAME IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
                AND     EXISTS
                        (
                                SELECT
                                        1
                                FROM
                                        GL_PERIODS GP
                                WHERE
                                        1                  = 1
                                AND     GP.PERIOD_NAME     = GPS.PERIOD_NAME
                                AND     GP.PERIOD_TYPE     = GPS.PERIOD_TYPE
                                AND     GP.PERIOD_SET_NAME = 'XXKD_ACCT_CALEN'
                                AND     GP.PERIOD_TYPE     = 'MONTH2380721164'
                                --                  AND    GP.ADJUSTMENT_PERIOD_FLAG = 'N'
                        )
                        AND GPS.EFFECTIVE_PERIOD_NUM >= FROM_PERIOD.FROM_EFFECTIVE_PERIOD_NUM
                        AND GPS.EFFECTIVE_PERIOD_NUM <= TO_PERIOD.TO_EFFECTIVE_PERIOD_NUM  
)

---- MAIN 
,   CCDL_WITH AS 
(

SELECT CCDL_DATA.DISTRIBUTION_ID
,        ( CCDL_DATA.MATERIAL_COST_ELEMENT_TYPE )    MATERIAL_COST_ELEMENT_TYPE
,        (  CCDL_DATA.OVERHEAD_COST_ELEMENT_TYPE )  OVERHEAD_COST_ELEMENT_TYPE
,        (   CCDL_DATA.RESOURCE_COST_ELEMENT_TYPE   ) RESOURCE_COST_ELEMENT_TYPE
,        (  CCDL_DATA.PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE ) PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE
,        (  NVL  ( CCDL_DATA.MATERIAL_LEDGER_AMOUNT , 0  ) )  MATERIAL_LEDGER_AMOUNT
,        (  NVL  ( CCDL_DATA.MATERIAL_COGS_AMOUNT , 0  ) )     MATERIAL_COGS_AMOUNT  
,        (   NVL  ( CCDL_DATA.OVERHEAD_LEDGER_AMOUNT  , 0  ) )   OVERHEAD_LEDGER_AMOUNT
,        (  NVL  ( CCDL_DATA. OVERHEAD_COGS_AMOUNT, 0  )  )     OVERHEAD_COGS_AMOUNT  
,        (   NVL  ( CCDL_DATA.RESOURCE_LEDGER_AMOUNT , 0  )  )   RESOURCE_LEDGER_AMOUNT
,        (  NVL  ( CCDL_DATA.RESOURCE_COGS_AMOUNT, 0  )  )     RESOURCE_COGS_AMOUNT  
,        (   NVL  ( CCDL_DATA.PROFIT_IN_INV_LEDGER_AMOUNT , 0  )  )   PROFIT_IN_INV_LEDGER_AMOUNT
,        (   NVL  ( CCDL_DATA.PROFIT_IN_INV_COGS_AMOUNT , 0  ) )     PROFIT_IN_INV_COGS_AMOUNT  
,        (  NVL  ( CCDL_DATA.MATERIAL_LEDGER_AMOUNT , 0  ) +  NVL  ( CCDL_DATA.OVERHEAD_LEDGER_AMOUNT  , 0  )  +
               NVL  ( CCDL_DATA.RESOURCE_LEDGER_AMOUNT , 0  )  + NVL  ( CCDL_DATA.PROFIT_IN_INV_LEDGER_AMOUNT , 0  )  ) TOTAL_LEDGER_AMOUNT
,        (  NVL  ( CCDL_DATA.MATERIAL_COGS_AMOUNT , 0  ) +  NVL  ( CCDL_DATA. OVERHEAD_COGS_AMOUNT, 0  )    +
				 NVL  ( CCDL_DATA.RESOURCE_COGS_AMOUNT, 0  )	+  NVL  ( CCDL_DATA.PROFIT_IN_INV_COGS_AMOUNT , 0  ))   TOTAL_COGS_AMOUNT                   
,      CCDL_DATA.COST_BOOK_ID
,      CCDL_DATA.DOO_FULLFILL_LINE_ID 
,      CCDL_DATA.COST_ORGANIZATION_ID
,      CCDL_DATA.LEDGER_ID  
,      CCDL_DATA.DEP_TRXN_ID   
,      CCDL_DATA.TRANSACTION_ID
,      CCDL_DATA.EVENT_TYPE_CODE
,      CCDL_DATA.GL_DATE
,      CCDL_DATA.DOO_ORDER_TYPE 
,      CCDL_DATA.SO_ORDER_NUMBER 
,      CCDL_DATA.TRANSFER_ORDER_NUMBER 
,      CCDL_DATA.RMA_ORDER_NUMBER
,      CCDL_DATA.PERIOD_NAME   
,      CCDL_DATA.DIST_COST_TRANSACTION_TYPE     
,      CCDL_DATA.DIST_ADDITIONAL_PROCESSING_CODE
,      CCDL_DATA.AE_HEADER_ID                 
,      CCDL_DATA.AE_LINE_NUM                  
,      CCDL_DATA.CCDL_SLA_CODE_COMBINATION_ID 
,      CCDL_DATA.TRANSACTION_NUMBER 
,      CCDL_DATA.CUSTOMER_ID
,      CCDL_DATA.COST_ORG_NAME
,      CCDL_DATA.ACCOUNTING_LINE_TYPE
FROM 
(
SELECT  ccd.DISTRIBUTION_ID  
,       CCDL.DISTRIBUTION_LINE_ID 
,       ccev.COST_ELEMENT_TYPE                 MATERIAL_COST_ELEMENT_TYPE
,       NULL                                   OVERHEAD_COST_ELEMENT_TYPE
,       NULL                                   RESOURCE_COST_ELEMENT_TYPE
,       NULL                                   PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE
,       nvl (   CCDL.LEDGER_AMOUNT , 0   )     MATERIAL_LEDGER_AMOUNT  
,       nvl (    CCGD.COGS_AMOUNT , 0   )      MATERIAL_COGS_AMOUNT
,       NULL                                   OVERHEAD_LEDGER_AMOUNT  
,       NULL                                   OVERHEAD_COGS_AMOUNT
,       NULL                                   RESOURCE_LEDGER_AMOUNT  
,       NULL                                   RESOURCE_COGS_AMOUNT
,       NULL                                   PROFIT_IN_INV_LEDGER_AMOUNT  
,       NULL                                   PROFIT_IN_INV_COGS_AMOUNT
,       CCGD.COGS_TYPE 
,       CCGD.DOO_FULLFILL_LINE_ID 
---
,       CCD.COST_BOOK_ID
,       CCD.COST_ORGANIZATION_ID
,       CCD.LEDGER_ID  
,       CCD.DEP_TRXN_ID   
,       CCD.TRANSACTION_ID
,       CCD.EVENT_TYPE_CODE
,       CCD.GL_DATE
,       CCGD.DOO_ORDER_TYPE 

,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'SO'
		     THEN  CCGD.DOO_ORDER_NUMBER
        END SO_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'TO'
             THEN  CCGD.DOO_ORDER_NUMBER
        END TRANSFER_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'RMA'
             THEN  CCGD.DOO_ORDER_NUMBER
        END RMA_ORDER_NUMBER
,       CPS.PERIOD_NAME       
,       CCD.COST_TRANSACTION_TYPE      DIST_COST_TRANSACTION_TYPE     
,       CCD.ADDITIONAL_PROCESSING_CODE DIST_ADDITIONAL_PROCESSING_CODE
,       CCDL.AE_HEADER_ID                       AE_HEADER_ID                 
,       CCDL.AE_LINE_NUM                        AE_LINE_NUM                  
,       CCDL.SLA_CODE_COMBINATION_ID            CCDL_SLA_CODE_COMBINATION_ID        
,       CCD.TRANSACTION_NUMBER                        
,       CCGD.CUSTOMER_ID
,       CCOV.COST_ORG_NAME 
,       CCGD.ACCOUNTING_LINE_TYPE
FROM    CST_COST_DISTRIBUTION_LINES    CCDL
,       CST_COST_DISTRIBUTIONS         CCD 
,       CST_COST_ELEMENTS_VL           CCEV
,       CST_COGS_DETAILS               CCGD
,       CST_COST_BOOKS_B               BK   
,       CST_PERIOD_STATUSES            CPS
,       PERIOD_PARAM                   PERIOD_PARAM                      
,       CST_COST_ORGS_V                CCOV 

WHERE  1 = 1
AND    ccdl.COST_ELEMENT_ID   = ccev.COST_ELEMENT_ID  
AND    CCDL.DISTRIBUTION_ID = CCD.DISTRIBUTION_ID  
AND     CCDL.DISTRIBUTION_ID      = CCGD.DISTRIBUTION_ID
AND     CCDL.DISTRIBUTION_LINE_ID = CCGD.DISTRIBUTION_LINE_ID
AND     CCD.COST_BOOK_ID             =          BK.COST_BOOK_ID
AND     BK.COST_BOOK_CODE            = ('Primary Cost Book')
AND     CCD.COST_ORGANIZATION_ID     = CCOV.COST_ORG_ID 
AND    CCD.COST_BOOK_ID         = CPS.COST_BOOK_ID
AND    CCD.COST_ORGANIZATION_ID = CPS.COST_ORG_ID 
AND    CCD.GL_DATE                                    >= CPS.START_DATE
AND    CCD.GL_DATE                                    < CPS.END_DATE + 1
AND    CPS.PERIOD_NAME             IN PERIOD_PARAM.PERIOD_NAME

-- AND    CCGD.ACCOUNTING_LINE_TYPE = 'COST_OF_GOODS_SOLD'
AND    ccev.COST_ELEMENT_TYPE  = 'MATERIAL'
AND    CCOV.COST_ORG_NAME       = (:P_COST_ORG_NAME)    -- 300000005646377
AND EXISTS   ( SELECT 1     
               FROM  XLA_AE_HEADERS XAH 
			   ,      XLA_AE_LINES   XAL
               ,      GL_LEDGERS     GLD 
               ,      GL_PERIODS               GLP 
               ,      PERIOD_PARAM             PERIOD_PARAM
               WHERE 1 = 1
               AND    CCDL.AE_HEADER_ID        =  XAL.AE_HEADER_ID 
		       AND    CCDL.AE_LINE_NUM         =  XAL.AE_LINE_NUM 
               AND    CCDL.AE_HEADER_ID        =  XAH.AE_HEADER_ID 
               AND    xah.LEDGER_ID            =  gld.LEDGER_ID
               AND    XAH.PERIOD_NAME          =  GLP.PERIOD_NAME
               AND    GLP.PERIOD_SET_NAME      = 'XXKD_ACCT_CALEN'
               AND    GLP.PERIOD_TYPE          = 'MONTH2380721164'
               AND    XAL.ACCOUNTING_CLASS_CODE IN ('COST_OF_GOODS_SOLD',
                                                      'DEFERRED_COGS',
                                                      'DEFERRED_COST_OF_GOODS_SOLD',
                                                      'INTERCOMPANY_COGS')          
               AND ( GLD.NAME  IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))      --        300000003031029                            
			  --   AND    xah.LEDGER_ID       =    300000003031029
               AND    XAH.PERIOD_NAME  IN PERIOD_PARAM.PERIOD_NAME
 )    
 

UNION ALL
SELECT  ccd.DISTRIBUTION_ID  
,       CCDL.DISTRIBUTION_LINE_ID 
,       NULL                                  MATERIAL_COST_ELEMENT_TYPE
,       ccev.COST_ELEMENT_TYPE                OVERHEAD_COST_ELEMENT_TYPE
,       NULL                                  RESOURCE_COST_ELEMENT_TYPE
,       NULL                                  PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE

,       NULL                                  MATERIAL_LEDGER_AMOUNT  
,       NULL                                  MATERIAL_COGS_AMOUNT
,       nvl (   CCDL.LEDGER_AMOUNT , 0   )    OVERHEAD_LEDGER_AMOUNT  
,       nvl (    CCGD.COGS_AMOUNT , 0   )     OVERHEAD_COGS_AMOUNT
,       NULL                                  RESOURCE_LEDGER_AMOUNT  
,       NULL                                  RESOURCE_COGS_AMOUNT
,       NULL                                  PROFIT_IN_INV_LEDGER_AMOUNT  
,       NULL                                  PROFIT_IN_INV_COGS_AMOUNT


,       CCGD.COGS_TYPE 
,       CCGD.DOO_FULLFILL_LINE_ID 
,       CCD.COST_BOOK_ID
,       CCD.COST_ORGANIZATION_ID
,       CCD.LEDGER_ID  
,       CCD.DEP_TRXN_ID   
,       CCD.TRANSACTION_ID
,       CCD.EVENT_TYPE_CODE
,       CCD.GL_DATE
,       CCGD.DOO_ORDER_TYPE 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'SO'
		     THEN  CCGD.DOO_ORDER_NUMBER
        END SO_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'TO'
             THEN  CCGD.DOO_ORDER_NUMBER
        END TRANSFER_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'RMA'
             THEN  CCGD.DOO_ORDER_NUMBER
        END RMA_ORDER_NUMBER
,       CPS.PERIOD_NAME   
,       CCD.COST_TRANSACTION_TYPE      DIST_COST_TRANSACTION_TYPE     
,       CCD.ADDITIONAL_PROCESSING_CODE DIST_ADDITIONAL_PROCESSING_CODE
,       CCDL.AE_HEADER_ID                       AE_HEADER_ID                 
,       CCDL.AE_LINE_NUM                        AE_LINE_NUM                  
,       CCDL.SLA_CODE_COMBINATION_ID            CCDL_SLA_CODE_COMBINATION_ID 
,       CCD.TRANSACTION_NUMBER    
,       CCGD.CUSTOMER_ID
,       CCOV.COST_ORG_NAME 
,       CCGD.ACCOUNTING_LINE_TYPE
FROM   CST_COST_DISTRIBUTION_LINES    CCDL
,      CST_COST_DISTRIBUTIONS         CCD 
,      CST_COST_ELEMENTS_VL           CCEV
,      CST_COGS_DETAILS               CCGD
,      CST_COST_BOOKS_B               BK 
,       CST_PERIOD_STATUSES           CPS
,       PERIOD_PARAM                  PERIOD_PARAM 
,      CST_COST_ORGS_V                CCOV 
WHERE  1 = 1
AND    ccdl.COST_ELEMENT_ID   = ccev.COST_ELEMENT_ID  
AND    CCDL.DISTRIBUTION_ID = CCD.DISTRIBUTION_ID  
AND     CCDL.DISTRIBUTION_ID      = CCGD.DISTRIBUTION_ID
AND     CCDL.DISTRIBUTION_LINE_ID = CCGD.DISTRIBUTION_LINE_ID
AND     CCD.COST_BOOK_ID             =          BK.COST_BOOK_ID
AND     BK.COST_BOOK_CODE            = ('Primary Cost Book')
AND     CCD.COST_ORGANIZATION_ID     = CCOV.COST_ORG_ID

-- AND    CCGD.ACCOUNTING_LINE_TYPE = 'COST_OF_GOODS_SOLD'
AND    ccev.COST_ELEMENT_TYPE  = 'OVERHEAD'
AND    CCD.COST_BOOK_ID         = CPS.COST_BOOK_ID
AND    CCD.COST_ORGANIZATION_ID = CPS.COST_ORG_ID 
AND    CCD.GL_DATE                                    >= CPS.START_DATE
AND    CCD.GL_DATE                                    < CPS.END_DATE + 1
AND    CPS.PERIOD_NAME             IN PERIOD_PARAM.PERIOD_NAME
AND    CCOV.COST_ORG_NAME       = (:P_COST_ORG_NAME)   
AND EXISTS   ( SELECT 1     
               FROM  XLA_AE_HEADERS XAH 
			   ,      XLA_AE_LINES   XAL
               ,      GL_LEDGERS     GLD 
               ,      GL_PERIODS               GLP 
               ,      PERIOD_PARAM             PERIOD_PARAM
               WHERE 1 = 1
               AND    CCDL.AE_HEADER_ID   =    XAL.AE_HEADER_ID 
		       AND    CCDL.AE_LINE_NUM    =    XAL.AE_LINE_NUM 
               AND    CCDL.AE_HEADER_ID   =    XAH.AE_HEADER_ID 
               AND    xah.LEDGER_ID       =    gld.LEDGER_ID
               AND    XAH.PERIOD_NAME          =  GLP.PERIOD_NAME
               AND    GLP.PERIOD_SET_NAME      = 'XXKD_ACCT_CALEN'
               AND    GLP.PERIOD_TYPE          = 'MONTH2380721164'               
               AND    XAL.ACCOUNTING_CLASS_CODE IN ('COST_OF_GOODS_SOLD',
                                                      'DEFERRED_COGS',
                                                      'DEFERRED_COST_OF_GOODS_SOLD',
                                                      'INTERCOMPANY_COGS')                
			  -- AND    xah.LEDGER_ID       =    300000003031029
               AND ( GLD.NAME  IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))      --        300000003031029   			      
               AND    XAH.PERIOD_NAME  IN PERIOD_PARAM.PERIOD_NAME
 )
 UNION ALL
SELECT  ccd.DISTRIBUTION_ID  
,       CCDL.DISTRIBUTION_LINE_ID 
,       NULL                                  MATERIAL_COST_ELEMENT_TYPE
,       NULL                                  OVERHEAD_COST_ELEMENT_TYPE
,       ccev.COST_ELEMENT_TYPE                RESOURCE_COST_ELEMENT_TYPE
,       NULL                                  PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE

,       NULL                                  MATERIAL_LEDGER_AMOUNT  
,       NULL                                  MATERIAL_COGS_AMOUNT
,       NULL                                  OVERHEAD_LEDGER_AMOUNT  
,       NULL                                  OVERHEAD_COGS_AMOUNT
,       nvl (   CCDL.LEDGER_AMOUNT , 0   )    RESOURCE_LEDGER_AMOUNT  
,       nvl (    CCGD.COGS_AMOUNT , 0   )     RESOURCE_COGS_AMOUNT
,       NULL                                  PROFIT_IN_INV_LEDGER_AMOUNT  
,       NULL                                  PROFIT_IN_INV_COGS_AMOUNT


,       CCGD.COGS_TYPE 
,       CCGD.DOO_FULLFILL_LINE_ID 
,       CCD.COST_BOOK_ID
,       CCD.COST_ORGANIZATION_ID
,       CCD.LEDGER_ID  
,       CCD.DEP_TRXN_ID   
,       CCD.TRANSACTION_ID
,       CCD.EVENT_TYPE_CODE
,       CCD.GL_DATE
,       CCGD.DOO_ORDER_TYPE 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'SO'
		     THEN  CCGD.DOO_ORDER_NUMBER
        END SO_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'TO'
             THEN  CCGD.DOO_ORDER_NUMBER
        END TRANSFER_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'RMA'
             THEN  CCGD.DOO_ORDER_NUMBER
        END RMA_ORDER_NUMBER
,       CPS.PERIOD_NAME           
,       CCD.COST_TRANSACTION_TYPE      DIST_COST_TRANSACTION_TYPE     
,       CCD.ADDITIONAL_PROCESSING_CODE DIST_ADDITIONAL_PROCESSING_CODE
,       CCDL.AE_HEADER_ID                       AE_HEADER_ID                 
,       CCDL.AE_LINE_NUM                        AE_LINE_NUM                  
,       CCDL.SLA_CODE_COMBINATION_ID            CCDL_SLA_CODE_COMBINATION_ID 
,       CCD.TRANSACTION_NUMBER    
,       CCGD.CUSTOMER_ID
,       CCOV.COST_ORG_NAME 
,       CCGD.ACCOUNTING_LINE_TYPE
FROM   CST_COST_DISTRIBUTION_LINES    CCDL
,      CST_COST_DISTRIBUTIONS         CCD 
,      CST_COST_ELEMENTS_VL           CCEV
,      CST_COGS_DETAILS               CCGD
,      CST_COST_BOOKS_B               BK   
,       CST_PERIOD_STATUSES            CPS
,       PERIOD_PARAM                   PERIOD_PARAM 
,      CST_COST_ORGS_V                CCOV 

WHERE  1 = 1
AND    ccdl.COST_ELEMENT_ID   = ccev.COST_ELEMENT_ID  
AND    CCDL.DISTRIBUTION_ID = CCD.DISTRIBUTION_ID  
AND     CCDL.DISTRIBUTION_ID      = CCGD.DISTRIBUTION_ID
AND     CCDL.DISTRIBUTION_LINE_ID = CCGD.DISTRIBUTION_LINE_ID
AND     CCD.COST_BOOK_ID             =          BK.COST_BOOK_ID
AND     BK.COST_BOOK_CODE            = ('Primary Cost Book')
AND     CCD.COST_ORGANIZATION_ID     = CCOV.COST_ORG_ID
--AND    CCGD.ACCOUNTING_LINE_TYPE = 'COST_OF_GOODS_SOLD'
AND    ccev.COST_ELEMENT_TYPE  = 'RESOURCE'
AND    CCD.COST_BOOK_ID         = CPS.COST_BOOK_ID
AND    CCD.COST_ORGANIZATION_ID = CPS.COST_ORG_ID 
AND    CCD.GL_DATE                                    >= CPS.START_DATE
AND    CCD.GL_DATE                                    < CPS.END_DATE + 1
AND    CPS.PERIOD_NAME             IN PERIOD_PARAM.PERIOD_NAME
AND    CCOV.COST_ORG_NAME       = (:P_COST_ORG_NAME)       -- 300000005646377
AND EXISTS   ( SELECT 1     
               FROM  XLA_AE_HEADERS XAH 
			   ,      XLA_AE_LINES   XAL
               ,      GL_LEDGERS     GLD 
               ,      GL_PERIODS               GLP 
               ,      PERIOD_PARAM             PERIOD_PARAM
               WHERE 1 = 1
               AND    CCDL.AE_HEADER_ID   =    XAL.AE_HEADER_ID 
		       AND    CCDL.AE_LINE_NUM    =    XAL.AE_LINE_NUM 
               AND    CCDL.AE_HEADER_ID   =    XAH.AE_HEADER_ID 
               AND    xah.LEDGER_ID       =    gld.LEDGER_ID
               AND    XAH.PERIOD_NAME          =  GLP.PERIOD_NAME
               AND    GLP.PERIOD_SET_NAME      = 'XXKD_ACCT_CALEN'
               AND    GLP.PERIOD_TYPE          = 'MONTH2380721164'               
               AND    XAL.ACCOUNTING_CLASS_CODE IN ('COST_OF_GOODS_SOLD',
                                                      'DEFERRED_COGS',
                                                      'DEFERRED_COST_OF_GOODS_SOLD',
                                                      'INTERCOMPANY_COGS')                
			  -- AND    xah.LEDGER_ID       =    300000003031029
               AND ( GLD.NAME  IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))      --        300000003031029   	         

              AND    XAH.PERIOD_NAME  IN PERIOD_PARAM.PERIOD_NAME   
 )
UNION ALL 
SELECT  ccd.DISTRIBUTION_ID  
,       CCDL.DISTRIBUTION_LINE_ID 
,       NULL                                  MATERIAL_COST_ELEMENT_TYPE
,       NULL                                  OVERHEAD_COST_ELEMENT_TYPE
,       NULL                                  RESOURCE_COST_ELEMENT_TYPE
,       ccev.COST_ELEMENT_TYPE                PROFIT_IN_INVENTORY_COST_ELEMENT_TYPE

,       NULL                                  MATERIAL_LEDGER_AMOUNT  
,       NULL                                  MATERIAL_COGS_AMOUNT
,       NULL                                  OVERHEAD_LEDGER_AMOUNT  
,       NULL                                  OVERHEAD_COGS_AMOUNT
,       NULL                                  RESOURCE_LEDGER_AMOUNT  
,       NULL                                  RESOURCE_COGS_AMOUNT
,       nvl (   CCDL.LEDGER_AMOUNT , 0   )    PROFIT_IN_INV_LEDGER_AMOUNT  
,       nvl (    CCGD.COGS_AMOUNT , 0   )     PROFIT_IN_INV_COGS_AMOUNT
,       CCGD.COGS_TYPE 
,       CCGD.DOO_FULLFILL_LINE_ID 
,       CCD.COST_BOOK_ID
,       CCD.COST_ORGANIZATION_ID
,       CCD.LEDGER_ID  
,       CCD.DEP_TRXN_ID   
,       CCD.TRANSACTION_ID
,       CCD.EVENT_TYPE_CODE
,       CCD.GL_DATE
,       CCGD.DOO_ORDER_TYPE 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'SO'
		     THEN  CCGD.DOO_ORDER_NUMBER
        END SO_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'TO'
             THEN  CCGD.DOO_ORDER_NUMBER
        END TRANSFER_ORDER_NUMBER 
,       CASE WHEN CCGD.DOO_ORDER_TYPE = 'RMA'
             THEN  CCGD.DOO_ORDER_NUMBER
        END RMA_ORDER_NUMBER
,       CPS.PERIOD_NAME        
,       CCD.COST_TRANSACTION_TYPE      DIST_COST_TRANSACTION_TYPE     
,       CCD.ADDITIONAL_PROCESSING_CODE DIST_ADDITIONAL_PROCESSING_CODE
,       CCDL.AE_HEADER_ID                       AE_HEADER_ID                 
,       CCDL.AE_LINE_NUM                        AE_LINE_NUM                  
,       CCDL.SLA_CODE_COMBINATION_ID            CCDL_SLA_CODE_COMBINATION_ID 
,       CCD.TRANSACTION_NUMBER    
,       CCGD.CUSTOMER_ID
,       CCOV.COST_ORG_NAME 
,       CCGD.ACCOUNTING_LINE_TYPE
FROM    CST_COST_DISTRIBUTION_LINES    CCDL
,       CST_COST_DISTRIBUTIONS         CCD 
,       CST_COST_ELEMENTS_VL           CCEV
,       CST_COGS_DETAILS               CCGD
,       CST_COST_BOOKS_B               BK  
,       CST_PERIOD_STATUSES            CPS
,       PERIOD_PARAM                   PERIOD_PARAM 
,      CST_COST_ORGS_V                CCOV 
WHERE  1 = 1
AND    ccdl.COST_ELEMENT_ID   = ccev.COST_ELEMENT_ID  
AND    CCDL.DISTRIBUTION_ID = CCD.DISTRIBUTION_ID  
AND     CCDL.DISTRIBUTION_ID      = CCGD.DISTRIBUTION_ID
AND     CCDL.DISTRIBUTION_LINE_ID = CCGD.DISTRIBUTION_LINE_ID
AND     CCD.COST_BOOK_ID             =          BK.COST_BOOK_ID
AND     BK.COST_BOOK_CODE            = ('Primary Cost Book')
AND     CCD.COST_ORGANIZATION_ID     = CCOV.COST_ORG_ID

--AND    CCGD.ACCOUNTING_LINE_TYPE = 'COST_OF_GOODS_SOLD'
AND    ccev.COST_ELEMENT_TYPE  = 'PROFIT_IN_INVENTORY'
AND    CCD.COST_BOOK_ID         = CPS.COST_BOOK_ID
AND    CCD.COST_ORGANIZATION_ID = CPS.COST_ORG_ID 
AND    CCD.GL_DATE                                    >= CPS.START_DATE
AND    CCD.GL_DATE                                    < CPS.END_DATE + 1
AND    CPS.PERIOD_NAME             IN PERIOD_PARAM.PERIOD_NAME
AND    CCOV.COST_ORG_NAME      = (:P_COST_ORG_NAME)         --300000005646377
AND EXISTS   ( SELECT 1     
               FROM  XLA_AE_HEADERS XAH 
			   ,      XLA_AE_LINES   XAL
               ,      GL_LEDGERS     GLD 
               ,      GL_PERIODS               GLP 
               ,      PERIOD_PARAM             PERIOD_PARAM
               WHERE 1 = 1
               AND    CCDL.AE_HEADER_ID   =    XAL.AE_HEADER_ID 
		       AND    CCDL.AE_LINE_NUM    =    XAL.AE_LINE_NUM 
               AND    CCDL.AE_HEADER_ID   =    XAH.AE_HEADER_ID 
               AND    xah.LEDGER_ID       =    gld.LEDGER_ID
               AND    XAH.PERIOD_NAME          =  GLP.PERIOD_NAME
               AND    GLP.PERIOD_SET_NAME      = 'XXKD_ACCT_CALEN'
               AND    GLP.PERIOD_TYPE          = 'MONTH2380721164'               
               AND    XAL.ACCOUNTING_CLASS_CODE IN ('COST_OF_GOODS_SOLD',
                                                      'DEFERRED_COGS',
                                                      'DEFERRED_COST_OF_GOODS_SOLD',
                                                      'INTERCOMPANY_COGS')                
               AND ( GLD.NAME IN ( :P_LEDGER_NAME )
                                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))      --        300000003031029                             	
                  AND    XAH.PERIOD_NAME  IN PERIOD_PARAM.PERIOD_NAME
 ) 

 
 
 
 
 )   CCDL_DATA
 
 WHERE 1 = 1 
/*
GROUP BY CCDL_DATA.DISTRIBUTION_ID
,        CCDL_DATA.DOO_FULLFILL_LINE_ID 
,        CCDL_DATA.COST_BOOK_ID
,        CCDL_DATA.COST_ORGANIZATION_ID
,        CCDL_DATA.LEDGER_ID  
,        CCDL_DATA.DEP_TRXN_ID  
,        CCDL_DATA.TRANSACTION_ID
,        CCDL_DATA.EVENT_TYPE_CODE
,        CCDL_DATA.GL_DATE
,        CCDL_DATA.DOO_ORDER_TYPE 
,        CCDL_DATA.SO_ORDER_NUMBER 
,        CCDL_DATA.TRANSFER_ORDER_NUMBER 
,        CCDL_DATA.RMA_ORDER_NUMBER
,        CCDL_DATA.PERIOD_NAME   
,        CCDL_DATA.DIST_COST_TRANSACTION_TYPE     
,        CCDL_DATA.DIST_ADDITIONAL_PROCESSING_CODE
,        CCDL_DATA.AE_HEADER_ID                 
,        CCDL_DATA.AE_LINE_NUM                  
,        CCDL_DATA.CCDL_SLA_CODE_COMBINATION_ID 
,        CCDL_DATA.TRANSACTION_NUMBER 
,        CCDL_DATA.CUSTOMER_ID
,        CCDL_DATA.COST_ORG_NAME
,        CCDL_DATA.ACCOUNTING_LINE_TYPE
)

*/
)
 , QXLA AS
(
SELECT  XAL.GL_SL_LINK_ID   
,        XAL.GL_SL_LINK_TABLE 
,        XAH.AE_HEADER_ID
,        XAL.AE_LINE_NUM                                          
,        XTE.SOURCE_ID_INT_1    XTE_SOURCE_ID_INT_1              
,        XTE.TRANSACTION_NUMBER XTE_TRANSACTION_NUMBER            
,        XAH.APPLICATION_ID     XAH_APPLICATION_ID               
,        XAH.EVENT_TYPE_CODE                                      
,        XAL.ACCOUNTING_CLASS_CODE                                
,        FLV.MEANING ACCOUNTING_CLASS_MEANING                    
,        XAL.BUSINESS_CLASS_CODE                                  
,        XAL.PARTY_ID            XAL_PARTY_ID                    
,        XAL.PARTY_SITE_ID       XAL_PARTY_SITE_ID                
,        XAL.CODE_COMBINATION_ID XAL_CODE_COMBINATION_ID
,        XAL.APPLICATION_ID XAL_APPLICATION_ID 
,        XAH.LEDGER_ID                        
,        XAH.PERIOD_NAME                       
,        XAH.ACCOUNTING_ENTRY_TYPE_CODE
FROM     XLA_AE_HEADERS XAH 
,        XLA_AE_LINES   XAL
,        XLA_TRANSACTION_ENTITIES XTE 
,        GL_LEDGERS               GLD 
,        GL_PERIODS               GLP 
,        FND_LOOKUP_VALUES_VL     FLV
,        PERIOD_PARAM             PERIOD_PARAM
WHERE    1                = 1
AND     XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
AND     XAH.LEDGER_ID    = GLD.LEDGER_ID
AND     (
                GLD.NAME IN ( :P_LEDGER_NAME )
                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
AND     GLD.LEDGER_CATEGORY_CODE = 'PRIMARY'
AND     XAH.PERIOD_NAME          = GLP.PERIOD_NAME
AND     GLP.PERIOD_SET_NAME      = 'XXKD_ACCT_CALEN'
AND     GLP.PERIOD_TYPE          = 'MONTH2380721164'
AND     XAL.APPLICATION_ID = XAH.APPLICATION_ID
AND     GLP.PERIOD_NAME IN PERIOD_PARAM.PERIOD_NAME
AND     XTE.ENTITY_ID = XAH.ENTITY_ID
AND     XAL.APPLICATION_ID                                                    = XAH.APPLICATION_ID
AND     XAL.ACCOUNTING_CLASS_CODE                                             = FLV.LOOKUP_CODE (+)
AND     FLV.LOOKUP_TYPE (                                                  +) = 'XLA_ACCOUNTING_CLASS'
AND     XAL.ACCOUNTING_CLASS_CODE IN ('COST_OF_GOODS_SOLD',
                                      'DEFERRED_COGS',
                                      'DEFERRED_COST_OF_GOODS_SOLD',
                                      'INTERCOMPANY_COGS')
) 

,  FROM_SLA_SL_LINK AS
      (
SELECT  LEDGER_ID           
,        LEDGER_NAME         
,        PERIOD_NAME          
,        PERIOD_YEAR          
,        PERIOD_NUM           
,        EFFECTIVE_GL_DATE           
,        CODE_COMBINATION_ID  
,        JE_HEADER_ID         
,        JE_LINE_NUM          
,        JE_CREATION_DATE     
,        JE_NAME              
,        JE_DOC_NUM_OLD       
,        JE_DOC_NUM           
,        JE_CURRENCY          
,        JE_SOURCE            
,        JE_CATEGORY          
,        JE_FROM_SLA_FLAG     
,        JE_LINE_DESC         
,        GL_CREATION_DATE     
,        GL_SL_LINK_ID        
,        GL_SL_LINK_TABLE     
,        GRP
FROM  (
SELECT  GLD.LEDGER_ID                                     
,        GLD.NAME LEDGER_NAME                              
,        GLP.PERIOD_NAME                                   
,        GLP.PERIOD_YEAR                                   
,        GLP.PERIOD_NUM                                    
,        GLP.PERIOD_TYPE                                   
,        JL.EFFECTIVE_DATE EFFECTIVE_GL_DATE                        
,        JL.CODE_COMBINATION_ID                            
,        JH.JE_HEADER_ID                                   
,        JL.JE_LINE_NUM                                    
,        JH.CREATION_DATE          JE_CREATION_DATE        
,        JH.NAME                   JE_NAME                 
,        JH.DOC_SEQUENCE_VALUE     JE_DOC_NUM_OLD          
,        JH.POSTING_ACCT_SEQ_VALUE JE_DOC_NUM              
,        JH.CURRENCY_CODE          JE_CURRENCY             
,        JH.JE_SOURCE                                      
,        JH.JE_CATEGORY                                    
,        NVL ( JH.JE_FROM_SLA_FLAG,  'N') JE_FROM_SLA_FLAG  
,        JL.DESCRIPTION                  JE_LINE_DESC      
,        JL.CREATION_DATE                GL_CREATION_DATE  
,        GIR.GL_SL_LINK_ID                                 
,        GIR.GL_SL_LINK_TABLE                              
,        'FROM_SLA_SL_LINK_Y' GRP
FROM     GL_LEDGERS           GLD  
,        GL_PERIODS           GLP  
,        GL_JE_HEADERS        JH   
,        GL_JE_LINES          JL   
,        GL_IMPORT_REFERENCES GIR  
,        PERIOD_PARAM         PERIOD_PARAM
WHERE   1                   = 1
AND     GLD.LEDGER_ID       = JH.LEDGER_ID
AND     JH.JE_HEADER_ID     = JL.JE_HEADER_ID
AND     GLD.PERIOD_SET_NAME = GLP.PERIOD_SET_NAME
AND     JH.PERIOD_NAME      = GLP.PERIOD_NAME
AND     GLP.PERIOD_SET_NAME = 'XXKD_ACCT_CALEN'
AND     GLP.PERIOD_TYPE     = 'MONTH2380721164'
AND     GLP.PERIOD_NAME IN PERIOD_PARAM.PERIOD_NAME
AND     GLD.LEDGER_CATEGORY_CODE    = 'PRIMARY'
AND     JH.STATUS                   = 'P'
AND     JH.ACTUAL_FLAG              = 'A'
AND     JL.JE_HEADER_ID             = GIR.JE_HEADER_ID
AND     JL.JE_LINE_NUM              = GIR.JE_LINE_NUM
AND     JL.GL_SL_LINK_ID            = GIR.GL_SL_LINK_ID
AND     JL.GL_SL_LINK_TABLE         = GIR.GL_SL_LINK_TABLE
AND     NVL(JH.CURRENCY_CODE ,'XX') != 'STAT'
AND     (
                GLD.NAME IN ( :P_LEDGER_NAME )
                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
AND     NVL ( JH.JE_FROM_SLA_FLAG , 'N') = 'Y'
AND     JH.JE_SOURCE                    = 'Cost Accounting'
AND     JL.GL_SL_LINK_ID IS NOT NULL
                
UNION ALL
                
SELECT  GLD.LEDGER_ID                                     
,        GLD.NAME LEDGER_NAME                              
,        GLP.PERIOD_NAME                                   
,        GLP.PERIOD_YEAR                                   
,        GLP.PERIOD_NUM                                    
,        GLP.PERIOD_TYPE                                   
,        JL.EFFECTIVE_DATE EFFECTIVE_GL_DATE                          
,        JL.CODE_COMBINATION_ID                            
,        JH.JE_HEADER_ID                                   
,        JL.JE_LINE_NUM                                    
,        JH.CREATION_DATE          JE_CREATION_DATE        
,        JH.NAME                   JE_NAME                 
,        JH.DOC_SEQUENCE_VALUE     JE_DOC_NUM_OLD          
,        JH.POSTING_ACCT_SEQ_VALUE JE_DOC_NUM              
,        JH.CURRENCY_CODE          JE_CURRENCY             
,        JH.JE_SOURCE                                      
,        JH.JE_CATEGORY                                    
,        NVL ( JH.JE_FROM_SLA_FLAG  , 'N') JE_FROM_SLA_FLAG  
,        JL.DESCRIPTION                  JE_LINE_DESC      
,        JL.CREATION_DATE                GL_CREATION_DATE  
,        GIR.GL_SL_LINK_ID                                 
,        GIR.GL_SL_LINK_TABLE                              
,        'FROM_SLA_SL_LINK_N' GRP
FROM     GL_LEDGERS           GLD  
,        GL_PERIODS           GLP  
,        GL_JE_HEADERS        JH   
,        GL_JE_LINES          JL   
,        GL_IMPORT_REFERENCES GIR  
,        PERIOD_PARAM         PERIOD_PARAM
WHERE   1                   = 1
AND     GLD.LEDGER_ID       = JH.LEDGER_ID
AND     JH.JE_HEADER_ID     = JL.JE_HEADER_ID
AND     GLD.PERIOD_SET_NAME = GLP.PERIOD_SET_NAME
AND     JH.PERIOD_NAME      = GLP.PERIOD_NAME
AND     GLP.PERIOD_SET_NAME = 'XXKD_ACCT_CALEN'
AND     GLP.PERIOD_TYPE     = 'MONTH2380721164'
AND     GLP.PERIOD_NAME IN PERIOD_PARAM.PERIOD_NAME
AND     GLD.LEDGER_CATEGORY_CODE    = 'PRIMARY'
AND     JH.STATUS                   = 'P'
AND     JH.ACTUAL_FLAG              = 'A'
AND     JL.JE_HEADER_ID             = GIR.JE_HEADER_ID
AND     JL.JE_LINE_NUM              = GIR.JE_LINE_NUM
AND     NVL(JH.CURRENCY_CODE , 'XX') != 'STAT'
AND     (
                GLD.NAME IN ( :P_LEDGER_NAME )
                OR 'ALL' IN ( :P_LEDGER_NAME || 'ALL'))
AND     NVL ( JH.JE_FROM_SLA_FLAG , 'N') = 'Y'
AND     JL.GL_SL_LINK_ID IS NULL
AND     JH.JE_SOURCE = 'Cost Accounting' ) GL_ALL 
)

,    GL_SEGMENTS_DESC AS
(
SELECT FFVL.DESCRIPTION    GL_SEGMENT_DESCRIPTION 
,      FFVL.FLEX_VALUE     GL_SEGMENT_CODE        
,      FFVL.VALUE_CATEGORY GL_SEGMENT_VALUE_CATEGORY
FROM   FND_FLEX_VALUES_VL FFVL
WHERE  1 = 1
AND    FFVL.VALUE_CATEGORY IN ( 'XXKD_GL_Company',
                             'XXKD_GL_Account',
                             'XXKD_GL_Department')
AND     FFVL.ENABLED_FLAG = 'Y'
AND     (  SYSDATE) >= NVL(FFVL.START_DATE_ACTIVE, TRUNC(SYSDATE))
AND     TRUNC(SYSDATE)   <= NVL (FFVL.END_DATE_ACTIVE, TRUNC(SYSDATE))
)
-------------------

SELECT CCDL_WITH.*

,      GLD.NAME LEDGER_NAME   
,      CIT.TRANSACTION_QTY CIT_TRANSACTION_QTY    
,      ITM.ITEM_NUMBER                                             
,      ITM.DESCRIPTION ITEM_DESCRIPTION
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'  THEN  NVL ( CT.QUANTITY, 0 )  END  QNTY_IN_MATERIAL
,      CT.QUANTITY                 
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   THEN   CT.TXN_SOURCE_DOC_NUMBER    END  TXN_SOURCE_DOC_NUMBER_IN_MATERIAL 
,      CT.TXN_SOURCE_DOC_NUMBER     
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   THEN   CIT.SUBINVENTORY_CODE    END  SUBINVENTORY_CODE_IN_MATERIAL 
,      CIT.SUBINVENTORY_CODE                                    
,      CIT.TRANSFER_SUBINVENTORY_CODE                            
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'  THEN  NVL (CIT.TRANSACTION_QTY , 0 )  END  CST_TRX_QTY_IN_MATERIAL
,      CIT.TRANSACTION_QTY          CST_TRX_QTY    
,      CT.TXN_SOURCE_REF_DOC_NUMBER CT_TXN_SOURCE_REF_DOC_NUMBER 
,      CIT.TXN_SOURCE_DOC_TYPE
-------------  new
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   THEN    CT.CST_INV_TRANSACTION_ID    END  CST_INV_TRANSACTION_ID_IN_MATERIAL  
,      CT.CST_INV_TRANSACTION_ID                                 
,      CT.TRANSFER_CST_INV_TXN_ID        
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   THEN   CT.WSH_DELIVERY_DETAIL_ID    END  WSH_DELIVERY_DETAIL_ID_IN_MATERIAL
,      CT.WSH_DELIVERY_DETAIL_ID     
,      CASE WHEN MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   THEN   CT.DOO_FULLFILL_LINE_ID     END  DOO_FULLFILL_LINE_ID_IN_MATERIAL


--,      CT.DOO_FULLFILL_LINE_ID   

,      CT.TXN_SOURCE_REF_DOC_TYPE                                  
,      CIT.EXTERNAL_SYSTEM_REFERENCE CIT_EXTERNAL_SYSTEM_REFERENCE 
,      CIT.EXTERNAL_SYSTEM_REF_ID    CIT_INV_TRX_IDIN_FUSION_REF
,      CIT.DOO_SPLIT_FULFILL_LINE_ID CIT_DOO_SPLIT_FULFILL_LINE_ID   
,      CIT.TRANSACTION_DATE          CIT_TRANSACTION_DATE   
,      DFLA.HEADER_ID                DFLA_HEADER_ID
,      DFLA.LINE_ID                  DFLA_LINE_ID
,      DFLA.FULFILL_LINE_ID          DFLA_FULFILL_LINE_ID




,      CASE WHEN  QXLA.ACCOUNTING_CLASS_CODE     IN    (   'COST_OF_GOODS_SOLD' , 'INTERCOMPANY_COGS')
			THEN     'COGS_LINE'
			WHEN  QXLA.ACCOUNTING_CLASS_CODE   IN  (  'DEFERRED_COST_OF_GOODS_SOLD',   'DEFERRED_COGS')
			THEN     'DCOGS_LINE'
			END COGS_DCOGS_LINE_CALC
			
,      CASE WHEN DFLA.FULFILL_LINE_ID IS NOT NULL  
				AND QXLA.ACCOUNTING_CLASS_CODE   = 'COST_OF_GOODS_SOLD'
				-- ROW_NUMBER ()  OVER ( PARTITION BY  DFLA.FULFILL_LINE_ID    ORDER BY  DFLA.HEADER_ID  ,DFLA.LINE_ID ,  DFLA.FULFILL_LINE_ID   )  = 1
            THEN NVL (   DFLA.FULFILLED_QTY, 0 )     
       END           FULFILLED_QTY_COST_OF_GOODS_SOLD
       
 ,      CASE WHEN DFLA.FULFILL_LINE_ID IS NOT NULL  
				AND  QXLA.ACCOUNTING_CLASS_CODE    = 'DEFERRED_COGS'
				-- ROW_NUMBER ()  OVER ( PARTITION BY  DFLA.FULFILL_LINE_ID    ORDER BY  DFLA.HEADER_ID  ,DFLA.LINE_ID ,  DFLA.FULFILL_LINE_ID   )  = 1
            THEN NVL (   DFLA.FULFILLED_QTY, 0 )     
       END           FULFILLED_QTY_DEFERRED_COGS    
       
 ,      CASE WHEN DFLA.FULFILL_LINE_ID IS NOT NULL  
				AND QXLA.ACCOUNTING_CLASS_CODE   =  'DEFERRED_COST_OF_GOODS_SOLD'
				-- ROW_NUMBER ()  OVER ( PARTITION BY  DFLA.FULFILL_LINE_ID    ORDER BY  DFLA.HEADER_ID  ,DFLA.LINE_ID ,  DFLA.FULFILL_LINE_ID   )  = 1
            THEN NVL (   DFLA.FULFILLED_QTY, 0 )     
       END           FULFILLED_QTY_DEFERRED_COST_OF_GOODS_SOLD
 
 ,      CASE WHEN DFLA.FULFILL_LINE_ID IS NOT NULL  
				AND  QXLA.ACCOUNTING_CLASS_CODE    =  'INTERCOMPANY_COGS'
				-- ROW_NUMBER ()  OVER ( PARTITION BY  DFLA.FULFILL_LINE_ID    ORDER BY  DFLA.HEADER_ID  ,DFLA.LINE_ID ,  DFLA.FULFILL_LINE_ID   )  = 1
            THEN NVL (   DFLA.FULFILLED_QTY, 0 )     
       END           FULFILLED_QTY_INTERCOMPANY_COGS     
       
,      DFLA.FULFILLMENT_DATE
,      DLA.LINE_NUMBER   ORDER_LINE_NUMBER
,      DLA.DISPLAY_LINE_NUMBER   ORDER_DISPLAY_LINE_NUMBER
,      DFLA.FULFILL_LINE_NUMBER

,      DFLA.FULFILLED_QTY

,      DFLA.SHIPPED_QTY
-----
,      QXLA.GL_SL_LINK_ID              
,      QXLA.GL_SL_LINK_TABLE           
,      QXLA.XTE_TRANSACTION_NUMBER     
,      QXLA.ACCOUNTING_CLASS_CODE      
,      QXLA.ACCOUNTING_CLASS_MEANING   
,      QXLA.BUSINESS_CLASS_CODE        
,      QXLA.XAL_PARTY_ID               
,      QXLA.XAL_PARTY_SITE_ID          
,      QXLA.ACCOUNTING_ENTRY_TYPE_CODE 
/*
,      FROM_SLA_SL_LINK.PERIOD_YEAR    
,      FROM_SLA_SL_LINK.PERIOD_NUM     
,      FROM_SLA_SL_LINK.EFFECTIVE_GL_DATE    EFFECTIVE_GL_DATE 
,      FROM_SLA_SL_LINK.JE_HEADER_ID    
,      FROM_SLA_SL_LINK.JE_LINE_NUM      
,      FROM_SLA_SL_LINK.JE_CREATION_DATE 
,      FROM_SLA_SL_LINK.JE_NAME          
,      FROM_SLA_SL_LINK.JE_DOC_NUM       
,      FROM_SLA_SL_LINK.JE_CURRENCY      
,      FROM_SLA_SL_LINK.JE_SOURCE        
,      FROM_SLA_SL_LINK.JE_CATEGORY      
,      FROM_SLA_SL_LINK.JE_FROM_SLA_FLAG 
*/
,      GCC.SEGMENT1 || '.' || 
       GCC.SEGMENT2 || '.' || 
       GCC.SEGMENT3 || '.' || 
       GCC.SEGMENT4 || '.' || 
       GCC.SEGMENT5 || '.' || 
       GCC.SEGMENT6 || '.' || 
       GCC.SEGMENT7 || '.' || 
       GCC.SEGMENT8 || '.' || 
       GCC.SEGMENT9 || '.' || 
       GCC.SEGMENT10 || '.' || 
       GCC.SEGMENT11 CONCATENATED_SEGMENTS  
,      GCC.SEGMENT1    GL_COMPANY_CODE       
,      GL_COMPANY_DESC.GL_SEGMENT_DESCRIPTION     GL_COMPANY_DESCRIPTION
,      GCC.SEGMENT2                                 GL_ACCOUNT_CODE        
,      GL_ACCOUNT_DESC.GL_SEGMENT_DESCRIPTION  GL_ACCOUNT_DESCRIPTION 
,      GCC.SEGMENT3                                 GL_DEPARTMENT_CODE        
,      GL_DEPARTMENT_DESC.GL_SEGMENT_DESCRIPTION     GL_DEPARTMENT_DESCRIPTION 
,      HCU.ACCOUNT_NUMBER  
,      HCU.ACCOUNT_NAME   
,      HCU.CUSTOMER_CLASS_CODE 
,      HZP.PARTY_NUMBER
,      HZP.PARTY_NAME
,      AVG (  DFLA.SHIPPED_QTY )   OVER ( PARTITION BY DFLA.FULFILL_LINE_ID )   CNT 
FROM   CCDL_WITH                      CCDL_WITH

,      CST_TRANSACTIONS               CT
,      CST_INV_TRANSACTIONS           CIT
,      GL_LEDGERS                     GLD
,      EGP_SYSTEM_ITEMS_VL            ITM  

,      DOO_FULFILL_LINES_ALL          DFLA
,      DOO_LINES_ALL                  DLA
,      HZ_CUST_ACCOUNTS               HCU  

,      QXLA                           QXLA
--,      FROM_SLA_SL_LINK               FROM_SLA_SL_LINK
,      GL_CODE_COMBINATIONS           GCC   
,      GL_SEGMENTS_DESC               GL_COMPANY_DESC 
,      GL_SEGMENTS_DESC               GL_ACCOUNT_DESC  
,      GL_SEGMENTS_DESC               GL_DEPARTMENT_DESC 
,      HZ_PARTIES                     HZP  
,      INV_ORGANIZATION_DEFINITIONS_V DOO_IOP

WHERE  1 = 1

AND    CASE WHEN   CCDL_WITH.EVENT_TYPE_CODE  = 'COGS_RECOGNITION'
	         THEN   CCDL_WITH.DEP_TRXN_ID     
	         ELSE   CCDL_WITH.TRANSACTION_ID
	   END     = CT.TRANSACTION_ID (+)
AND    CT.CST_INV_TRANSACTION_ID       = CIT.CST_INV_TRANSACTION_ID (+) 
AND    CCDL_WITH.LEDGER_ID             = GLD.LEDGER_ID
AND    CT.INVENTORY_ITEM_ID            = ITM.INVENTORY_ITEM_ID ( +)
AND    CT.INVENTORY_ORG_ID             = ITM.ORGANIZATION_ID (+)
AND     DFLA.LINE_ID         = DLA.LINE_ID (+)
AND    CASE WHEN  MATERIAL_COST_ELEMENT_TYPE  = 'MATERIAL'   
			THEN  CIT.DOO_FULLFILL_LINE_ID
	   END 		 = DFLA.FULFILL_LINE_ID (+)

AND    NVL ( CCDL_WITH.CUSTOMER_ID,   DFLA.BILL_TO_CUSTOMER_ID ) = HCU.CUST_ACCOUNT_ID ( +)
/*
AND    CASE  WHEN  CCDL_WITH.DOO_ORDER_TYPE IN ( 'SO', 'RMA' )              
            	 THEN    DFLA.BILL_TO_CUSTOMER_ID 
             WHEN CCDL_WITH.DOO_ORDER_TYPE = 'TO'
                 THEN  CCDL_WITH.CUSTOMER_ID
       END                 = HCU.CUST_ACCOUNT_ID ( +)
       */

AND     CCDL_WITH.AE_HEADER_ID = QXLA.AE_HEADER_ID
AND     CCDL_WITH.AE_LINE_NUM = QXLA.AE_LINE_NUM  
--AND     QXLA.GL_SL_LINK_ID     = FROM_SLA_SL_LINK.GL_SL_LINK_ID
--AND     QXLA.GL_SL_LINK_TABLE = FROM_SLA_SL_LINK.GL_SL_LINK_TABLE
--AND     QXLA.PERIOD_NAME    = FROM_SLA_SL_LINK.PERIOD_NAME
AND     CCDL_WITH.CCDL_SLA_CODE_COMBINATION_ID               = GCC.CODE_COMBINATION_ID 
AND     GCC.SEGMENT1                              = GL_COMPANY_DESC.GL_SEGMENT_CODE
AND     GL_company_DESC.GL_SEGMENT_VALUE_CATEGORY = 'XXKD_GL_Company'
AND     GCC.SEGMENT2                              = GL_ACCOUNT_DESC.GL_SEGMENT_CODE                     
AND     GL_ACCOUNT_DESC.GL_SEGMENT_VALUE_CATEGORY = 'XXKD_GL_Account'
AND     GCC.SEGMENT3                             = GL_DEPARTMENT_DESC.GL_SEGMENT_CODE
AND     GL_DEPARTMENT_DESC.GL_SEGMENT_VALUE_CATEGORY = 'XXKD_GL_Department'
AND     HCU.PARTY_ID        = HZP.PARTY_ID (+)
AND     DFLA.FULFILL_ORG_ID = DOO_IOP.ORGANIZATION_ID (+)

--  AND DISTRIBUTION_ID IN (  94773740, 94773363)

)   FOR_SUM_LAYER
WHERE 1 = 1
AND   FOR_SUM_LAYER.COGS_DCOGS_LINE_CALC   = 'COGS_LINE'
--AND   FOR_SUM_LAYER.DOO_FULLFILL_LINE_ID =  300000861437158
--AND   FOR_SUM_LAYER.SO_ORDER_NUMBER	= '1022423'

GROUP BY FOR_SUM_LAYER.DOO_FULLFILL_LINE_ID
,      FOR_SUM_LAYER.EVENT_TYPE_CODE	
,      FOR_SUM_LAYER.GL_DATE	
,      FOR_SUM_LAYER.DOO_ORDER_TYPE	
,      FOR_SUM_LAYER.SO_ORDER_NUMBER	
,      FOR_SUM_LAYER.TRANSFER_ORDER_NUMBER	
,      FOR_SUM_LAYER.RMA_ORDER_NUMBER	
,      FOR_SUM_LAYER.PERIOD_NAME
,      FOR_SUM_LAYER.DIST_ADDITIONAL_PROCESSING_CODE
,      FOR_SUM_LAYER.TRANSACTION_NUMBER
,      FOR_SUM_LAYER.COST_ORG_NAME	
,      FOR_SUM_LAYER.ACCOUNTING_LINE_TYPE	
,      FOR_SUM_LAYER.LEDGER_NAME
,      FOR_SUM_LAYER.ITEM_NUMBER	
,      FOR_SUM_LAYER.ITEM_DESCRIPTION
,      FOR_SUM_LAYER.COGS_DCOGS_LINE_CALC
,      NVL ( FOR_SUM_LAYER.FULFILLED_QTY	, 0 )
,      NVL (   FOR_SUM_LAYER.SHIPPED_QTY , 0 )   

,       FOR_SUM_LAYER.FULFILLMENT_DATE 
,       FOR_SUM_LAYER.ORDER_LINE_NUMBER	 
,        FOR_SUM_LAYER.ORDER_DISPLAY_LINE_NUMBER	 
,       FOR_SUM_LAYER.FULFILL_LINE_NUMBER	  
,      FOR_SUM_LAYER.ACCOUNT_NUMBER

/*
,      FOR_SUM_LAYER.EVENT_TYPE_CODE	
,      FOR_SUM_LAYER.GL_DATE	
,      FOR_SUM_LAYER.DOO_ORDER_TYPE	
,      FOR_SUM_LAYER.SO_ORDER_NUMBER	
,      FOR_SUM_LAYER.TRANSFER_ORDER_NUMBER	
,      FOR_SUM_LAYER.RMA_ORDER_NUMBER	
,      FOR_SUM_LAYER.PERIOD_NAME
,      FOR_SUM_LAYER.DIST_ADDITIONAL_PROCESSING_CODE
,      FOR_SUM_LAYER.TRANSACTION_NUMBER
,      FOR_SUM_LAYER.COST_ORG_NAME	
,      FOR_SUM_LAYER.ACCOUNTING_LINE_TYPE	
,      FOR_SUM_LAYER.LEDGER_NAME
,      FOR_SUM_LAYER.ITEM_NUMBER	
,      FOR_SUM_LAYER.ITEM_DESCRIPTION
,      FOR_SUM_LAYER.COGS_DCOGS_LINE_CALC 
*/
--,      FOR_SUM_LAYER.FULFILLMENT_DATE
--,      FOR_SUM_LAYER.ORDER_LINE_NUMBER	
--,      FOR_SUM_LAYER.ORDER_DISPLAY_LINE_NUMBER	
--,      FOR_SUM_LAYER.FULFILL_LINE_NUMBER	
