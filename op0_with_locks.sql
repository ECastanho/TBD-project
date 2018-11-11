-- MAIN FUNCTION


CREATE OR REPLACE FUNCTION create_order_with_locks (
    customer_id  	customers.customerid%TYPE,
    ordered_products 	integer [],
    quantity_products	integer [],
    dtax		orders.tax%TYPE)
      RETURNS numeric AS $$
DECLARE
	order_date 		orders.orderdate%TYPE:= now();
	index			integer := 1;
	number_prod 		integer := array_length(ordered_products, 1);
	product_id 		integer;
	quantity_ordered 	integer;
	available_stock 	integer;
	prod_price 		products.price%TYPE;
	dnetamount  		orders.netamount%TYPE := 0;
	order_id		orders.orderid%TYPE;
BEGIN

	--Creating an empty order
	order_id := (SELECT generate_empty_order_with_locks(customer_id, order_date));
	-- For each item in the order
	WHILE index <= number_prod LOOP	--FOR selected_item IN ordered_products 
		product_id := ordered_products[index];
		quantity_ordered := quantity_products[index];
		-- Check quantity in stock
		SELECT quan_in_stock INTO available_stock
		FROM inventory
		WHERE prod_id = product_id;
		-- Check if there is enough stock for the product
		IF (quantity_ordered <= available_stock) THEN
			-- Create new orderline for the item
			PERFORM createorderline(order_id,product_id, quantity_ordered);
			-- Update inventory (stock up, sales down)
			PERFORM upgrade_inventory(product_id, quantity_ordered);
			-- Get price of the item
			SELECT products.price INTO prod_price
			FROM products
			WHERE products.prod_id = product_id;
			-- Update netamount
			dnetamount := dnetamount + prod_price * quantity_ordered;
			-- Insert order into cust_hist
			INSERT INTO cust_hist (customerid, orderid, prod_id)
			VALUES (customer_id, order_id, product_id);
		ELSE
			RAISE EXCEPTION 'ERROR: Not enough quantity available for product %',  product_id;
			RETURN -1;
		END IF;
		index := index + 1;
	END LOOP; -- WHILE number_prod
	-- Update the order

	UPDATE orders
	SET  netamount = dnetamount, tax = dtax * dnetamount, totalamount = dnetamount * (1 + dtax)
	WHERE orderid = order_id;

	RETURN 0;
END;
$$ LANGUAGE plpgsql;



--AUXILIAR FUNCTIONS

CREATE OR REPLACE FUNCTION generate_empty_order_with_locks(
	customer_id  customers.customerid%TYPE,
	orderdate orders.orderdate%TYPE)
	RETURNS orders.orderid%TYPE AS $$
DECLARE
	order_id	orders.orderid%TYPE;
BEGIN
--LOCK	
LOCK orders IN  ACCESS EXCLUSIVE MODE;
											 
	order_id := (SELECT MAX(orderid)+1 FROM orders);
						 

	INSERT INTO orders (orderid, customerid, orderdate, netamount, tax, totalamount)
	VALUES (order_id, customer_id, orderdate, 0, 0, 0); 
	RETURN order_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION createorderline(
	order_id	orderlines.orderid%TYPE, 
	prodid  	orderlines.prod_id%TYPE,
	iquantity	integer)
	RETURNS numeric AS $$
DECLARE
	maxorderlineid	orderlines.orderlineid%TYPE;
	cdate		orderlines.orderdate%TYPE;
BEGIN
	cdate := (SELECT orderdate FROM orders WHERE orderid = order_id);

	----Calculating orderlineid
	--if if the first request of the day its 1, Else its max()+1
	maxorderlineid := (SELECT MAX(orderlineid) FROM orderlines WHERE orderdate = cdate);
	IF (maxorderlineid IS NULL) THEN 
		maxorderlineid := 1;
	ELSE
		maxorderlineid := maxorderlineid + 1;
	END IF;
	INSERT INTO orderlines (orderlineid,orderid,prod_id,quantity, orderdate)
	VALUES (maxorderlineid,order_id, prodid,iquantity,cdate);
RETURN 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upgrade_inventory(
	prodid	orderlines.prod_id%TYPE,
	quantity_ordered integer
	)
	RETURNS numeric AS $$
BEGIN
-- Update inventory (stock up, sales down)
UPDATE inventory
SET quan_in_stock = (quan_in_stock - quantity_ordered), sales = (sales + quantity_ordered)
WHERE prod_id = prodid;
RETURN 0;
END;
$$ LANGUAGE plpgsql;