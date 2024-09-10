--stores info of customers
CREATE TABLE IF NOT EXISTS Customer (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL
);

--stores basic info of resturant orders
CREATE TABLE IF NOT EXISTS Res_Order (
    customization VARCHAR(30),
    total_charge decimal(18, 2),
    customer_id INTEGER,
    order_id integer NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer (customer_id),
    CONSTRAINT order_pkey PRIMARY KEY (order_id),
    CONSTRAINT unique_order UNIQUE (customization, total_charge, order_id)
);

--stores the infos of Resturant Tables
CREATE TABLE IF NOT EXISTS Resturant_Table (
    table_id INTEGER PRIMARY KEY,
    capacity INTEGER NOT NULL DEFAULT 0 CHECK(
        capacity BETWEEN 4
        and 8
    ),
    located VARCHAR(10) NOT NULL CHECK (located IN ('outside', 'inside'))
);

-- Stores the basic infos for food and drinks(items) in Menu
CREATE TABLE IF NOT EXISTS Menu_item (
    item_id INTEGER UNIQUE NOT NULL,
    item_name VARCHAR(20) NOT NULL,
    description VARCHAR(50),
    price DECIMAL(18, 2) NOT NULL,
    PRIMARY KEY (item_id)
);
-- stores the category of each menu item (breakfast or lunch)
CREATE TABLE IF NOT EXISTS Category (
    category_name VARCHAR(20) NOT NULL,
    category_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    PRIMARY KEY (category_id, item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- stores the Menu entities
CREATE TABLE IF NOT EXISTS Menu (
    menu_id INTEGER NOT NULL,
    season TEXT CHECK(
        season IN ('spring', 'summer', 'autumn', 'winter')
    ),
    PRIMARY KEY (menu_id)
);
-- stores the information of coffee in Menu items
CREATE TABLE IF NOT EXISTS Coffee (
    item_id INTEGER UNIQUE NOT NULL,
    coffee_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- stores the information of Food in Menu items
CREATE TABLE IF NOT EXISTS Food (
    item_id INTEGER NOT NULL,
    food_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- stores the information of Frappe in Menu items
CREATE TABLE IF NOT EXISTS Frappe (
    item_id INTEGER NOT NULL,
    frappe_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- stores the information of Fresh juice in Menu items

CREATE TABLE IF NOT EXISTS Fresh_juice (
    item_id INTEGER NOT NULL,
    juice_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- stores the many to many relation of menu item and it's menu.
CREATE TABLE IF NOT EXISTS Menu_item_is_Included_in_Menu (
    menu_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    PRIMARY KEY (menu_id, item_id),
    FOREIGN KEY (menu_id) REFERENCES Menu(menu_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- many to many relationship between Resturant orders and menu item
-- Stores the menu items added into Resturant order
CREATE TABLE IF NOT EXISTS Menu_item_in_Res_Order (
    menu_item_number INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    PRIMARY KEY (order_id, item_id),
    FOREIGN KEY (order_id) REFERENCES Res_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- store the information of milk kind for coffee, eg oat milk, full milk and diet milk
CREATE TABLE IF NOT EXISTS Coffee_milk(
    milk_name VARCHAR(20),
    milk_id SERIAL PRIMARY KEY NOT NULL
);
-- store the information of coffees in orders. 
-- it's a weak entity describing coffees that added into orders
CREATE TABLE IF NOT EXISTS Ordered_coffee (
    ordered_coffee_id INTEGER  NOT NULL,
    item_id INTEGER  NOT NULL,
    coffee_number INTEGER NOT NULL,
    milk_id INTEGER,
    order_id INTEGER  NOT NULL,
    PRIMARY KEY (ordered_coffee_id, milk_id, item_id, order_id),
    FOREIGN KEY (milk_id) REFERENCES Coffee_milk(milk_id),
    FOREIGN KEY (item_id) REFERENCES Coffee(item_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (order_id) REFERENCES Res_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- complementary items in menu
CREATE TABLE IF NOT EXISTS Complementary_item (
    com_item_id INTEGER NOT NULL,
    item_type VARCHAR(20) NOT NULL,
    item_id INTEGER  NOT NULL,
    PRIMARY KEY (com_item_id, item_id),
    FOREIGN KEY (item_id) REFERENCES Menu_item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- complementary items that added into order by customer
CREATE TABLE IF NOT EXISTS Complementary_item_in_order (
    com_item_number INTEGER NOT NULL,
    com_item_id INTEGER  NOT NULL,
    item_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    PRIMARY KEY (order_id, item_id, com_item_id),
    FOREIGN KEY (com_item_id, item_id) REFERENCES Complementary_item(com_item_id,item_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (order_id) REFERENCES Res_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- reservations made by customer.
CREATE TABLE IF NOT EXISTS Reservation (
    reservation_id INTEGER PRIMARY KEY,
    number_of_guests INTEGER NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (
        status IN ('cancelled', 'confirmed')
    ),
    res_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration INTERVAL NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES Customer (customer_id),
    table_id INTEGER REFERENCES Resturant_Table (table_id),
    CONSTRAINT valid_time CHECK(
        duration > INTERVAL '0 minutes'
        AND duration <= INTERVAL '90 minutes'
    )
);

--stores the additional information for dine-in orders. derived from Res_order
CREATE TABLE IF NOT EXISTS Dine_in_Order (
    order_id INTEGER NOT NULL,
    table_id INTEGER NOT NULL,
    reservation_id INTEGER NOT NULL,
    PRIMARY KEY (order_id),
    FOREIGN KEY (order_id) REFERENCES Res_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (table_id) REFERENCES Resturant_Table (table_id),
    FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Triggers to check availability of tables. Avoid time conflicts in reservations
CREATE
OR REPLACE FUNCTION check_reservation_time_conflict() RETURNS TRIGGER AS $$ BEGIN IF EXISTS (
    SELECT
        1
    FROM
        Reservation r
    WHERE
        r.table_id = NEW.table_id
        AND r.res_date = NEW.res_date
        AND r.reservation_id <> NEW.reservation_id
        AND (
            (
                NEW.start_time >= r.start_time
                AND NEW.start_time < r.start_time + r.duration
            )
            OR (
                NEW.start_time + NEW.duration > r.start_time
                AND NEW.start_time + NEW.duration <= r.start_time + r.duration
            )
            OR (
                NEW.start_time <= r.start_time
                AND NEW.start_time + NEW.duration >= r.start_time + r.duration
            )
        )
) THEN RAISE EXCEPTION 'Reservation time conflict detected.';

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER reservation_time_conflict_trigger BEFORE
INSERT
    OR
UPDATE
    ON Reservation FOR EACH ROW EXECUTE FUNCTION check_reservation_time_conflict();
-- store the basic informationn for each payment
CREATE TABLE IF NOT EXISTS Payment_Method (
    payment_id INTEGER PRIMARY KEY,
    amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    order_id INTEGER,
    FOREIGN KEY (order_id) REFERENCES Res_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- store the extra information for payment in cash.
CREATE TABLE IF NOT EXISTS Cash (
    payment_id INTEGER PRIMARY KEY,
    FOREIGN KEY (payment_id) REFERENCES Payment_Method(payment_id)
);
-- store the extra information for payment by credit card.
CREATE TABLE IF NOT EXISTS Credit_card (
    payment_id INTEGER PRIMARY KEY,
    CVV VARCHAR(3) NOT NULL,
    card_number varchar(30) NOT NULL,
    cardholder_name varchar(60) NOT NULL,
    expir_date DATE NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES Payment_Method(payment_id)

);
-- store the information of suburbs
CREATE TABLE IF NOT EXISTS Suburb (
    suburb_name VARCHAR(30) NOT NULL,
    suburb_id VARCHAR(4) NOT NULL,
    CONSTRAINT suburb_pkey PRIMARY KEY (suburb_id),
    CONSTRAINT suburb_suburb_id_suburb_id1_key UNIQUE (suburb_id)
);
-- store the information of delivery staffs
CREATE TABLE IF NOT EXISTS Delivery_staff (
    staff_name VARCHAR(30) NOT NULL,
    age integer,
    salary decimal(18, 2),
    staff_id integer NOT NULL,
    CONSTRAINT delivery_staff_pkey PRIMARY KEY (staff_id),
    CONSTRAINT unique_staff UNIQUE (staff_id),
    CONSTRAINT restriction_on_deliveryman CHECK(
        age > 21
        and salary > 0
    )
);
-- relationship between suburbs and delivery staff
CREATE TABLE IF NOT EXISTS Suburb_Allocate_For_Delivery_staff(
    suburb_id VARCHAR(4) NOT NULL,
    staff_id integer NOT NULL,
    PRIMARY KEY (suburb_id, staff_id),
    FOREIGN KEY (staff_id) REFERENCES Delivery_staff (staff_id),
    FOREIGN KEY (suburb_id) REFERENCES Suburb (suburb_id)
);
--stores the additional information for delivery orders. derived from Res_order
CREATE TABLE IF NOT EXISTS Delivery_order (
    special_instruction VARCHAR(30),
    delivery_date date NOT NULL,
    delivery_time time without time zone,
    delivery_cost decimal(18, 2),
    order_id integer NOT NULL,
    staff_id integer NOT NULL,
    CONSTRAINT delivery_order_pkey PRIMARY KEY (order_id),
    FOREIGN KEY (staff_id) REFERENCES delivery_staff (staff_id),
    FOREIGN KEY (order_id) REFERENCES Res_Order (order_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- weak entity set that stores the nominated address for delivery order
CREATE TABLE IF NOT EXISTS Nominated_address(
    address VARCHAR(30),
    order_id integer NOT NULL,
    suburb_id VARCHAR(4) NOT NULL,
    address_id integer NOT NULL,
    PRIMARY KEY (address_id, order_id, suburb_id),
    FOREIGN KEY (suburb_id) REFERENCES Suburb(suburb_id),
    FOREIGN KEY (order_id) REFERENCES delivery_order (order_id) ON DELETE CASCADE ON UPDATE CASCADE
);
--stores the additional information for delivery orders. derived from take_out_order
CREATE TABLE IF NOT EXISTS Take_out_order (
    order_id integer NOT NULL,
    CONSTRAINT take_out_order_pkey PRIMARY KEY (order_id),
    FOREIGN KEY (order_id) REFERENCES Res_Order (order_id) ON DELETE CASCADE ON UPDATE CASCADE
);


INSERT INTO
    Customer (
        customer_id,
        first_name,
        last_name,
        email,
        phone_number
    )
VALUES
    (
        1,
        'John',
        'Doe',
        'john.doe@example.com',
        '123-456-7890'
    ),
    (
        2,
        'Jane',
        'Smith',
        'jane.smith@example.com',
        '987-654-3210'
    );

INSERT INTO
    Res_Order (
        customization,
        total_charge,
        customer_id,
        order_id
    )
VALUES
    ('No onions', 25.97, 1, 1),
    ('Extra cheese', 18.97, 2, 2),
    ('No tomato', 16.97, 1, 3),
    ('More cheese', 19.97, 2, 4),
    ('Less salt please', 12.97, 2, 5),
    ('Extra sause', 23.97, 2, 6),
    ('Split bill', 42.94, 2, 7);

INSERT INTO
    Resturant_Table (table_id, capacity, located)
VALUES
    (1, 4, 'inside'),
    (2, 6, 'outside');

INSERT INTO
    Reservation (
        reservation_id,
        number_of_guests,
        status,
        res_date,
        start_time,
        duration,
        customer_id,
        table_id
    )
VALUES
    (
        1,
        2,
        'confirmed',
        '2023-05-01',
        '18:00:00',
        '01:00:00',
        1,
        1
    ),
    (
        2,
        4,
        'confirmed',
        '2023-05-02',
        '19:30:00',
        '01:30:00',
        2,
        2
    );

INSERT INTO
    Dine_in_Order (order_id, table_id, reservation_id)
VALUES
    (1, 1, 1),
    (2, 2, 2);

INSERT INTO
    Menu_item (item_id, item_name, description, price)
VALUES
    (1, 'French toast', 'With savory cheese', 9.99),
    (2, 'Eggs benedict', 'Poached eggs classic', 7.99),
    (3, 'Poke bowl', 'With fresh lettuce', 12.99),
    (11, 'Espresso', 'Bold coffee shot', 2.99),
    (12, 'Cappuccino', 'Espresso with milk', 3.99),
    (13, 'Latte', 'Espresso and steamed-milk', 3.99),
    (17, 'Long black', 'Espresso over water', 3.99),
    (19, 'Cold Brew', 'Slow-steeped iced coffee', 4.99),
    (21, 'Caramel Frappe', 'Sweet blended beverage', 4.99),
    (22, 'Mocha Frappe', 'Chocolate coffee frappe', 4.99),
    (31, 'Orange Juice', 'Fresh citrus juice', 3.99),
    (32, 'Apple Juice', 'Crisp fruit juice', 3.99);

INSERT INTO
    Complementary_item (com_item_id, item_type, item_id)
VALUES
    (1, 'Ketchup', 1),
    (2, 'Ranch', 2),
    (3, 'Mustard', 1),
    (4, 'Hot Sauce', 3),
    (5, 'Soy Sauce', 3);

INSERT INTO
    Category (category_name, category_id, item_id)
VALUES
    ('Breakfast', 1, 1),
    ('Lunch', 2, 1),
    ('Breakfast', 1, 2),
    ('Lunch', 2, 3),
    ('Breakfast', 1, 11),
    ('Lunch', 2, 11),
    ('Breakfast', 1, 12),
    ('Lunch', 2, 12),
    ('Breakfast', 1, 13),
    ('Lunch', 2, 13),
    ('Breakfast', 1, 17),
    ('Lunch', 2, 17),
    ('Breakfast', 1, 19),
    ('Lunch', 2, 19),
    ('Breakfast', 1, 21),
    ('Lunch', 2, 21),
    ('Breakfast', 1, 22),
    ('Lunch', 2, 22),
    ('Breakfast', 1, 31),
    ('Lunch', 2, 31),
    ('Breakfast', 1, 32),
    ('Lunch', 2, 32);

INSERT INTO
    Menu (menu_id, season)
VALUES
    (1, 'spring'),
    (2, 'summer');

INSERT INTO
    Coffee (item_id, coffee_type)
VALUES
    (11, 'Espresso'),
    (12, 'Cappuccino'),
    (13, 'Latte'),
    (17, 'Long black'),
    (19, 'Cold Brew');

INSERT INTO
    Food (item_id, food_type)
VALUES
    (1, 'Toast'),
    (2, 'Egg');

INSERT INTO
    Frappe (item_id, frappe_type)
VALUES
    (21, 'Caramel Frappe'),
    (22, 'Mocha Frappe');

INSERT INTO
    Fresh_juice (item_id, juice_type)
VALUES
    (31, 'Orange Juice'),
    (32, 'Apple Juice');

INSERT INTO
    Menu_item_is_Included_in_Menu (menu_id, item_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 1),
    (2, 2),
    (1, 11),
    (1, 12),
    (1, 13),
    (1, 17),
    (1, 19),
    (1, 21),
    (2, 22),
    (2, 31),
    (2, 32);

INSERT INTO
    Menu_item_in_Res_Order (menu_item_number, order_id, item_id)
VALUES
    (1, 1, 1),
    (2, 1, 2),
    (1, 2, 3),
    (2, 2, 11),
    (1, 3, 12),
    (2, 3, 17),
    (1, 4, 19),
    (2, 4, 21),
    (1, 5, 22),
    (2, 5, 31),
    (1, 6, 32),
    (2, 6, 1),
    (1, 7, 2),
    (2, 7, 3),
    (3, 7, 11);

INSERT INTO
    Coffee_milk (milk_name, milk_id)
VALUES
    ('Whole Milk', 1),
    ('Skim Milk', 2),
    ('Soy Milk', 3);

INSERT INTO
    Ordered_coffee (
        ordered_coffee_id,
        item_id,
        coffee_number,
        milk_id,
        order_id
    )
VALUES
    (1, 11, 1, 1, 1),
    (2, 12, 1, 2, 2);

INSERT INTO
    Complementary_item_in_order (com_item_number, com_item_id, item_id, order_id)
VALUES
    (1, 1, 1, 1),
    (1, 1, 1, 6),
    (1, 2, 2, 7),
    (2, 2, 2, 1),
    (1, 3, 1, 6),
    (2, 3, 1, 1),
    (1, 4, 3, 7),
    (2, 4, 3, 2),
    (1, 5, 3, 7);

INSERT INTO Payment_Method (payment_id, amount, order_id)
VALUES
    (1, 25.97, 1),
    (2, 18.97, 2),
    (3, 16.97, 3),
    (4, 19.97, 4),
    (5, 12.97, 5),
    (6, 23.97, 6),
    (7, 2.94, 7),
    (8, 40.00, 7);

INSERT INTO Cash (payment_id)
VALUES
    (1),
    (2),
    (5),
    (6),
    (7);

INSERT INTO Credit_card (payment_id, CVV, card_number, cardholder_name, expir_date)
VALUES
    (3, '123', '1234567890123456', 'John Doe', '2024-12-31'),
    (4, '456', '2345678901234567', 'Jane Smith', '2025-06-30'),
    (8, '789', '3344556677889900', 'Jane Smith', '2026-10-20');
INSERT INTO
    Suburb (suburb_name, suburb_id)
VALUES
    ('Downtown', '0001'),
    ('Riverside', '0002');

INSERT INTO
    Delivery_staff (staff_name, age, salary, staff_id)
VALUES
    ('James Smith', 25, 2500.00, 1),
    ('Emily Johnson', 28, 2800.00, 2);

INSERT INTO
    Suburb_Allocate_For_Delivery_staff (suburb_id, staff_id)
VALUES
    ('0001', 1),
    ('0002', 2),
    ('0001', 2);

INSERT INTO
    Delivery_order (
        special_instruction,
        delivery_date,
        delivery_time,
        delivery_cost,
        order_id,
        staff_id
    )
VALUES
    (
        'Leave at the door',
        '2023-05-01',
        '18:30:00',
        5.00,
        3,
        1
    ),
    (
        'Call when arrived',
        '2023-05-02',
        '19:45:00',
        5.00,
        4,
        2
    );

INSERT INTO
    Nominated_address (address, order_id, suburb_id, address_id)
VALUES
    ('123 Main St', 3, '0001', 1),
    ('456 Elm St', 4, '0002', 2);

INSERT INTO
    Take_out_order (order_id)
VALUES
    (5),
    (6);
