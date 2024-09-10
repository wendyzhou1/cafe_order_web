#!/usr/bin/env python3
import psycopg2
import routes

#####################################################
##  Database Connection
#####################################################

"""
Connect to the database using the connection string
"""


def openConnection():
    # connection parameters - ENTER YOUR LOGIN AND PASSWORD HERE
    database = "y24s1c9120_unikey"
    userid = "y24s1c9120_unikey"
    passwd = ""
    myHost = "awsprddbs4836.shared.sydney.edu.au"
    # Create a connection to the database
    conn = None
    try:
        # Parses the config file and connects using the connect string
        conn = psycopg2.connect(
            database=database, user=userid, password=passwd, host=myHost
        )
    except psycopg2.Error as sqle:
        print("psycopg2.Error : " + str(sqle.pgerror))

    # return the connection to use
    return conn


def closeConnection(conn):
    if conn is None:
        print("connection not exist")
        return False
    else:
        conn.close()


"""
Validate staff based on username and password
"""


def checkStaffLogin(staffID, password):
    conn = openConnection()
    query = """SELECT * FROM Staff WHERE lower(staffID) = lower(%s) AND password = %s"""
    try:
        cur = conn.cursor()
        cur.execute(query, (staffID, password))
        acc = cur.fetchone()
        if acc != None:
            staff = acc
            return list(staff)
    except:
        print("Login wrong")
    return
    # return ["johndoe", "654", "John", "Doe", 22, 38000]


"""
List all the associated menu items in the database by staff
"""


def findMenuItemsByStaff(staffID):
    conn = openConnection()
    query = """SELECT M.menuitemid,COALESCE(M.name,''),COALESCE(M.description, ''),COALESCE(M.coffeetype,-1),COALESCE(M.price,-1),COALESCE(TO_CHAR(M.reviewdate, 'DD-MM-YYYY'), ''),COALESCE(CONCAT(S.FirstName, ' ', S.LastName),'') as reviewer,COALESCE(C1.categoryname,'') as categoryname1, COALESCE(C2.categoryname,'') as categoryname2, COALESCE(C3.categoryname,'') as categoryname3, 
CONCAT(
    COALESCE(C1.categoryname,''),
	CASE WHEN C1.categoryname IS NOT NULL AND (C2.categoryname IS NOT NULL OR C3.categoryname IS NOT NULL) THEN '|' ELSE '' END,
	COALESCE(C2.categoryname, ''),
	CASE WHEN C2.categoryname IS NOT NULL AND C3.categoryname IS NOT NULL THEN '|' ELSE '' END,
    COALESCE(C3.categoryname, '')
) AS categories,
	CONCAT(
		C.coffeetypename,
		CASE WHEN C.coffeetypename IS NOT NULL AND Milk.milkkindname IS NOT NULL THEN ' - ' ELSE '' END,
		Milk.milkkindname) as option
FROM Menuitem as M 
LEFT OUTER JOIN Category AS C1 ON C1.categoryid =  M.categoryone
LEFT OUTER JOIN Category AS C2 ON C2.categoryid =  M.categorytwo
LEFT OUTER JOIN Category AS C3 ON C3.categoryid =  M.categorythree
LEFT OUTER JOIN Staff AS S ON LOWER(M.reviewer) = S.staffid
LEFT OUTER JOIN Milkkind as Milk on Milk.milkkindid = M.milkkind
LEFT OUTER JOIN Coffeetype as C on C.coffeetypeid = M.coffeetype
WHERE S.staffid = %s
Order By M.reviewdate ASC,COALESCE(M.description, '') ASC , M.price DESC;

"""
    ret = []
    try:
        cur = conn.cursor()
        cur.execute(query, (staffID,))
        results = cur.fetchall()
        for result in results:
            menu_item = {
                "menuitem_id": result[0],
                "name": result[1],
                "description": result[2],
                "category": result[-2],  # concat category 1,2,3  with '|'
                "coffeeoption": result[-1],
                # concat coffeetype and milkkind  with ' - '
                "price": result[4],
                "reviewdate": result[5],
                "reviewer": result[6],
            }
            ret += [menu_item]
    except:
        print("something wrong")
    return ret


"""
Find a list of menu items based on the searchString provided as parameter
See assignment description for search specification
"""


def findMenuItemsByCriteria(searchString):
    conn = openConnection()
    query = """SELECT M.menuitemid,COALESCE(M.name,''),COALESCE(M.description, ''),COALESCE(M.coffeetype,-1),COALESCE(M.price,-1),COALESCE(TO_CHAR(M.reviewdate, 'DD-MM-YYYY'), ''),COALESCE(CONCAT(S.FirstName, ' ', S.LastName),'') as reviewer,COALESCE(C1.categoryname,'') as categoryname1, COALESCE(C2.categoryname,'') as categoryname2, COALESCE(C3.categoryname,'') as categoryname3, 
CONCAT(
    COALESCE(C1.categoryname,''),
	CASE WHEN C1.categoryname IS NOT NULL AND (C2.categoryname IS NOT NULL OR C3.categoryname IS NOT NULL) THEN '|' ELSE '' END,
	COALESCE(C2.categoryname, ''),
	CASE WHEN C2.categoryname IS NOT NULL AND C3.categoryname IS NOT NULL THEN '|' ELSE '' END,
    COALESCE(C3.categoryname, '')
) AS categories,
	CONCAT(
		C.coffeetypename,
		CASE WHEN C.coffeetypename IS NOT NULL AND Milk.milkkindname IS NOT NULL THEN ' - ' ELSE '' END,
		Milk.milkkindname) as option
FROM Menuitem as M 
LEFT OUTER JOIN Category AS C1 ON C1.categoryid =  M.categoryone
LEFT OUTER JOIN Category AS C2 ON C2.categoryid =  M.categorytwo
LEFT OUTER JOIN Category AS C3 ON C3.categoryid =  M.categorythree
LEFT OUTER JOIN Staff AS S ON LOWER(M.reviewer) = S.staffid
LEFT OUTER JOIN Milkkind as Milk on Milk.milkkindid = M.milkkind
LEFT OUTER JOIN Coffeetype as C on C.coffeetypeid = M.coffeetype
WHERE  (lower(M.name) LIKE lower('%%' || %s || '%%') OR lower(M.description) LIKE lower('%%' || %s || '%%') OR lower(C1.categoryname) LIKE lower('%%' || %s || '%%') OR  lower(C2.categoryname) LIKE lower('%%' || %s || '%%') OR lower(C3.categoryname) LIKE lower('%%' || %s || '%%') OR lower(C.coffeetypename) LIKE lower('%%' || %s || '%%') OR  lower(Milk.milkkindname) LIKE lower('%%' || %s || '%%') OR lower(CONCAT(S.FirstName, ' ', S.LastName)) LIKE lower('%%' || %s || '%%') OR lower(M.reviewer) = lower(%s)) AND( M.reviewdate >= CURRENT_DATE - INTERVAL '10 YEARS' OR M.reviewdate IS NULL)
Order By M.reviewdate Desc


"""
    # search the login user's associate item if the search string is empty
    if searchString == "":
        searchString = routes.user_details["staffID"]

    ret = []
    try:
        cur = conn.cursor()
        cur.execute(query, ((searchString,) * 9))
        results = cur.fetchall()
        for result in results:
            menu_item = {
                "menuitem_id": result[0],
                "name": result[1],
                "description": result[2],
                "category": result[-2],  # concat category 1,2,3  with '|'
                "coffeeoption": result[
                    -1
                ],  # concat coffeetype and milkkind  with ' - '
                "price": result[4],
                "reviewdate": result[5],
                "reviewer": result[6],
            }
            ret += [menu_item]
    except:
        print("something wrong")
    return ret


"""
Add a new menu item
"""


def addMenuItem(
    name,
    description,
    categoryone,
    categorytwo,
    categorythree,
    coffeetype,
    milkkind,
    price,
):
    # get connection
    conn = openConnection()
    curs = conn.cursor()

    try:
        # insert the data
        curs.callproc(
            "AddNewMenuItem",
            [
                name,
                description,
                categoryone,
                categorytwo,
                categorythree,
                coffeetype,
                milkkind,
                price,
            ],
        )

        # commit the insertion
        conn.commit()

    except Exception as e:
        print("Failed to insert new menu item: ", e)
        return False

    finally:
        # close connection
        curs.close()
        conn.close()

    return True


"""
Update an existing menu item
"""


def updateMenuItem(
    menuitem_id,
    name,
    description,
    categoryone,
    categorytwo,
    categorythree,
    coffeetype,
    milkkind,
    price,
    reviewdate,
    reviewer,
):
    # get connection
    conn = openConnection()
    curs = conn.cursor()

    try:
        # make sure the data sylte match
        curs.execute("SET datestyle = 'ISO, DMY';")
        # update the menu item
        curs.callproc(
            "UpdateMenuItem",
            [
                menuitem_id,
                name,
                description,
                categoryone,
                categorytwo,
                categorythree,
                coffeetype,
                milkkind,
                price,
                reviewdate,
                reviewer,
            ],
        )

        # commit the insertion
        conn.commit()
    except Exception as e:
        print("failed to update the menu item: ", e)
        return False

    finally:
        # close connection
        curs.close()
        conn.close()

    return True
