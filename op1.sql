CREATE OR REPLACE FUNCTION halloween_discount (id_order orders.orderid%TYPE)
RETURNS numeric AS $$
DECLARE
	discount decimal := 0;
	ntotalamount orders.totalamount%TYPE;
	h_price orders.totalamount%TYPE;
	other_price orders.totalamount%TYPE;
	quantity orderlines.quantity%TYPE;
BEGIN
-- Check if it is Halloween week
IF (is_it_halloween(id_order)) -- If it is Halloween week, the function returns 1 (true)
THEN	
	-- "Count" how many Horror movies exist in that order
	quantity := (SELECT SUM(OL.quantity)
				 FROM orderlines OL, orders O, products P
				 WHERE O.orderid = OL.orderid
				 AND P.prod_id = OL.prod_id
				 AND P.category = 11
				 AND O.orderid = id_order);

	-- Assign discount according to number of movies acquired
	IF quantity>0 AND quantity<5
	THEN
		discount:=0.1+(quantity*0.05);

		ELSE IF quantity>=5
		THEN
			discount:=0.35;

		END IF;
	END IF;
					
	-- Horror movies' price
	h_price := (SELECT SUM(P.price * OL.quantity)
				FROM orderlines OL, orders O, products P
				WHERE O.orderid = OL.orderid
				AND P.prod_id = OL.prod_id
				AND O.orderid=id_order
				AND P.category = 11);

	-- Other movies' price
	other_price := (SELECT SUM(P.price * OL.quantity)
					FROM orderlines OL, orders O, products P
					WHERE O.orderid = OL.orderid
					AND P.prod_id = OL.prod_id
					AND O.orderid=id_order
					AND P.category != 11);
	
	-- Calculate total amount with discount
	ntotalamount := other_price + (h_price * (1-discount));

	UPDATE orders SET totalamount = ntotalamount WHERE orderid = id_order;

ELSE
	discount := 0;
	ntotalamount := (SELECT SUM(P.price * OL.quantity)
					FROM orderlines OL, orders O, products P
					WHERE O.orderid = OL.orderid
					AND P.prod_id = OL.prod_id
					AND O.orderid=id_order);

END IF;
RETURN ntotalamount;
END;
$$ LANGUAGE plpgsql;


--AUXILIAR FUNCTIONS

CREATE OR REPLACE FUNCTION is_it_halloween(id_order orders.orderid%TYPE )
RETURNS bit AS $$
DECLARE
	order_date orders.orderdate%TYPE;
BEGIN
order_date := (SELECT orderdate
			   FROM orders O
			   WHERE O.orderid = id_order);
			  
IF ( date_part('month', order_date)=10
	 AND date_part('day', order_date) BETWEEN 24 AND 31 ) 
THEN
	RETURN 1;
ELSE
	RETURN 0;
END IF;
END;
$$ LANGUAGE plpgsql;
