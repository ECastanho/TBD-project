-- This code contains every code to test query 3 and related tasks 


SELECT * FROM reorder;

SELECT * FROM inventory ORDER BY quan_in_stock DESC;
SELECT * FROM inventory ORDER BY quan_in_stock ASC;

SELECT * FROM customers ORDER BY customerid DESC LIMIT 3 ;

DELETE FROM reorder;

SELECT auto_reorder('2018-11-01','2018-11-01');

--CREATING TEST VARIABLES
INSERT INTO inventory VALUES (10001, 5000, 4);
INSERT INTO customers VALUES (20001,'VKUUXF','ITHOMQJNYX','4608499546 Dell Way',null,'QSDPAGD','SD',24101,'US',1,'ITHOMQJNYX@dell.com','4608499546',1,'1979279217775911','2012/03','user20001','password',55,100000,'M');
INSERT INTO products VALUES (10001,14,'ACADEMY ACADEMY','ENELOPE GUINESS',25.99,0,1976);


UPDATE inventory SET quan_in_stock = 5000 WHERE prod_id = 10001;
SELECT * FROM inventory WHERE prod_id=10001;
SELECT * FROM reorder WHERE prod_id = 10001;


SELECT * FROM products ORDER BY prod_id DESC LIMIT 1;
SELECT * FROM customers ORDER BY customerid DESC LIMIT 1;
SELECT * FROM inventory ORDER BY prod_id DESC LIMIT 1;

SELECT create_order (20001,'{10001}','{1}',1);

SELECT * FROM cust_hist WHERE customerid = 20001;

SELECT * FROM orderlines ORDER BY orderid DESC LIMIT 40;
