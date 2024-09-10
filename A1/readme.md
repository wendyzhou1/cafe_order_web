# Explaination on ER diagram

## Entities

- Complementary_item is a weak entity that relies on Menu_item, as each menu item can come with a unique menu_item, such as ice comes with Apple juices. When one entity from Menu_item is deleted, its corresponding Menu item should also be deleted.

- Payment_method is a weak entity that relies on Resturant Order. When an Order is deleted, its corresponding Payment record should be deleted to avoid payments that have no corresponding order.

- Nominated_address is a weak entity that relies on Delivery_Order. It's created every time customer places a delivery order.

- Ordered_coffee is a weak entity that relies on Resturant Order. It stores the additional information for coffees that customer ordered. 

## Relationships
- Relationship Menu_item_is_included_in_Menu represents menu_items are included in which menu. It's a many to many relationship as a menu_item can be presented in different menus.

- Res_Order_in_Complementary_item represents which complementary item is added to restaurant order. It also stores the number of complementary item that is added to restaurant order. Eg. 2 sugar bags are added to order #1.

- Res_Order is superclass. Dine_in_Order, Delivery_order and Take_out_order are its subclass. This subclass IsA superclass relationship represents that Dine_in_Order, Delivery_order and Take_out_order are all a form of ordering. Menu_item must choose one subclass. Eg. order #1 is Dine_in_Order and order #5 is Dine_in_Order.

- Menu_item_in_Res_Order represents which menu_item is added to restaurant order. It also stores the number of menu item that is added to restaurant order. Eg. 1 French toast is added to order #2.

- Menu_item is superclass. Food, Coffee, Fresh_juice and Frappe are its subclass. This subclass IsA superclass relationship represents that food, coffee, fresh_juice and frappe are all a part of menu_item. Menu_item must choose one subclass. Eg. menu_item latte is coffee.

- Reservation can be only associated with exactly 1 customer, which books exactly 1 table and result in exactly 1 Dine_in_order. Each Dine_in_Order should be associated with exactly 1 Resturant_Table.

## Attributes
- Category attribute is a multi-valued attribute that includes category_id and category_name. Category_id helps simplify the contents of SQL insert statement and guarantees that each menu_item must have a 'Category' attribute and can have at least one 'Category'. Category_name is specific category name, such as 'lunch' and 'breakfast'.

- Name is a composite attribute that can be flattened into 'first name' and 'last name'.

- Total_charge is a derived attribute that is calculated from the sum of prices of the ordered menu_item.

- We will choose integer type attributes with 'id' in its name as the primary key of the table, which allows us to better ensure the reliability of the table and the readability of the inserted contents.
