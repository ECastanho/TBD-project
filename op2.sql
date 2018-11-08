CREATE OR REPLACE FUNCTION buy_popular_products(
	selected_customer customers.customerid%TYPE) -- recieves customer id
RETURNS void AS $$
DECLARE
	current_product products.prod_id%TYPE;
	j integer :=1; -- order of search
	search_check boolean;
	counter integer;
	categoriesidlist integer [];
	k integer;
	products_for_order integer [];
	quantities_for_order integer [];
	category_count integer; --used to avoid infinite loop
BEGIN

	--defining counter
	counter := (SELECT COUNT(*) FROM categories); --number of categories

	FOR i IN 1 .. counter LOOP
		categoriesidlist[i] := (SELECT category FROM categories ORDER BY category LIMIT 1 OFFSET (i-1));
	END LOOP;
	

	FOR cat IN 1.. counter LOOP
		j := 1; -- This needs to be reseted each time we enter into a new category
		k := categoriesidlist[cat];
		--First Order verification and decision
		category_count:=(SELECT COUNT(*) FROM products WHERE category = categoriesidlist[cat]);

		current_product := decision(k,j); --fetches most popular product
		search_check := check_cust_hist(selected_customer,current_product); --checks if it's been bought
		WHILE(search_check = FALSE AND j <= category_count) LOOP
			j= j+1;
			current_product := decision(k,j);
			search_check := check_cust_hist(selected_customer,current_product);
		END LOOP; -- repeats until never bought product is selected
			
		products_for_order[k] := current_product;
		quantities_for_order[k] := 1; --we're only adding one copy of each

	END LOOP;

	PERFORM create_order(selected_customer,products_for_order,quantities_for_order, 0.23);
END;
$$ LANGUAGE plpgsql;


--AUXILIAR FUNCTIONS

CREATE OR REPLACE FUNCTION check_cust_hist(
	selected_customer customers.customerid%TYPE,-- recieves customer id
	selected_product products.prod_id%TYPE) -- recieves product for comparison

RETURNS boolean AS $$

DECLARE 
	buy_check boolean; 
	bought_number integer; -- number of bought products by selected customer

BEGIN
	--These Tables will be created to solve a problem (*). There isn't a real need for them to physically exist.
	CREATE TABLE our_customer (num INTEGER);
	INSERT INTO our_customer (num) VALUES (selected_customer); -- Creates table with only customer id
	CREATE TABLE our_product (num INTEGER);
	INSERT INTO our_product (num) VALUES (selected_product); -- Creates table with only product id


	--history_list: view that contains a list of bought products
	CREATE OR REPLACE VIEW history_list AS 
	SELECT ch.prod_id
	FROM cust_hist ch, our_customer c
	WHERE ch.customerid = c.num; --*

	--number of bought articles. 
	bought_number := (SELECT COUNT(*) 
			FROM history_list); 
			
	IF (bought_number = 0) THEN 
		buy_check := TRUE; -- The user hasn't bought the product (or any products, actually) 
	ELSE
		IF EXISTS(SELECT DISTINCT hl.prod_id 
			FROM history_list hl, our_product p, cust_hist ch, our_customer c
			WHERE hl.prod_id = p.num AND ch.customerid = c.num) --* --checks if selected product is in the list of bought products -- distinct because product can be bought more than once
		THEN
		  buy_check := FALSE; --product in list ->> keep searching
		ELSE 
			buy_check := TRUE; -- product not in list ->> move with purchase
		END IF; -- prod_id if.
	END IF; -- If that checks bought_number = 0 

--cleaning the created TABLEs and Views...
DROP VIEW history_list;
DROP TABLE our_customer;
DROP TABLE our_product;

RETURN buy_check;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION decision(
	selected_category categories.category%TYPE,-- recieves category
	k integer) -- order of choice
RETURNS integer AS $$
DECLARE 
	k_most_popular_product products.prod_id%TYPE;

BEGIN
	
	CREATE TABLE cat_num (num INTEGER);
	INSERT INTO cat_num (num) VALUES (selected_category); -- *needed because the view was using selected_category as a column name
	
	
	CREATE OR REPLACE VIEW product_list AS 
	SELECT p.prod_id, i.sales, i.quan_in_stock
	FROM products p, inventory i, cat_num cm
	WHERE p.prod_id = i.prod_id AND p.category = cm.num
	ORDER BY i.sales DESC, i.quan_in_stock DESC; --- gives ordered list of products, 1st by sales, then by quan_in_stock

	k_most_popular_product := (SELECT prod_id
							FROM product_list
							LIMIT 1 OFFSET k-1);	--contains id of k-th most popular product

	DROP VIEW product_list;
	DROP TABLE cat_num;
	
	RETURN k_most_popular_product;

END;
$$ LANGUAGE plpgsql;
