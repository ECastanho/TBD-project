CREATE OR REPLACE FUNCTION auto_reorder_with_locks(
	datelow    reorder.date_low%TYPE,
	datereord  reorder.date_reordered%TYPE)
	RETURNS numeric as $$
DECLARE
k 			record;
BEGIN
LOCK inventory IN ACCESS EXCLUSIVE MODE;

FOR k IN SELECT prod_id,quan_in_stock,sales FROM inventory
LOOP 
	IF (k.sales >= 5) THEN                                      -- IF the article is popular
		IF (k.quan_in_stock < 2*k.sales) THEN                    -- If there is a lack in stock
			INSERT INTO reorder (prod_id,   date_low, quan_low,        date_reordered, quan_reordered, date_expected) 
			VALUES              (k.prod_id, datelow,  k.quan_in_stock, datereord,      2*k.sales,      null);
		END IF;
	ELSE                                                        -- If the article isn't popular 
		IF (k.quan_in_stock < 5) THEN                            -- If there is a lack in stock
			INSERT INTO reorder (prod_id,   date_low, quan_low,        date_reordered, quan_reordered, date_expected) 
			VALUES              (k.prod_id, datelow,  k.quan_in_stock, datereord,      5,   	   null);
		END IF;	
	END IF;
END LOOP;	
RETURN 0;
COMMIT;
END;
$$ LANGUAGE plpgsql;
