SELECT * into branddata FROM OPENROWSET (
    BULK 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\brands.json', 
    FORMATFILE= 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\csv.fmt') AS [Json]
	    CROSS APPLY OPENJSON (json)
		WITH  (
  bid varchar(50) '$._id."$oid"',
  barcode varchar(50),
  brandCode varchar(50),
  category varchar(50),
  categoryCode varchar(50),
  
  topBrand varchar(10),
  name varchar(100),
  cpg nvarchar(max) as json
) b
cross apply openjson (b.cpg) 
with(
oid varchar(50) '$."$id"."$oid"',
ref varchar(50) '$."$ref"'
)
;

alter table branddata
drop column json, cpg;

select distinct category into dim_cat from branddata

select distinct oid, ref into dim_cpg from branddata

select * into dim_brand from branddata

alter table dim_brands
add catId int, cpgid int

update branddata 
set branddata.catID = c.catID
from branddata b join dim_cat c on b.category=c.category

--categoryCode needs cleaning up

update branddata 
set branddata.cpgID = c.cpgID
from branddata b join dim_cpg c on b.oid=c.cpg and b.ref=c.ref