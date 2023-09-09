--Inspecting Data
select * from PortfolioProject2..sales_data_sample

--Checking unique values
select distinct status from PortfolioProject2..sales_data_sample --good to plot
select distinct year_id from PortfolioProject2..sales_data_sample
select distinct PRODUCTLINE from PortfolioProject2..sales_data_sample --good to plot
select distinct COUNTRY from PortfolioProject2..sales_data_sample --good to plot
select distinct DEALSIZE from PortfolioProject2..sales_data_sample --good to plot
select distinct TERRITORY from PortfolioProject2..sales_data_sample --good to plot

--ANALYSIS:

--Group sales by productline
select PRODUCTLINE, sum(sales) as Revenue
from PortfolioProject2..sales_data_sample
group by PRODUCTLINE
order by 2 desc

--Group sales by year
select YEAR_ID, sum(sales) as Revenue
from PortfolioProject2..sales_data_sample
group by YEAR_ID
order by 2 desc

--Group sales by deal size
select DEALSIZE, sum(sales) as Revenue
from PortfolioProject2..sales_data_sample
group by DEALSIZE
order by 2 desc

--Group by most monthly sales made in a given year (as well as by what amount)
select MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from PortfolioProject2..sales_data_sample
where YEAR_ID = 2005 --Change value to see data for a unique year
group by MONTH_ID
order by 2 desc
--On average, November seems to have highest revenue for 2003 and 2004
--Group sales by most product sold in the highest grossing months
select MONTH_ID, PRODUCTLINE, sum(sales) as Revenue, count(ORDERNUMBER)
from PortfolioProject2..sales_data_sample
where YEAR_ID = 2003 and MONTH_ID = 11 --change year to see the rest
group by MONTH_ID, PRODUCTLINE
order by 3 desc

--Use RFM Analysis (recency, frequency, monetary) to group customers by purchases made
DROP TABLE IF EXISTS #rfm;
with rfm as
(
    select
        CUSTOMERNAME,
        sum(sales) as MonetaryValue,
        avg(sales) as AvgMonetaryValue,
        count(ORDERNUMBER) as Frequency,
        max(ORDERDATE) as last_order_date,
        (select max(ORDERDATE) from PortfolioProject2..sales_data_sample) as max_order_date,
        DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from PortfolioProject2..sales_data_sample)) as Recency
    from PortfolioProject2..sales_data_sample
    group by CUSTOMERNAME
),
rfm_calc as 
(
	select r.*,
		NTILE(4) OVER (order by Recency) as rfm_recency,
		NTILE(4) OVER (order by Frequency) as rfm_frequency,
		NTILE(4) OVER (order by AvgMonetaryValue) as rfm_monetary
	from rfm as r
)
select
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast (rfm_recency as varchar) + cast (rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm
