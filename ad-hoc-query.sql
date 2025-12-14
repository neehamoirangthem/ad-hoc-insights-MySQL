-- Request 1:
      
      SELECT market 
         FROM dim_customer
         WHERE customer ="Atliq exclusive" 
         AND region ="APAC"
         GROUP BY market
         ORDER BY market;
         
-- Request 2:
    
    WITH cte1 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
	FROM fact_sales_monthly
    WHERE fiscal_year=2020
    ),
    cte2 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year=2021
    )
    SELECT 
       unique_products_2020,
       unique_products_2021,
       ROUND(
       (unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS
       percentage_chg
	FROM cte1
    CROSS JOIN cte2
    ;
    
-- Request 3:

    SELECT 
      segment,
      COUNT(DISTINCT product_code) AS product_count
   FROM dim_product
   GROUP BY segment
   ORDER BY product_count DESC
   ;
   
-- Request 4:

	WITH unique_products as (
	SELECT 
         p.segment,
         COUNT(DISTINCT CASE WHEN fiscal_year=2020 
         THEN s.product_code END) AS product_count_2020,
         COUNT(DISTINCT CASE WHEN fiscal_year=2021
         THEN s.product_code END) AS product_count_2021
	FROM fact_sales_monthly s 
	JOIN dim_product p 
	ON s.product_code=p.product_code
	GROUP BY segment
	)
	SELECT
         segment,
         product_count_2020,
         product_count_2021,
         product_count_2021-product_count_2020 AS difference 
	FROM unique_products
	ORDER BY difference DESC
	;
    
    
  -- Request 5:
    
    WITH ranked AS (
    SELECT 
      p.product,
      p.product_code,
      c.manufacturing_cost,
    RANK() OVER (ORDER BY c.manufacturing_cost DESC) AS max_rank,
    RANK() OVER (ORDER BY c.manufacturing_cost ASC) AS min_rank
    FROM fact_manufacturing_cost c 
    JOIN dim_product p 
    ON c.product_code=p.product_code
)
    SELECT 
      product,
      product_code,
      manufacturing_cost
    FROM ranked
    WHERE min_rank=1 OR max_rank=1
    ORDER BY max_rank ASC;


-- Request 6:

    SELECT
	  d.customer_code,
      c.customer,
    CONCAT(ROUND(AVG(d.pre_invoice_discount_pct)*100,2), "%") AS avg_discount_pct
    FROM fact_pre_invoice_deductions d 
    JOIN dim_customer c 
    USING (customer_code)
    WHERE d.fiscal_year=2021
    AND c.market="India"
	GROUP BY 
      d.customer_code,
	  c.customer
    ORDER BY AVG(d.pre_invoice_discount_pct) DESC
    LIMIT 5
    ;
    
-- Request 7:

	SELECT 
	  monthname(s.date) AS month,
      year(s.date) AS year,
   ROUND(SUM(g.gross_price*s.sold_quantity)/1000000,2) AS gross_sales_amount
   FROM fact_sales_monthly s 
   JOIN fact_gross_price g 
   ON s.product_code=g.product_code
   AND g.fiscal_year=s.fiscal_year
   JOIN dim_customer c 
   on s.customer_code= c.customer_code
   WHERE customer="AtliQ Exclusive"
   GROUP BY month, year
   ORDER BY year ASC 
   ;
   
   
-- Request 8:

    SELECT (
      CASE
       WHEN month(date) IN (9,10,11) THEN "Q1"
       WHEN month(date) IN (12,1,2) THEN "Q2"
       WHEN month(date) IN (3,4,5) THEN "Q3"
       WHEN month(date) IN (6,7,8) THEN "Q4"
	  END) AS Quarter,
       SUM(sold_quantity) AS total_sold_quantity
   FROM fact_sales_monthly
   WHERE fiscal_year=2020
   GROUP BY Quarter 
   ORDER BY total_sold_quantity DESC
   ;
   
-- Request 9:

     WITH cte1 AS (
        SELECT 
          c.channel,
          ROUND(SUM((s.sold_quantity*g.gross_price)/1000000),2) AS gross_sales_mln
	    FROM dim_customer c 
	    JOIN fact_sales_monthly s 
	    ON c.customer_code=s.customer_code
        JOIN fact_gross_price g 
        ON s.product_code=g.product_code
        WHERE s.fiscal_year=2021
        GROUP BY c.channel
     )
     SELECT 
        *,
		CONCAT(ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2),"%") as pct_distribution
	 FROM cte1
     ORDER BY pct_distribution DESC
     ;
     
-- Request 10:
 
    WITH cte1 AS (
      SELECT 
        p.division,
        s.product_code,
        p.variant,
        p.product,
        SUM(s.sold_quantity) AS total_sold_qty,
        DENSE_RANK() OVER( PARTITION BY p.division ORDER BY SUM(s.sold_quantity)  DESC) AS rank_order
     FROM fact_sales_monthly s 
     JOIN dim_product p 
     ON s.product_code=p.product_code
     WHERE s.fiscal_year=2021
     GROUP BY p.division, s.product_code,p.product,p.variant
    )
     SELECT
       division,
       CONCAT(product," ", variant) AS product_variant,
       product_code,
       total_sold_qty,
       rank_order
	FROM cte1
    WHERE rank_order<=3
    ORDER BY division, rank_order
    ;
     