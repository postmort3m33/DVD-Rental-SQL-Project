-------------------
-- Create Tables --
-------------------

create table detailed_report (
	customer_id INT UNIQUE NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	address VARCHAR(50) NOT NULL,
	address2 VARCHAR(50),
	city VARCHAR(50) NOT NULL,
	postal_code VARCHAR(10),
	country VARCHAR (50) NOT NULL
);

create table summarized_report (
	num_customers int NOT NULL,
	country VARCHAR (50) NOT NULL
);

--SELECT * FROM detailed_report;




----------------------
-- Extract Raw Data --
----------------------

insert into detailed_report
	select customer.customer_id, customer.first_name, customer.last_name,
		   address.address, address.address2, city.city, address.postal_code,
		   country.country
	from customer, address, city, country
	where customer.address_id = address.address_id
	and address.city_id = city.city_id
	and city.country_id = country.country_id
	order by country.country_id;

--SELECT * FROM detailed_report;



----------------------------------
-- Create User Defined Function --
----------------------------------

create function combine_address(address text, address2 text)
returns text
language plpgsql
as
$$
declare
	new_address text;
begin

	-- Set new Address
	new_address = address || ' ' || address2;

	-- return it
	return new_address;
end;
$$;

--update detailed_report
--set address2 = 'Apt#2'
--where customer_id = 1;

--update detailed_report
--set address2 = 'Apt#2'
--where customer_id = 2;

--select customer_id, first_name, last_name, combine_address(address, address2) as new_address
--from detailed_report
--where customer_id = 1 or customer_id = 2;


--------------------
-- Create Trigger --
--------------------

create function update_summarized_table()
returns trigger
language plpgsql
as
$$
begin
	-- Delete all summarized table info..
	delete from summarized_report;
	-- Redo table with new counts..
	insert into summarized_report
		select count(detailed_report.country) as numCustomers, detailed_report.country
		from detailed_report
		group by detailed_report.country
		order by numCustomers desc;

	return new;
end;
$$;


--create trigger update_summarized_table_trigger
--after insert
--on detailed_report
--for each statement
--execute procedure update_summarized_table()


--INSERT into detailed_report
--VALUES (999, 'James', 'Touchstone', '17911 Kings Park Ln', 'Apt#1202',
--		'Houston', '77058', 'United States');

--SELECT * FROM summarized_report;

--INSERT into detailed_report
--VALUES (1000, 'Elisa', 'Combs', '17911 Kings Park Ln', 'Apt#1202',
--		'Houston', '77058', 'United States');

--SELECT * FROM summarized_report;



-----------------------------
-- Create Stored Procedure --
-----------------------------

create procedure refresh_reports()
language plpgsql
as $$
begin

	-- clear both tables..
	delete from detailed_report;
	delete from summarized_report;

	-- Add data into detailed report..
	insert into detailed_report
	select customer.customer_id, customer.first_name, customer.last_name,
		address.address, address.address2, city.city, address.postal_code,
		country.country
	from customer, address, city, country
	where customer.address_id = address.address_id
	and address.city_id = city.city_id
	and city.country_id = country.country_id
	order by country.country_id;

	-- now tranform into summarized report..
	insert into summarized_report
	select count(detailed_report.country) as numCustomers, detailed_report.country
	from detailed_report
	group by detailed_report.country
	order by numCustomers desc;

	-- Commit
	commit;
end;
$$;

--call refresh_reports()

--SELECT * from summarized_report;
