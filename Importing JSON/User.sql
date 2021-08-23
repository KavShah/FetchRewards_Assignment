SELECT * into userdata
FROM OPENROWSET (
    BULK 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\users.json', 
    FORMATFILE= 'C:\Users\shahk\OneDrive\Desktop\FetchAssgn\csv.fmt') AS [Json]
	    CROSS APPLY OPENJSON (json)
		WITH  (
  Userid varchar(50) '$._id."$oid"',
  state varchar(5),
  cd bigint '$.createdDate."$date"',
  ll bigint '$.lastLogin."$date"',
  role varchar(10)    ,
  signUpSource varchar(10),
  active varchar(10)   
) AS users
cross apply (
  select
    createdDate = dateadd(ss, cd/1000, '1970-01-01'),
    lastLogin = dateadd(ss, ll/1000, '1970-01-01')
) calc;

select distinct userid, state, createddate, role, signupsource, active into dim_user from Userdata

alter table dim_user 
drop column json, cd, ll;

select userid, count(*)
from dim_user
group by userid

select * from dim_user

select userID, lastLogin into dim_LastLogin from dim_user

alter table dim_user 
add roleid int;

update dim_user 
set dim_user.roleid = c.roleid
from dim_user b join dim_role c on b.role=c.role

