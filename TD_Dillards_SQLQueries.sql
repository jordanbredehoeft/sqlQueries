/* Finding average daily revenue but excluding results from August 2005 and those stores with less than 20 sale dates in a month*/

SELECT t.store, EXTRACT(MONTH FROM saledate) AS t_month_num, EXTRACT(year FROM saledate) AS t_sales_year, COUNT(DISTINCT saledate) AS numDates, SUM(amt) AS monthly_rev, (monthly_rev/COUNT(DISTINCT saledate)) AS avg_daily_rev
FROM trnsact t
JOIN (SELECT store, EXTRACT(year FROM saledate) AS sy, EXTRACT(MONTH FROM saledate) sm, 
CASE WHEN sm < 10 THEN sy||'0'||TRIM(sm)
                    ELSE sy||TRIM(sm)
                END AS ym
          FROM trnsact
         WHERE stype = 'P'
           AND ym <> 200508
         GROUP BY sy, sm, store, ym
        HAVING COUNT(DISTINCT saledate) >= 20) AS clean
ON t_sales_year = clean.sy
AND t_month_num = clean.sm
AND t.store = clean.store
WHERE stype ='P'
GROUP BY t.store,t_sales_year, t_month_num;

/* Comparing Dillards stores average daily revenue by hs graduation rate*/

SELECT CASE
	WHEN msa_high < 60 THEN 'low'
	WHEN msa_high > 60 AND msa_high < 70 THEN 'medium'
	WHEN msa_high > 70 THEN 'high'
	END AS msa_hs_grad_rate,
	SUM(monthly_trans.monthly_rev)/SUM(monthly_trans.numDates) AS AVG_Daily_Rev_ByHSGRAD
FROM 
	(SELECT t.store, EXTRACT(MONTH FROM saledate) AS t_month_num, EXTRACT(year FROM saledate) AS t_sales_year, COUNT(DISTINCT saledate) AS numDates, SUM(amt) AS monthly_rev, (monthly_rev/COUNT(DISTINCT saledate)) AS avg_daily_rev
	FROM trnsact t
	JOIN (SELECT store, EXTRACT(year FROM saledate) AS sy, EXTRACT(MONTH FROM saledate) sm, 
	CASE WHEN sm < 10 THEN sy||'0'||TRIM(sm)
	                    ELSE sy||TRIM(sm)
	                END AS ym
	          FROM trnsact
	         WHERE stype = 'P'
	           AND ym <> 200508
	         GROUP BY sy, sm, store, ym
	        HAVING COUNT(DISTINCT saledate) >= 20) AS clean
	ON t_sales_year = clean.sy
	AND t_month_num = clean.sm
	AND t.store = clean.store
	WHERE stype ='P'
	GROUP BY t.store,t_sales_year, t_month_num) AS monthly_trans;
JOIN store_msa msa_hs ON daily_rev_trans.store = msa_hs.store
GROUP BY msa_hs_grad_rate;

/* Comparing AVG Daily Revenue of store with minimum local income vs maximum local income */

SELECT msa.store, msa.city, msa.state, msa.msa_income,
	SUM(monthly_trans.monthly_rev)/SUM(monthly_trans.numDates) AS AVG_Daily_Rev
FROM 
	(SELECT t.store, EXTRACT(MONTH FROM saledate) AS t_month_num, EXTRACT(year FROM saledate) AS t_sales_year, COUNT(DISTINCT saledate) AS numDates, SUM(amt) AS monthly_rev, (monthly_rev/COUNT(DISTINCT saledate)) AS avg_daily_rev
	FROM trnsact t
	JOIN (SELECT store, EXTRACT(year FROM saledate) AS sy, EXTRACT(MONTH FROM saledate) sm, 
	CASE WHEN sm < 10 THEN sy||'0'||TRIM(sm)
	                    ELSE sy||TRIM(sm)
	                END AS ym
	          FROM trnsact
	         WHERE stype = 'P'
	           AND ym <> 200508
	         GROUP BY sy, sm, store, ym
	        HAVING COUNT(DISTINCT saledate) >= 20) AS clean
	ON t_sales_year = clean.sy
	AND t_month_num = clean.sm
	AND t.store = clean.store
	WHERE stype ='P'
	GROUP BY t.store,t_sales_year, t_month_num) AS monthly_trans
JOIN store_msa msa ON monthly_trans.store = msa.store
WHERE msa.msa_income IN ((SELECT MAX(msa_income) FROM store_msa),(SELECT MIN(msa_income) FROM store_msa))
GROUP BY msa.store, msa.city, msa.state, msa.msa_income;