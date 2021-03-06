
CREATE OR REPLACE FUNCTION auto_reorder(
	datelow    reorder.date_low%TYPE,
	datereord  reorder.date_reordered%TYPE)
	RETURNS numeric as $$
DECLARE
numentries numeric;
Vquan_in_stock inventory.quan_in_stock%TYPE;
Vsales         inventory.sales%TYPE;
i 				integer;
BEGIN


SELECT COUNT(prod_id) FROM inventory INTO numentries;

FOR k IN 1 .. numentries LOOP 

	i := (SELECT prod_id FROM inventory ORDER BY prod_id LIMIT 1 OFFSET (k-1));


	SELECT quan_in_stock FROM inventory WHERE prod_id = i INTO Vquan_in_stock;
	IF(Vquan_in_stock IS NOT NULL) THEN                                           -- checking if the tuple with prod_id = i exists 
		SELECT sales FROM inventory WHERE prod_id = i INTO Vsales;
		IF (Vsales >= 5) THEN                                      -- IF the article is popular
			IF (Vquan_in_stock < 2*Vsales) THEN                    -- If there is a lack in stock
				PERFORM new_reorder(i, datelow, datereord, 2*Vsales); --order more units
			END IF;
		ELSE                                                        -- If the article isn't popular 
			IF (Vquan_in_stock < 5) THEN                            -- If there is a lack in stock
				PERFORM new_reorder(i, datelow, datereord, 5); --order more units
			END IF;	
		END IF;
	END IF;
END LOOP;	
RETURN 0;
END;
$$ LANGUAGE plpgsql;



--AUXILIAR FUNCTIONS
CREATE OR REPLACE FUNCTION new_reorder(
	prodid    reorder.prod_id%TYPE, 
	datelow   reorder.date_low%TYPE,
	datereord  reorder.date_reordered%TYPE,
	quantord  reorder.quan_reordered%TYPE)
	RETURNS numeric AS $$
DECLARE
	quantlow  reorder.quan_low%TYPE;
BEGIN
	SELECT quan_in_stock FROM inventory WHERE prod_id = prodid INTO quantlow;
	IF (prodid IS NOT NULL) THEN -- Test if the id is valid. The product for reordering must exist
		INSERT INTO reorder (prod_id, date_low, quan_low,date_reordered,quan_reordered,date_expected) 
		VALUES (prodid, datelow, quantlow, datereord,quantord, null);
		RETURN 0;
	ELSE
		RETURN -1; -- should mean error. 
	END IF;
END;
$$ LANGUAGE plpgsql;
