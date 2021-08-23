--1. What are the top 5 brands by receipts scanned for most recent month?
with q1 as --Aggregate value for the brands by month
(
select name as brandName, count(rr.barcode) as Total, d.DimDate_Month as Mon
from dim_receipt r join Fact_Table f on r.rid=f.rid
join dim_rewRecItemList rr on f.rrid=rr.rrid join dim_brands b on rr.barcode=b.barcode
join DimDate d on d.DimDate_ID=f.dateScannedKey
--where Year(r.dateScanned)=Year(getDate())
group by name, d.DimDate_Month --grouping by year and month
)
, q2 as --get the most recent month
(
select brandName, Mon, total, 
row_number() over(partition by brandName order by Mon) as Recent
from q1
),
q3 as --taking only most Recent and ranking the brands
(
select brandName, total,
dense_rank() over(order by total desc) as rk
from q2
where  recent = 1 
group by brandName,total, mon 
having Mon = min(mon)
)
select brandName, total from q3
where rk <=5;

--2. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
--Not enough data, as barcode in brands has only 5111 serires whereas there are other barcodes in the receipt item list.
--So, for the data we have only jan and feb have barcode 5111 purchases with feb having only 3 brands

--3. When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
with q1 as(
select distinct f.rid, f.totalSpent, rs.rewardsReceiptStatus 
from Fact_Table f join dim_receipt r on f.rid=r.rid join dim_rewRecStatus rs 
on r.rewStatID=rs.rewStatID)
select q1.rewardsReceiptStatus, avg(q1.totalSpent) as AverageSpent from q1
group by q1.rewardsReceiptStatus;


--4. When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
with q1 as(
select distinct f.rid, f.purchasedItemCount, rs.rewardsReceiptStatus 
from Fact_Table f join dim_receipt r on f.rid=r.rid join dim_rewRecStatus rs 
on r.rewStatID=rs.rewStatID)
select q1.rewardsReceiptStatus, sum(q1.purchasedItemCount) as totPur from q1
group by q1.rewardsReceiptStatus

--5. Which brand has the most spend among users who were created within the past 6 months?
select b.name, sum(f.finalPrice) totalSpent
from Fact_Table f join dim_rewRecItemList rr on f.rrid=rr.rrid join dim_brands b on rr.barcode=b.barcode
join dim_user u on f.userid=u.userid
where createdDate > DATEADD(m,-9,current_timestamp)
group by b.name
order by totalSpent desc

--6. Which brand has the most transactions among users who were created within the past 6 months?
select b.name, count(rr.barcode) totalTrans
from Fact_Table f join dim_rewRecItemList rr on f.rrid=rr.rrid join dim_brands b on rr.barcode=b.barcode
join dim_user u on f.userid=u.userid
where createdDate > DATEADD(m,-9,current_timestamp)
group by b.name
order by totalTrans desc