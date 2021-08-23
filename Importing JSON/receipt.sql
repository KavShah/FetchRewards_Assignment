
SELECT * into ReceiptsData 
FROM OPENROWSET (
    BULK 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\receipts.json', 
    FORMATFILE= 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\csv.fmt') AS [Json]
	    CROSS APPLY OPENJSON (json)
		WITH  (
  rid varchar(50) '$._id."$oid"',
  cd bigint '$.createDate."$date"',
  ds bigint '$.dateScanned."$date"',
  fd bigint '$.finishedDate."$date"',
  md bigint '$.modifyDate."$date"',
  pd bigint '$.purchaseDate."$date"',
  purchasedItemCount float,
  totalSpent float,
  userID varchar(50)'$.userId',
  rewardsReceiptStatus varchar(10),
  pointsEarned float,
  pad bigInt '$.pointsAwardedDate."$date"',
  bonusPointsEarned float,
  bonusPointsEarnedReason varchar(100),
   rewardsReceiptItemList nvarchar(max) as json
) b
cross apply openjson (b.rewardsReceiptItemList) 
with(
barCode varchar(50) '$.barcode',
brandCode varchar(50) '$.brandCode', 
descr varchar(50) '$.description',
competitiveProduct varchar(10) '$.competitiveProduct',
discountedItemPrice float '$.discountedItemPrice',
finalPrice float '$.finalPrice',
itemPrice float '$.itemPrice',
needFetchReview varchar(10) '$.needsFetchReview',
fetcReviewReason varchar(1000) '$.needsFetchReviewReason',
pointsNotAwardedReason varchar(100) '$.pointsNotAwardedReason',
originalReceiptItemText varchar(100) '$.originalReceiptItemText',
partnerItemId int '$.partnerItemId',
rewardsProductPartnerId varchar(50) '$.rewardsProductPartnerId',
metabriteCampaignId varchar(50) '$.metabriteCampaignId',
ItempointsEarned float '$.pointsEarned',
pointsPayerId varchar(50) '$.pointsPayerId',
rewardsGroup varchar(50) '$.rewardsGroup',
targetPrice float '$.targetPrice',
preventTargetGap varchar(10) '$.preventTargetGapPoints',
QtyPurchased int '$.quantityPurchased',
userFlaggedBarCode varchar(50) '$.userFlaggedBarcode',
userFlaggednewItem varchar(10) '$.userFlaggedNewItem',
userFlaggedDescription varchar(50) '$.userFlaggedDescription',
userFlaggedPrice float '$.userFlaggedPrice',
userFlaggedQty float '$.userFlaggedQuantity'
)
cross apply (
  select
    createDate = dateadd(ss, cd/1000, '1970-01-01'),
    dateScanned = dateadd(ss, ds/1000, '1970-01-01'),
	finishedDate = dateadd(ss, fd/1000, '1970-01-01'),
	modifyDate = dateadd(ss, md/1000, '1970-01-01'),
	purchaseDate = dateadd(ss, pd/1000, '1970-01-01'),
	pointsAwardedDate = dateadd(ss, pad/1000, '1970-01-01')
) calc

--
--dim_receipt
select distinct userid, rid, rewardsReceiptStatus,bonuspointsearnedreason into dim_receipt from ReceiptsData
--adding foreign keys
alter table dim_receipt
add rewStatID int, bonusReasonID int
--updating
update dim_receipt 
set dim_receipt.rewStatID = c.rewStatID
from dim_receipt b join dim_rewRecStatus c on b.rewardsReceiptStatus=c.rewardsReceiptStatus
--
update dim_receipt 
set dim_receipt.bonusReasonID = c.bonusReasonID
from dim_receipt b join dim_bonusptsReason c on b.bonuspointsearnedreason=c.bonuspointsearnedreason

--DQ - Some userid missing in users table, there are more users in receipt so FK issue  

--dim_rewRecStatus
select distinct rewardsReceiptStatus into dim_rewRecStatus from ReceiptsData
--DQ status-submitted an issue

--dim_bonusPtsReason
select distinct bonuspointsearnedreason into dim_bonusPtsReason from ReceiptsData

--dim_rewRecItem
select rid, barcode,descr,partnerItemId, metabriteCampaignId, competitiveProduct, needFetchReview, fetcReviewReason, pointsNotAwardedReason, originalReceiptItemText
, rewardsProductPartnerId, pointsPayerId, preventTargetGap, rewardsGroup, userFlaggedBarCode, userFlaggednewItem, userFlaggedDescription, userFlaggedPrice, userFlaggedQty  into dim_rewRecItemList from ReceiptsData

alter table dim_rewRecItemList
add fetchReasonId int, notAwardedID int, rewardPartnerID int

--updating
update dim_rewRecItemList 
set dim_rewRecItemList.fetchReasonId = c.fetchReasonId
from dim_rewRecItemList b join dim_needFetchReviewReason c on b.fetcReviewReason=c.fetcReviewReason
--
update dim_rewRecItemList 
set dim_rewRecItemList.notAwardedID = c.notAwardedID
from dim_rewRecItemList b join dim_notAwardedReason c on b.pointsNotAwardedReason=c.pointsNotAwardedReason

update dim_rewRecItemList 
set dim_rewRecItemList.rewardPartnerID = c.rewardPartnerID
from dim_rewRecItemList b join dim_rewprodPartner c on b.rewardsPartnerId=c.rewardsProductPartnerId

--dim_rewProdPartner
-- DQ - Why is pointpayersID column there?
select distinct coalesce(rewardsProductPartnerId,pointsPayerId) as rewardPartnerID into dim_rewProdPartner from ReceiptsData
--dim_NotAwardedReason
select distinct pointsNotAwardedReason into dim_NotAwardedReason from ReceiptsData
--dim_needFetchReviewReason
select distinct fetcReviewReason into dim_needFetchReviewReason from ReceiptsData

-- DQ - UserFlagged use? as max is null
-- DQ - Barcodes missing in brand table, only 5111 series

--FACT Table
select rrid, rid, userid, [purchasedItemCount],[totalSpent],[pointsEarned],[bonusPointsEarned],[discountedItemPrice]
      ,[finalPrice]
      ,[itemPrice],[ItempointsEarned],[targetPrice],[QtyPurchased]
	  ,CONVERT(INT, CONVERT(VARCHAR(8), [createDate], 112)) as createDateKey
      ,CONVERT(INT, CONVERT(VARCHAR(8), [dateScanned], 112)) as dateScannedKey
      ,CONVERT(INT, CONVERT(VARCHAR(8), [finishedDate], 112)) as finisheddateKey
      ,CONVERT(INT, CONVERT(VARCHAR(8), [modifyDate], 112)) as modifyDateKey
      ,CONVERT(INT, CONVERT(VARCHAR(8), [purchaseDate], 112)) as purchaseDateKey
      ,CONVERT(INT, CONVERT(VARCHAR(8), [pointsAwardedDate], 112)) as pointsAwardedDateKey
	 into Fact_Table from ReceiptsData rd  

	 select rid, count(rid)
	 from ReceiptsData
	 group by rid
	 order by count(rid) desc

	 select  f.userid, sum(finalprice) from Fact_Table f
	 join dim_receipt r on f.rid=r.rid join dim_user u on f.userID=u.userid
	 group by f.userID 
	 
	 --FK constraints