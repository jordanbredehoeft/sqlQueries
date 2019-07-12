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

/* Comparing departments with the greatest increase in average daily revenue from Nov to Dec */

SELECT clean.sale_dept, dt.deptdesc, clean.store, st.city, st.state, 
	SUM(CASE WHEN clean.sm = 11 THEN clean.amt END) AS Nov_Rev, 
	SUM(CASE WHEN clean.sm=12 THEN clean.amt END) AS Dec_Rev, 
	COUNT(DISTINCT CASE WHEN clean.sm = 11 THEN clean.saledate END) AS NovDates, 
	COUNT(DISTINCT CASE WHEN clean.sm=12 THEN clean.saledate END) AS DecDates,
	Nov_Rev/NovDates AS Nov_Daily_Rev, 
	Dec_Rev/DecDates AS Dec_Daily_Rev, 
	((Dec_Daily_Rev - Nov_Daily_Rev)/Nov_Daily_Rev)*100 AS Percent_Increase
FROM (SELECT sk.dept AS sale_dept, store, saledate, EXTRACT(year FROM saledate) AS sy, EXTRACT(MONTH FROM saledate) sm, 
		CASE WHEN sm < 10 THEN sy||'0'||TRIM(sm)
		ELSE sy||TRIM(sm)
        END AS ym, amt
      FROM trnsact t
      JOIN skuinfo sk ON t.sku = sk.sku
      WHERE stype = 'P'
      AND ym <> 200508) AS clean
JOIN strinfo st ON clean.store = st.store
JOIN deptinfo dt on clean.sale_dept = dt.dept
GROUP BY 1,2,3,4,5
HAVING NovDates >= 20 AND DecDates >=20
ORDER BY 12 DESC;

/* Comparing stores with the greatest decrease in average daily revenue from Aug to Sep */

SELECT clean.store, st.city, st.state, 
	SUM(CASE WHEN clean.sm = 8 THEN clean.amt END) AS Aug_Rev, 
	SUM(CASE WHEN clean.sm=9 THEN clean.amt END) AS Sep_Rev, 
	COUNT(DISTINCT CASE WHEN clean.sm = 8 THEN clean.saledate END) AS AugDates, 
	COUNT(DISTINCT CASE WHEN clean.sm=9 THEN clean.saledate END) AS SepDates,
	Aug_Rev/AugDates AS Aug_Daily_Rev, 
	Sep_Rev/SepDates AS Sep_Daily_Rev, 
	(Aug_Daily_Rev - Sep_Daily_Rev) AS Daily_Rev_Decrease
FROM (SELECT store, saledate, EXTRACT(year FROM saledate) AS sy, EXTRACT(MONTH FROM saledate) sm, 
		CASE WHEN sm < 10 THEN sy||'0'||TRIM(sm)
		ELSE sy||TRIM(sm)
        END AS ym, amt
      FROM trnsact t
      WHERE stype = 'P'
      AND ym <> 200508) AS clean
JOIN strinfo st ON clean.store = st.store
GROUP BY 1,2,3
HAVING AugDates >= 20 AND SepDates >=20
ORDER BY 10 DESC;

/* Finding the month with the most stores having their min total revenue and min daily revenue 
		Using row number to group by store, order by avg daily revenue and total revenue, then qualify to choose only those with last rank*/

SELECT clean.month_num AS month_with_mins, 
	COUNT(CASE WHEN clean.month_rank_total_rev=12 THEN clean.store END) AS total_monthly_rev_min_count, 
	COUNT(CASE WHEN clean.month_rank_avg_daily_rev=12 THEN clean.store END) AS average_daily_rev_min_count
FROM (
		SELECT store, EXTRACT(year FROM saledate) AS sales_year, EXTRACT(MONTH FROM saledate) AS month_num, 
		CASE WHEN month_num < 10
		            THEN sales_year||'0'||TRIM(month_num)
		            ELSE sales_year||TRIM(month_num)
		             END AS year_month,
		COUNT(DISTINCT saledate) AS num_dates, SUM(amt) AS monthly_rev, (monthly_rev/COUNT(DISTINCT saledate)) AS avg_daily_rev,
		ROW_NUMBER() OVER(PARTITION BY store ORDER BY avg_daily_rev DESC) AS month_rank_avg_daily_rev,
		ROW_NUMBER() OVER(PARTITION BY store ORDER BY monthly_rev DESC) AS month_rank_total_rev
		FROM trnsact
		WHERE stype='P' AND year_month <> 200508
		GROUP BY sales_year, month_num, store, year_month
		HAVING num_dates >= 20
		QUALIFY month_rank_avg_daily_rev = 12 OR month_rank_total_rev=12
	) AS clean
GROUP BY month_with_mins
ORDER BY total_monthly_rev_min_count DESC;

/* Comparing average daily revenue by stores in population size groups */

SELECT CASE
	WHEN msa_pop > 0 AND msa_pop <= 100000 THEN 'very small'
	WHEN msa_pop > 100000 AND msa_pop <= 200000 THEN 'small'
	WHEN msa_pop > 200000 AND msa_pop <= 500000 THEN 'med_small'
	WHEN msa_pop > 500000 AND msa_pop <= 1000000 THEN 'med_large'
	WHEN msa_pop > 1000000 AND msa_pop <= 5000000 THEN 'large'
	WHEN msa_pop > 5000000 THEN 'very large'
	END AS msa_pop_group,
	SUM(monthly_trans.monthly_rev)/SUM(monthly_trans.numDates) AS AVG_Daily_Rev_ByPopGroup
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
GROUP BY msa_pop_group;

/* Finding the month where stores have the max number of items returned 
		Using a row number statement to group by store and rank by items returned, then qualify to choose the highest rank*/

SELECT clean.month_num AS month_with_max_returns, 
	COUNT(CASE WHEN clean.month_rank_total_units_returned=1 THEN clean.store END) AS total_monthly_return_maxes
FROM (
		SELECT store, EXTRACT(year FROM saledate) AS sales_year, EXTRACT(MONTH FROM saledate) AS month_num, 
		CASE WHEN month_num < 10
		            THEN sales_year||'0'||TRIM(month_num)
		            ELSE sales_year||TRIM(month_num)
		             END AS year_month,
		COUNT(DISTINCT saledate) AS num_dates, SUM(quantity) AS monthly_items_returned,
		ROW_NUMBER() OVER(PARTITION BY store ORDER BY monthly_items_returned DESC) AS month_rank_total_units_returned
		FROM trnsact
		WHERE stype='R' AND year_month <> 200508
		GROUP BY sales_year, month_num, store, year_month
		HAVING num_dates >= 20
		QUALIFY month_rank_total_units_returned = 1
	) AS clean
GROUP BY month_with_max_returns
ORDER BY total_monthly_return_maxes DESC;