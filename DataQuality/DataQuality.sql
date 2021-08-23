--Data Quality Queries/Issues
--Users Schema
--The Primary key prevents duplicate userID, but just to verify
select userid, count(userid)
from dim_user
group by userid
having count(userid) > 1

--Checking where active = false *One user is not active - 6008622ebe5fc9247bab4eb9*
select userid from dim_user
where dim_user.active not like 'true'

--Brand Schema
select bid, count(bid)
from dim_brands
group by bid
having count(bid) > 1

--As it is a 12 digit UPC barcode, checking if every barcode is unique 
--*7 barcodes that are not unique*.*This will arise a major data quality issue as one barcode is shared by 2 items*
select barcode, count(barcode)
from dim_brands
group by barcode
having count(barcode) > 1

--CategoryCode seems a redundant column
select distinct category, categoryCode from branddata

--Receipt Schema
--Here there are columns that need clarification, such as pointsPayerID and rewardProductPrtnerID, both have same IDs
select distinct r.pointsPayerId, r.rewardsProductPartnerId from ReceiptsData r

--Importance of column such as metabriteCampaignId, as most are nulls
select count(*) from ReceiptsData
where metabriteCampaignId is null

--The rows having reward receipt status SUBMITTED, have no reward receipt item list, is that data needed?

--FK constarints
--There are userIds in receipts schema but are not present in User table, which says the users were deleted after the receipts or data is incomplete and hance FK constraint can't be established.
select count(distinct userid) from Fact_Table;--246 Users
select count(distinct userid) from dim_user;--212 Users

--Similarly with barcodes not unique in the brands schema, issue while trying FK connection with rewardItemList barcode.
--There are only 5111 series barcodes in brand schema whereas ReceiptItem list contains more types of barcodes. This won't give accurate counts
select distinct barcode from dim_rewRecItemList;
select distinct barcode from dim_brands;

--Fetch review true where reason is null
select rrid from dim_rewRecItemList rr join dim_needFetchReviewReason fr on rr.fetchReasonId=fr.fetchReasonID 
where rr.needFetchReview like 'true' and (fr.fetcReviewReason is null or fr.fetcReviewReason like 'Null')

--FinalPrice vs ItemPrice
--Both the prices are irrespective of the quantities, either final price ahould be ItemQty * ItemPrice or ItemPrice should be FinalPrice/ItemQty
select rrid, itemprice, finalprice, QtyPurchased from Fact_Table
where QtyPurchased>1