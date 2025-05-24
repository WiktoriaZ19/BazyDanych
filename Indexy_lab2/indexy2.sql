create database lab2
go
use lab2
go



-------------------- ZADANIE 1 --------------------------------
--- tabela
select businessentityid  
      ,persontype  
      ,namestyle  
      ,title  
      ,firstname  
      ,middlename  
      ,lastname  
      ,suffix  
      ,emailpromotion  
      ,rowguid  
      ,modifieddate  
into person  
from adventureworks2017.person.person;

--zapytania
select * from [person] where lastname = 'Agbonile';
  
select * from [person] where lastname = 'Agbonile' and firstname = 'Osarumwense';  
  
select * from [person] where firstname = 'Osarumwense';

-- indeks
create index person_first_last_name_idx  
on person(lastname, firstname);

-- inne parametry
select * from [person] where lastname = 'Price';
  
select * from [person] where lastname = 'Price' and firstname = 'Angela';  
  
select * from [person] where firstname = 'Angela';





-------------------	ZADANIE 2	------------------------------------
--tabela
select * into product from adventureworks2017.production.product;

-- indeks z warunkiem przedziałowym
create nonclustered index product_range_idx  
    on product (productsubcategoryid, listprice) include (name)  
where productsubcategoryid >= 27 and productsubcategoryid <= 36;

-- zapytania
select name, productsubcategoryid, listprice  
from product  
where productsubcategoryid >= 27 and productsubcategoryid <= 36;

select name, productsubcategoryid, listprice  
from product  
where productsubcategoryid < 27 or productsubcategoryid > 36


----------------------	ZADANIE 3 ------------------------------------------
-- tabela 
select * into purchaseorderdetail from  adventureworks2017.purchasing.purchaseorderdetail;

-- zapytanie 
select rejectedqty, ((rejectedqty/orderqty)*100) as rejectionrate, productid, duedate  
from purchaseorderdetail  
order by rejectedqty desc, productid asc;

-- stworzenia indeksu
create clustered index rejectedqty_productid_idx
on purchaseorderdetail(rejectedqty desc, productid asc);


drop index rejectedqty_productid_idx
on purchaseorderdetail;



--------------------	ZADANIE 4 -----------------------------
-- tabela
create table dbo.saleshistory(  
 salesorderid int not null,  
 salesorderdetailid int not null,  
 carriertrackingnumber nvarchar(25) null,  
 orderqty smallint not null,  
 productid int not null,  
 specialofferid int not null,  
 unitprice money not null,  
 unitpricediscount money not null,  
 linetotal numeric(38, 6) not null,  
 rowguid uniqueidentifier not null,  
 modifieddate datetime not null  
 );

 -- indeks
create clustered index saleshistory_idx  
on saleshistory(salesorderdetailid);

-- wypełnienie tablicy danymi
insert into saleshistory  
 select sh.*  
 from adventureworks2017.sales.salesorderdetail sh  
go 100


-- zapytanie
select productid, sum(unitprice), avg(unitprice), sum(orderqty), avg(orderqty)  
from saleshistory  
group by productid  
order by productid;


create nonclustered columnstore index saleshistory_columnstore  
 on saleshistory(unitprice, orderqty, productid);