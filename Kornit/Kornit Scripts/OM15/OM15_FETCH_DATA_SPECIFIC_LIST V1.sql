-- --OM15_FETCH_DATA_SPECIFIC_LIST_DM.sql
with rep_params AS
(
SELECT
	NVL(:P_PRICE_LIST_NAME,'')		P_PRICE_LIST_NAME,
	NVL(:P_NEW_ONLY,'Y')			P_NEW_ONLY,
	NVL(:P_IS_AUTOMATED,'Y')		P_IS_AUTOMATED,
	NVL(:P_MARKUP,'')				P_MARKUP,
	NVL(:P_INCLUDED_ITEM_STATUSES,'') P_INCLUDED_ITEM_STATUSES,
	NVL(:P_EXCLUDED_ITEM_STATUSES,'') P_EXCLUDED_ITEM_STATUSES
from
		dual
),
gl_dr AS
(
/*
SELECT
	gdr.from_currency,
	gdr.to_currency,
	gdr.conversion_rate
FROM
	gl_daily_rates gdr
WHERE
	1 = 1
and gdr.from_currency = 'USD'
--and gdr.to_currency (+) = qpl.currency_code
and gdr.conversion_type (+) ='Corporate'
and gdr.conversion_date (+) = trunc(sysdate)
*/
select 
	'Corporate' 		conversion_type,
	'USD' 				from_currency,
	lookup_code 		to_currency,	
	to_number(meaning) 	conversion_rate
from 
	fnd_lookups f
where 
	f.lookup_type = 'XXKD_PL_CUR_CONV'
UNION
SELECT
	'Corporate' conversion_type,
	'USD'		from_currency,
	'USD'		to_currency,
	1			conversion_rate
FROM
	dual
)
SELECT /* Union part #3 - in case the markup is taken from the parameter (also means it is a specific price list) */
       distinct 'USER-DEFINED' fetch_source,
	   'N/A' organization_name,
       cic.category_name,
       cic.inventory_item_id,
       cic.item_number,
	   'USD' item_currency_code,
       nvl((select c.base_price
            from qp_price_list_charges c
            where c.parent_entity_id=qpli.price_list_item_id 
            and c.parent_entity_type_code = 'PRICE_LIST_ITEM' 
            and c.start_date <= sysdate
            and nvl(c.end_date,sysdate +1) > sysdate),
           -1) current_cost, -- current price in price list
       nvl((select c.price_list_charge_id
            from qp_price_list_charges c
            where c.parent_entity_id=qpli.price_list_item_id 
            and c.parent_entity_type_code = 'PRICE_LIST_ITEM' 
            and c.start_date <= sysdate
            and nvl(c.end_date,sysdate +1) > sysdate),0)  price_list_charge_id,  
       qpl.price_list_id,
       qplt.name price_list_name,
   	   qpl.currency_code price_list_currency_code,
       qpli.price_list_item_id,
       decode (qpli.price_list_item_id,
               null,'INSERT',
               'UPDATE') action_flag,
       to_number(prm.P_MARKUP) markup_pct_found,
       cic.total_cost * ((100.0 + prm.P_MARKUP)/100.0 ) * decode(qpl.currency_code,'USD',1,gdr.conversion_rate) new_price
FROM cst_item_costs_v cic,
     qp_price_lists_all_b qpl,
     QP_PRICE_LISTS_TL qplt,
     QP_PRICE_LIST_ITEMS qpli,
     EGP_SYSTEM_ITEMS egp,
     egp_item_categories eic,
     egp_categories_b cat,
	 egp_category_sets_tl ecst,
	 (SELECT CST_REL.COST_ORG_ID,COST_BOOK_CODE, CST_REL.COST_BOOK_ID, CST_REL.CONVERSION_TYPE, CST_REL.CURRENCY_CODE 
      FROM CST_COST_ORG_BOOKS CST_REL, CST_COST_BOOKS_B CST_BOOK
      WHERE CST_REL.COST_BOOK_ID = CST_BOOK.COST_BOOK_ID) CST_BOOKS,
	  CST_COST_ORGS_V CST_ORG,
	   -- --gl_daily_rates gdr,
	   gl_dr	gdr,
	   rep_params 	prm
where
	1 = 1
/* Join conditions - vanilla tables */
and qpl.price_list_id = qplt.price_list_id
and egp.inventory_item_id = cic.inventory_item_id
and qpli.item_id (+) = cic.inventory_item_id /* outer join as the item may not exist in list */
AND trunc(sysdate) BETWEEN cic.EFFECTIVE_START_DATE(+) AND cic.EFFECTIVE_END_DATE(+) -- --
and qpli.price_list_id (+) = qplt.price_list_id /* outer join as the item may not exist in list */
and qplt.language = 'US'
and eic.inventory_item_id = egp.inventory_item_id
and eic.organization_id = egp.organization_id
and eic.category_id = cat.category_id 
and ecst.category_set_id =eic.category_set_id
and ecst.category_set_name='Costing Catalog' 
/* Join condition to costing books */
and cic.cost_book_id = cst_books.cost_book_id
and cst_books.cost_org_id = CST_ORG.cost_org_id
and cst_org.COST_ORG_CODE='CST_KTIL'
/* No need for status='PUBLISHED'. it is hard coded into the cst_item_costs_v view */
AND CST_BOOKS.COST_BOOK_CODE ='Standard Cost Book'
/* fillters on costs */
and gdr.to_currency (+) = qpl.currency_code
/* fillters on items */
and egp.customer_order_enabled_flag='Y'
AND egp.organization_id in (select organization_id from INV_ORG_PARAMETERS where organization_code in  ('KDIL_INK' ,'KTIL_PRD' )) 
-- --and nvl(prm.P_IS_AUTOMATED,'Y') = nvl(prm.P_IS_AUTOMATED,'Y') /* @TODO - use prm.P_IS_AUTOMATED parameter versus DFF */
/* @TODO: item category */
/* filters on price lists */
and	prm.P_MARKUP is not null and prm.P_PRICE_LIST_NAME is not null /* The union section condition */
and qplt.name = prm.P_PRICE_LIST_NAME
/* Join to BU */
and (
	prm.P_NEW_ONLY = 'N'
    OR
	not exists (	select 'item found'
					from QP_PRICE_LIST_ITEMS qpli1
					where 
						1 = 1
			-- -- 	and qpli1.item_id = cic.inventory_item_id
			-- --	and qpli1.item_id = qpl.item_id
					and qpli1.item_id = egp.inventory_item_id
					and qpli1.price_list_id = qpl.price_list_id
				   )
	)
and (
	nvl(prm.P_IS_AUTOMATED,'N') = 'N' 
    or
	exists	(
			select 
				'IS_AUTOMATED'
			from
				ego_item_eff_b eb
			WHERE
				1 = 1
			and eb.context_code = 'KD Order Mgmt Information'
			and eb.inventory_item_id = egp.inventory_item_id
			AND eb.organization_id = (select organization_id from INV_ORG_PARAMETERS where organization_code = 'ITM' )
			AND	nvl(eb.attribute_char1,'Yes') = 'Yes'
			AND	(eb.attribute_char1 = 'Yes' OR eb.attribute_char1 is NULL)
			and	cic.cost_asof_date > sysdate - 3)			
			)
AND
	(
		prm.P_INCLUDED_ITEM_STATUSES IS NULL
		OR
		INSTR(','||prm.P_INCLUDED_ITEM_STATUSES||',',','||egp.INVENTORY_ITEM_STATUS_CODE||',') > 0
	)
AND
	(
		prm.P_EXCLUDED_ITEM_STATUSES IS NULL
		OR		
		INSTR(','||prm.P_EXCLUDED_ITEM_STATUSES||',',','||egp.INVENTORY_ITEM_STATUS_CODE||',') = 0
	)
and rownum < 1001