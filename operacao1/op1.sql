CREATE OR REPLACE FUNCTION halloween_discount (id_order orders.orderid%TYPE)
RETURNS numeric AS $$
DECLARE
    discount decimal := 0;
    ntotalamount     orders.totalamount%TYPE;
    h_price     orders.totalamount%TYPE;
    other_price    orders.totalamount%TYPE;
    quantity    orderlines.quantity%TYPE;
    order_date     orders.orderdate%TYPE;
    a        orders.orderid%TYPE;
BEGIN
order_date := (SELECT O.orderdate FROM orders O WHERE O.orderid = id_order);
              
IF (date_part('month', order_date)=10 AND date_part('day', order_date) BETWEEN 24 AND 31) -- If it is Halloween week, the function returns 1 (true)
THEN   

    -- "Count" how many Horror movies exist in that order
    quantity:=( SELECT SUM(OL.quantity) FROM orderlines OL, orders O, products P
             WHERE O.orderid = OL.orderid
             AND P.prod_id = OL.prod_id
             AND O.orderid = id_order AND P.category = 11);


    IF quantity IS NOT NULL
    THEN
               
        -- Horror movies' price
        h_price := (SELECT SUM(OL.quantity*P.price) FROM orderlines OL, orders O, products P
             WHERE O.orderid = OL.orderid
             AND P.prod_id = OL.prod_id
             AND O.orderid = id_order AND P.category = 11);
        -- Other movies' price
        other_price := (SELECT SUM(OL.quantity*P.price) FROM orderlines OL, orders O, products P
             WHERE (O.orderid = OL.orderid
             AND P.prod_id = OL.prod_id
             AND O.orderid = id_order AND P.category != 11));
        -- They could actually be zero.
        IF other_price IS NULL
        THEN
        other_price:=0;
        END IF;

        -- Assign discount according to number of movies acquired
        IF quantity>0 AND quantity<5
        THEN
            discount:=0.1+(quantity*0.05);
            ELSE IF quantity>=5
            THEN
                discount:=0.35;
            END IF;
        END IF;

        -- Calculate total amount with discount
        ntotalamount := other_price + (h_price * (1-discount));

        UPDATE orders SET totalamount = ntotalamount WHERE orderid = id_order;
    END IF; -- are any horror movies?
END IF;
RETURN 0;
END;
$$ LANGUAGE plpgsql;

