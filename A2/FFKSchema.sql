
DROP TABLE IF EXISTS MenuItem;
DROP TABLE IF EXISTS MilkKind;
DROP TABLE IF EXISTS CoffeeType;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Staff;
SET datestyle = 'DMY';
CREATE TABLE Staff
(
	StaffID		VARCHAR(10)		PRIMARY KEY,
	Password	VARCHAR(30)		NOT NULL,
	FirstName	VARCHAR(30)		NOT NULL,
	LastName	VARCHAR(30)		NOT NULL,
	Age			INTEGER			NOT NULL CHECK (Age > 21),
	Salary		DECIMAL(9,2)	NOT NULL CHECK (Salary > 0)
);

CREATE TABLE Category
(
	CategoryID		SERIAL	PRIMARY KEY,
	CategoryName	VARCHAR(10) UNIQUE NOT NULL,
	CategoryDesc	VARCHAR(40)	NOT NULL
);

CREATE TABLE CoffeeType
(
	CoffeeTypeID	SERIAL	PRIMARY KEY,
	CoffeeTypeName	VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE MilkKind
(
	MilkKindID		SERIAL	PRIMARY KEY,
	MilkKindName	VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE MenuItem
(
	MenuItemID		SERIAL			PRIMARY KEY,
	Name			VARCHAR(30)		NOT NULL,
	Description		VARCHAR(150),
	CategoryOne		INTEGER			NOT NULL REFERENCES Category,
	CategoryTwo		INTEGER			REFERENCES Category,
	CategoryThree	INTEGER			REFERENCES Category,
	CoffeeType		INTEGER			REFERENCES CoffeeType,
	MilkKind		INTEGER			REFERENCES MilkKind,
	Price			DECIMAL(6,2)	NOT NULL,
	ReviewDate		DATE,
	Reviewer		VARCHAR(10) 	REFERENCES Staff
);

INSERT INTO Staff VALUES ('ajones','098','Anna','Jones',25,41000);
INSERT INTO Staff VALUES ('ganderson','987','Glen','Anderson',30,49500.80);
INSERT INTO Staff VALUES ('jwalker','876','James','Walker',22,38890.50);
INSERT INTO Staff VALUES ('janedoe','765','Jane','Doe',26,43900.20);
INSERT INTO Staff VALUES ('johndoe','654','John','Doe',22,38000);
INSERT INTO Staff VALUES ('njohnson','543','Neil','Johnson',27,4500);
INSERT INTO Staff VALUES ('nbrown','432','Nicole','Brown',41,68100.90);
INSERT INTO Staff VALUES ('rtatum','321','Robert','Tatum',39,62400);
INSERT INTO Staff VALUES ('rmarrick','210','Ryu','Marrick',36,59900.20);
INSERT INTO Staff VALUES ('tcolemen','109','Tom','Coleman',24,48000);

INSERT INTO Category VALUES (1,'Breakfast','Menu item to be offered for breakfast');
INSERT INTO Category VALUES (2,'Lunch','Menu item to be offered for lunch');
INSERT INTO Category VALUES (3,'Dinner','Menu item to be offered for dinner');

INSERT INTO CoffeeType VALUES (1,'Espresso');
INSERT INTO CoffeeType VALUES (2,'Latte');
INSERT INTO CoffeeType VALUES (3,'Cappuccino');
INSERT INTO CoffeeType VALUES (4,'LongBlack');
INSERT INTO CoffeeType VALUES (5,'ColdBrew');

INSERT INTO MilkKind VALUES (1,'Whole');
INSERT INTO MilkKind VALUES (2,'Skim');
INSERT INTO MilkKind VALUES (3,'Soy');
INSERT INTO MilkKind VALUES (4,'Almond');
INSERT INTO MilkKind VALUES (5,'Oat');

INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('French Toast','A sliced bread soaked in beaten eggs, milk, and cream, then pan-fried with butter',1,NULL,NULL,NULL,NULL,9.90,'10/01/2024','johndoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Eggs Benedict','An English muffin, toasted, and topped with bacon, poached eggs, and classic French hollandaise sauce',1,2,NULL,NULL,NULL,12.80,'18/02/2024','janedoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Poke Bowl','Cubes of marinated fish tossed over rice and topped with vegetables and Asian-inspired sauces',1,2,3,NULL,NULL,15.90,'28/02/2024','johndoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Orange Juice','A fresh, sweet, and juicy drink with orange bits made from freshly squeezed oranges',1,2,3,NULL,NULL,6.50,'01/03/2024','janedoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('White Coffee','A full-flavored concentrated form of coffee served in small, strong shots with whole milk',1,2,NULL,1,1,3.50,'22/03/2024','rtatum');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Black Coffee',NULL,1,2,3,4,NULL,4.30,NULL,NULL);
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Coffee Drink',NULL,1,2,NULL,3,3,3.50,'28/02/2024','johndoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Seafood Cleopatra','Salmon topped with prawns in a creamy seafood sauce. Served with salad and chips',3,NULL,NULL,NULL,NULL,25.90,'20/02/2024','johndoe');
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Iced Coffee','A glass of cold espresso, milk, ice cubes, and a scoop of ice cream',1,2,NULL,2,1,7.60,NULL,NULL);
INSERT INTO MenuItem (Name,Description,CategoryOne,CategoryTwo,CategoryThree,CoffeeType,MilkKind,Price,ReviewDate,Reviewer) VALUES 
	('Coffee Pancake','A short stack of pancakes flecked with espresso powder and mini chocolate chips',1,NULL,NULL,NULL,NULL,8.95,'08/04/2014','janedoe');

COMMIT;



CREATE OR REPLACE FUNCTION AddNewMenuItem(
	name VARCHAR,
	description VARCHAR,
	categoryone VARCHAR,
	categorytwo VARCHAR,
	categorythree VARCHAR,
	coffeetype VARCHAR,
	milkkind VARCHAR,
	price VARCHAR) RETURNS VOID AS $$
DECLARE
	categoryoneId		INTEGER;
	categorytwoId		INTEGER;
	categorythreeId		INTEGER;
	coffeetypeId		INTEGER;
	milkkindId			INTEGER;
	decimalPrice		DECIMAL(6,2);
BEGIN
	-- check if the coffeetype is specified if given milktype
	IF		(milkkind != '' AND coffeetype = '')
	THEN 	RAISE EXCEPTION 'the coffetype must be specified if the milktype is given';
	END IF;

	--  turn category to category id
	IF		categoryone != ''
	THEN 	categoryoneId := GetCategoryIdByName(categoryone);
			IF 		(categoryoneId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	IF		categorytwo != ''
	THEN 	categorytwoId := GetCategoryIdByName(categorytwo);
			IF 		(categorytwoId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	IF		categorythree != ''
	THEN 	categorythreeId := GetCategoryIdByName(categorythree);
			IF 		(categorythreeId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	-- the category cannot be the same
	IF		(categoryoneId IS NOT NULL
			AND categorytwoId IS NOT NULL
			AND categoryoneId = categorytwoId)
			OR
			(categoryoneId IS NOT NULL
			AND categorythreeId IS NOT NULL
			AND categoryoneId = categorythreeId)
			OR
			(categorytwoId IS NOT NULL
			AND categorythreeId IS NOT NULL
			AND categorytwoId = categorythreeId)
	THEN 	RAISE EXCEPTION 'Two category can not be the same';
	END IF;

 	-- turn coffee to coffee id
	IF		coffeetype != ''
	THEN 	coffeetypeId := GetCoffeeTypeIdByName(coffeetype);
			IF 		(coffeetypeId IS NULL)
			THEN 	RAISE EXCEPTION 'The coffee cannot be found';
			END IF;
	END IF;

 	-- turn milkkind to milkkind id
	IF		milkkind != ''
	THEN 	milkkindId := GetMilkKindIdByName(milkkind);
			IF 		(milkkindId IS NULL)
			THEN 	RAISE EXCEPTION 'The milkkind cannot be found';
			END IF;
	END IF;

	-- format price
 	BEGIN
         decimalPrice := CAST(price AS DECIMAL(6,2));
    EXCEPTION
         WHEN others THEN
             RAISE EXCEPTION 'the price format should be like 1.23';
    END;

	-- check if the price is negtive
	IF	decimalPrice < 0
	THEN RAISE EXCEPTION 'the price cannot be negtive';
	END IF;

	-- insert the new item
	BEGIN
		INSERT INTO MenuItem(
			Name,
			Description,
			CategoryOne,
			CategoryTwo,
			CategoryThree,
			CoffeeType,
			MilkKind,
			Price)
		VALUES(
			name,
			description,
			categoryoneId,
			categorytwoId,
			categorythreeId,
			coffeetypeId,
			milkkindId,
			decimalPrice
		);
	EXCEPTION
         WHEN others THEN
             RAISE EXCEPTION 'There is error when insert new item';
    END;

END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION GetCategoryIdByName(name VARCHAR) RETURNS INTEGER AS $$
DECLARE
	result		INTEGER;
BEGIN
	SELECT CategoryID INTO result
	FROM Category
	WHERE lower(CategoryName) = lower(name);

	RETURN result;
END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION GetCoffeeTypeIdByName(name VARCHAR) RETURNS INTEGER AS $$
DECLARE
	result		INTEGER;
BEGIN
	SELECT CoffeeTypeID INTO result
	FROM CoffeeType
	WHERE lower(CoffeeTypeName) = lower(name);

	RETURN result;
END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION GetMilkKindIdByName(name VARCHAR) RETURNS INTEGER AS $$
DECLARE
	result		INTEGER;
BEGIN
	SELECT MilkKindID INTO result
	FROM MilkKind
	WHERE lower(MilkKindName) = lower(name);

	RETURN result;
END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION GetReviewerIdByFullName(reviewer VARCHAR) RETURNS VARCHAR AS $$
DECLARE
	result		VARCHAR;
BEGIN
	SELECT StaffID INTO result
	FROM Staff
	WHERE lower(CONCAT(FirstName, ' ', LastName)) = lower(reviewer) OR lower(StaffID) = lower(reviewer);

	RETURN result;
END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION CheckStaffIdExist(reviewer VARCHAR) RETURNS VARCHAR AS $$
DECLARE
	result 		VARCHAR;
BEGIN
	SELECT StaffID INTO result
	FROM Staff
	WHERE lower(StaffID) = lower(reviewer);

	RETURN result;
END; $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION UpdateMenuItem(
	menuitem_id_param INTEGER,
	name_param VARCHAR,
	description_param VARCHAR,
	categoryone VARCHAR,
	categorytwo VARCHAR,
	categorythree VARCHAR,
	coffeetype VARCHAR,
	milkkind VARCHAR,
	price VARCHAR,
	reviewDate_param DATE,
	reviewer_param VARCHAR
) RETURNS VOID AS $$
DECLARE
	categoryoneId		INTEGER;
	categorytwoId		INTEGER;
	categorythreeId		INTEGER;
	coffeetypeId		INTEGER;
	milkkindId			INTEGER;
	decimalPrice		DECIMAL(6,2);
	reviewerId 			VARCHAR;
	error_message TEXT;
BEGIN
	-- check if the coffeetype is specified if given milktype
	IF		(milkkind != '' AND coffeetype = '')
	THEN 	RAISE EXCEPTION 'the coffetype must be specified if the milktype is given';
	END IF;

	--  turn category to category id
	IF		categoryone != ''
	THEN 	categoryoneId := GetCategoryIdByName(categoryone);
			IF 		(categoryoneId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	IF		categorytwo != ''
	THEN 	categorytwoId := GetCategoryIdByName(categorytwo);
			IF 		(categorytwoId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	IF		categorythree != ''
	THEN 	categorythreeId := GetCategoryIdByName(categorythree);
			IF 		(categorythreeId IS NULL)
			THEN 	RAISE EXCEPTION 'The category cannot be found';
			END IF;
	END IF;

	-- the category cannot be the same
	IF		(categoryoneId IS NOT NULL
			AND categorytwoId IS NOT NULL
			AND categoryoneId = categorytwoId)
			OR
			(categoryoneId IS NOT NULL
			AND categorythreeId IS NOT NULL
			AND categoryoneId = categorythreeId)
			OR
			(categorytwoId IS NOT NULL
			AND categorythreeId IS NOT NULL
			AND categorytwoId = categorythreeId)
	THEN 	RAISE EXCEPTION 'Two category can not be the same';
	END IF;

 	-- turn coffee to coffee id
	IF		coffeetype != ''
	THEN 	coffeetypeId := GetCoffeeTypeIdByName(coffeetype);
			IF 		(coffeetypeId IS NULL)
			THEN 	RAISE EXCEPTION 'The coffee cannot be found';
			END IF;
	END IF;

 	-- turn milkkind to milkkind id
	IF		milkkind != ''
	THEN 	milkkindId := GetMilkKindIdByName(milkkind);
			IF 		(milkkindId IS NULL)
			THEN 	RAISE EXCEPTION 'The milkkind cannot be found';
			END IF;
	END IF;

	-- format price
 	BEGIN
         decimalPrice := CAST(price AS DECIMAL(6,2));
    EXCEPTION
         WHEN others THEN
             RAISE EXCEPTION 'the price format should be like 1.23';
    END;

	-- check if the price is negtive
	IF	decimalPrice < 0
	THEN RAISE EXCEPTION 'the price cannot be negtive';
	END IF;

	-- check if a reviewer id exist
	reviewer_param := trim(reviewer_param);
	reviewerId := CheckStaffIdExist(reviewer_param);
	IF 		reviewerId IS NULL
	THEN
		-- turn reviewer full name to reviewer id
		IF		reviewer_param != ''
		THEN 	reviewerId := GetReviewerIdByFullName(reviewer_param);
				IF 		(reviewerId IS NULL)
				THEN 	RAISE EXCEPTION 'The reviewer cannot be found';
				END IF;
		END IF;
	END IF;

	-- update the item
	BEGIN
		UPDATE MenuItem
		SET Name = name_param,
			Description = description_param,
			CategoryOne = categoryoneId,
			CategoryTwo = categorytwoId,
			CategoryThree = categorythreeId,
			CoffeeType = coffeetypeId,
			MilkKind = milkkindId,
			Price = decimalPrice,
			ReviewDate = reviewDate_param,
			Reviewer = reviewerId
		WHERE MenuItemID = menuitem_id_param;
	EXCEPTION
		WHEN others THEN
			GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
			RAISE EXCEPTION 'failed to update new item %', error_message;
	END;

END; $$ LANGUAGE plpgsql;