
drop database lab1
go

use AdventureWorks2017
go

create database lab1
go
use lab1
go

select * into [salesorderheader]
from [adventureworks2017].sales.[salesorderheader]
go
select * into [salesorderdetail]
from [adventureworks2017].sales.[salesorderdetail]
go


---checkpoint, dropcleanbuffers -> zapisanie zmodyfikowanych buforów stron na dysk, wyzerownie operacji, zeby miec pewnosc ze pula buforów jest pusta bo jakies dane moga byc w cache'u
select *
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
go


SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--------------------------	ZADANIE 1 ----------------------------------------


-- zapytanie 1
select *
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
where orderdate = '2008-06-01 00:00:00.000'
go
-- zapytanie 1.1
select *
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
where orderdate = '2013-01-28 00:00:00.000'
go
-- zapytanie 2
select orderdate, productid, sum(orderqty) as orderqty,
sum(unitpricediscount) as unitpricediscount, sum(linetotal)
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
group by orderdate, productid
having sum(orderqty) >= 100
go

-- zapytanie 3
select salesordernumber, purchaseordernumber, duedate, shipdate
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
where orderdate in ('2008-06-01','2008-06-02', '2008-06-03', '2008-06-04', '2008-06-05')
go
-- zapytanie 4
select sh.salesorderid, salesordernumber, purchaseordernumber, duedate, shipdate
from salesorderheader sh
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid
where carriertrackingnumber in ('ef67-4713-bd', '6c08-4c4c-b8')
order by sh.salesorderid
go


---indexy------
CREATE INDEX idx_orderdate_salesorderid ON salesorderheader(orderdate, salesorderid);
CREATE INDEX idx_salesorderid ON salesorderdetail(salesorderid);

CREATE INDEX idx_productid ON salesorderdetail(productid);

CREATE INDEX idx_carriertrackingnumber_salesorderid ON salesorderdetail(carriertrackingnumber, salesorderid);






------------------------	ZADANIE 3 -------------------------------------------------
select * into customer from adventureworks2017.sales.customer;

select * from customer where storeid = 594;
  
select * from customer where storeid between 594 and 610;

---idx
create  index customer_store_cls_idx on customer(storeid);
drop  index customer_store_cls_idx on customer;

create clustered index customer_store_cls_idx on customer(storeid);

