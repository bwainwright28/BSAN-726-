 
DROP Table DIM_JUNK;
DROP Table DIM_CUSTOMERS;
DROP Table DIM_LOCATION;
DROP Table DIM_ORDERS;
DROP Table DIM_PRODUCTS;
DROP Table DIM_SHIPPERS;
DROP TABLE DIM_SUPPLIERS;
Drop Table Facts;
Drop table Product_facts;

CREATE TABLE DIM_PRODUCTS (
    ProductID NUMBER,
    CategoryID VARCHAR2(60),
    ProductName varchar2(100),
    CategoryName VARCHAR2(60),
    Description varchar2(400),
    constraint DIM_Products_PK PRIMARY KEY (ProductID)
    );

INSERT INTO DIM_PRODUCTS 
    (ProductID, CategoryID, ProductName, CategoryName, Description)
SELECT p.ProductID, p.ProductName, c.CategoryID, c.CategoryName, c.Description
From nw_products p
Join NW_CATEGORIES c on (p.CategoryID = c.CategoryID)



CREATE TABLE DIM_SHIPPERS (
    ShipperID NUMBER,
    Company_Name VARCHAR2(100),
    Phone varchar2(20),
    constraint DIM_SHIPPERS_PK PRIMARY KEY (ShipperID)
    );

INSERT INTO DIM_SHIPPERS 
    (ShipperID, Company_Name, Phone)
SELECT sh.ShipperID, sh.CompanyName, sh.Phone
from nw_shippers sh



CREATE TABLE DIM_ORDERS (
    OrderID varchar2(10),
    Required_Date Date,
    Ship_Name VARCHAR2(200),
    Ship_Address varchar2(200),
    Ship_City varchar2(100),
    Ship_Region varchar2(100),
    Ship_PostalCode varchar2(20),
    Ship_Country varchar2(100),
    constraint DIM_ORDERS_PK PRIMARY KEY (ORDERID)
    );

INSERT INTO DIM_ORDERS 
    (OrderID, Required_Date, Ship_Name, Ship_Address, Ship_City, Ship_Region, Ship_PostalCode, Ship_Country)
SELECT OrderID, RequiredDate, ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry
from NW_orders 


CREATE TABLE DIM_CUSTOMERS (
    CustomerID varchar2(30),
    Company_Name varchar2(120),
    Contact_Name varchar2(120),
    Contact_Title varchar2(120),
    Address varchar2(120),
    City varchar2(60),
    Region varchar2(25),
    PostalCode varchar2(20),
    Country varchar2(15),
    Phone varchar2(20),
    Fax varchar2(20),
    constraint DIM_CUSTOMERS_PK PRIMARY KEY (CustomerID)
    );


INSERT INTO DIM_CUSTOMERS 
    (CustomerID, Company_Name, Contact_Name, Contact_Title, Address, City, Region, PostalCode, Country, Phone, Fax)
SELECT CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax
from nw_customers 

CREATE TABLE DIM_SUPPLIERS (
    SupplierID varchar2(30),
    Company_Name varchar2(120),
    Contact_Name varchar2(120),
    Contact_Title varchar2(120),
    Address varchar2(120),
    City varchar2(60),
    Region varchar2(25),
    PostalCode varchar2(20),
    Country varchar2(15),
    Phone varchar2(20),
    Fax varchar2(20),
    Homepage varchar2(200),
    constraint DIM_SUPPLIER_PK PRIMARY KEY (SupplierID)
    );

INSERT INTO DIM_SUPPLIERS    
    (SupplierID, Company_Name, Contact_Name, Contact_Title, Address, City, Region, PostalCode, Country, Phone, Fax, Homepage)
SELECT SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax, Homepage
from nw_suppliers 

CREATE TABLE DIM_LOCATION (
    TerritoryID number,
    Territory_Desc varchar2(60),
    RegionID number,
    Region_Desc varchar2(60),
    constraint DIM_LOCATION_PK PRIMARY KEY (TerritoryID)
)

INSERT INTO DIM_LOCATION 
    (RegionID, Region_Desc, TerritoryID, Territory_Desc)
Select r.RegionID, r.RegionDescription, t.territoryID, t.territorydescription
From nw_regions r
Join nw_territories t on (t.RegionID = r.RegionID)

Create Table DIM_JUNK(
    JunkID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
    ProductID number,
    Discontinued varchar2(1) DEFAULT 'Y',
    constraint DIM_JUNK_PK PRIMARY KEY (JunkID)
) 

Insert into DIM_JUNK 
    (ProductID, Discontinued)
Select ProductID, CASE WHEN Discontinued <> 0 THEN 'Y' ELSE 'N' END AS Discontinued
From nw_products



CREATE TABLE Facts as 
SELECT DISTINCT 
od.ProductID as ProductID, 
c.CustomerID as CustomerID, 
s.ShipperID as ShipperID, 
t.territoryID as TerritoryID, 
od.OrderID as OrderID, 
su.SupplierID as SupplierID, 
od.Quantity as Quantity, 
od.UnitPrice as Unit_Price,
od.Discount as Discount,
(od.Quantity*od.UnitPrice - od.Discount) as Billing_amount, 
o.Freight as Weight,
p.unitsonorder as Units_on_order,
p.unitsinstock as Units_in_stock,
p.reorderlevel as Reorder_level,
o.OrderDate as OrderDate, o.ShippedDate as ShippedDate
FROM NW_ORDERDETAILS od JOIN NW_ORDERS o ON 
od.OrderID = o.OrderID
JOIN NW_SHIPPERS s ON s.ShipperID = o.ShipVia
JOIN NW_PRODUCTS p ON od.ProductID = p.ProductID
JOIN NW_CUSTOMERS c ON o.CustomerID = c.CustomerID
JOIN nw_territories t on o.territoryID = t.territoryID
JOIN nw_suppliers su on p.SupplierID = su.SupplierID
ORDER BY OrderDate, ShippedDate, OrderID, ProductID
;

CREATE TABLE PRODUCT_FACTS as
Select 
pd.ProductID as ProductID, 
cd.CustomerID as CustomerID, 
shd.ShipperID as ShipperID, 
jd.JunkID as JunkID,
td.territoryID as TerritoryID, 
od.OrderID as OrderID, 
sd.SupplierID as SupplierID, 
f.Quantity as Quantity, 
f.Unit_Price as Unit_Price,
f.Discount as Discount,
(f.Quantity*f.Unit_Price - f.Discount) as Billing_amount, 
f.Weight as Weight,
f.Units_on_order as Units_on_order,
f.Units_in_stock as Units_in_stock,
f.reorder_level as Reorder_level,
f.OrderDate as OrderDate, 
f.ShippedDate as ShippedDate
FROM Facts f 
JOIN DIM_ORDERS od ON (f.orderID = od.OrderID)
JOIN DIM_CUSTOMERS cd on (f.CustomerID = cd.CustomerID)
JOIN DIM_LOCATION td on (f.territoryID = td.territoryID)
JOIN DIM_PRODUCTS pd on (f.ProductID = pd.ProductID)
JOIN DIM_SHIPPERS shd on (f.ShipperID = shd.ShipperID)
JOIN DIM_SUPPLIERS sd on (f.SupplierID = sd.SupplierID)
JOIN DIM_JUNK jd on (f.productID = jd.ProductID);

ALTER TABLE PRODUCT_FACTS 
ADD (
Constraint DIM_Products_FK FOREIGN KEY (ProductID) references DIM_PRODUCTS,
Constraint DIM_CUSTOMERS_FK FOREIGN KEY (CustomerID) references DIM_CUSTOMERS,
Constraint DIM_SHIPPERS_FK FOREIGN KEY (ShipperID) references DIM_SHIPPERS,
Constraint DIM_ORDERS_FK FOREIGN KEY (OrderId) references DIM_ORDERS,
Constraint DIM_JUNK_FK FOREIGN KEY (JunkID) references JUNK_DIM,
Constraint DIM_LOCATION_FK FOREIGN KEY (TerritoryID) references DIM_LOCATION,
Constraint DIM_SUPPLIER_FK FOREIGN KEY (SupplierID) references DIM_SUPPLIERS
);


ALTER TABLE JUNK_DIM
DROP COLUMN ProductID ;


--- Facts table made by joining all primary keys from needed tables
--- Dimensions made by joining tables to the facts table





