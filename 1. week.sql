101. Listázzuk ki az ügyfelek (customers) nevét és születési dátumát születési dátum szerint csökkenõen, azon belül név szerint növekvõen.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(101,
    'SELECT (CUST_FIRST_NAME || '' '' || CUST_LAST_NAME) AS Nev, TO_CHAR(DATE_OF_BIRTH, ''YYYY-MM-DD'') AS Szuletesi_datum
    FROM OE.CUSTOMERS
    ORDER BY Szuletesi_datum DESC, CUST_FIRST_NAME, CUST_LAST_NAME;/
    ');
END;

102. Listázzuk ki, hogy az egyes ügyfelek (customers)  mikor rendeltek (orders) utoljára. A lista legyen dátum szerint növekvõen rendezve. 
Azokat az ügyfeleket is listázzuk, akik nem rendeltek.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(102,
   'SELECT (D1.CUST_FIRST_NAME || '' '' || D1.CUST_LAST_NAME) AS Nev, TO_CHAR(MAX(D2.ORDER_DATE), ''YYYY-MM-DD'') AS Rendeles_datuma
    FROM OE.CUSTOMERS D1
    FULL OUTER JOIN OE.ORDERS D2
    ON D1.CUSTOMER_ID = D2.CUSTOMER_ID
    GROUP BY D1.CUSTOMER_ID, D1.CUST_FIRST_NAME, D1.CUST_LAST_NAME
    ORDER BY Rendeles_datuma;/
    ');
END;

103. Listázzuk ki, hogy a Bombay nevû raktárban (warehouse)  az egyes termékekbõl (product_id és product_name)  hány darab található. 
Azzal a termékkel kezdjük a listát, amelyikbõl a legtöbb van.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(103,
    'SELECT D1.PRODUCT_ID, D1.PRODUCT_NAME, SUM(D2.QUANTITY_ON_HAND)
    FROM OE.PRODUCT_INFORMATION D1
    INNER JOIN OE.INVENTORIES D2
    ON D1.PRODUCT_ID = D2.PRODUCT_ID
    INNER JOIN OE.WAREHOUSES D3
    ON D2.WAREHOUSE_ID = D3.WAREHOUSE_ID
    WHERE WAREHOUSE_NAME = ''Bombay''
    GROUP BY D1.PRODUCT_ID, D1.PRODUCT_NAME
    ORDER BY SUM(D2.QUANTITY_ON_HAND) DESC;/
    ');
END;

104 Minden 20 évnél fiatalabb ügyfél 10% kedvezményt kap a rendelés árából. Az életkort viszonyítsuk a rendelés dátumához. 
Módosítsuk ennek megfelelõen a megrendelés (orders) táblát.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(104,
        'UPDATE ORDERS O
        SET ORDER_TOTAL = ORDER_TOTAL*0.9
            WHERE customer_id IN (SELECT CUSTOMER_ID
                FROM OE.CUSTOMERS D1
                WHERE trunc(months_between(O.ORDER_DATE, D1.DATE_OF_BIRTH)/12) between 0 and 20);/
  ');
END;

105. Listázzuk ki azokat a megrendeléseket (az azonosítójukat és a dátumukat illetve a megrendelõ nevét), amelyeken 5-nél több
sor szerepel (azaz az order_items táblában 5-nél több line_item_id tartozik a megrendeléshez).
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(105,
    'SELECT d2.order_id as order_id, to_char(d2.order_date, ''YYYY-MM-DD'') as order_date, 
        (d3.cust_first_name || '' '' || d3.cust_last_name) as names
        FROM OE.order_items d1
        INNER JOIN OE.orders d2
        ON d1.order_id = d2.order_id
        INNER JOIN OE.customers d3
        ON d3.customer_id = d2.customer_id
        GROUP BY d2.order_id, (d3.cust_first_name || '' '' || d3.cust_last_name), order_date
        HAVING count(d1.line_item_id)>5;/
      ');
END;

106. Melyek azok a termékek, amelyekbõl még egyáltalán nem rendeltek?

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(106, '
    SELECT D1.PRODUCT_ID, D1.PRODUCT_NAME
    FROM OE.PRODUCT_INFORMATION D1
    WHERE D1.PRODUCT_ID NOT IN (SELECT PRODUCT_ID
                            FROM OE.ORDER_ITEMS);/');
END;

107. Hozzunk létre nézetet, amely listázza, az ügyfelek bevételi szintjeiként (income level) és évente és havonta a megrendelések összegét.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(107, '
    CREATE OR REPLACE VIEW Bevetelek AS 
        SELECT  T1.INCOME_LEVEL as INCOME_LEVEL, 
                to_char(T2.ORDER_DATE, ''MM'') as ORDER_DATE_MONTH, 
                to_char(T2.ORDER_DATE, ''YYYY'') as  ORDER_DATE_YEAR, 
                SUM(T2.ORDER_TOTAL) as ORDER_TOTAL
        from OE.CUSTOMERS T1
        FULL OUTER JOIN OE.ORDERS T2
        ON T1.CUSTOMER_ID = T2.CUSTOMER_ID
        GROUP BY T1.INCOME_LEVEL, to_char(T2.ORDER_DATE, ''MM'') , to_char(T2.ORDER_DATE, ''YYYY'')
        ORDER BY T1.INCOME_LEVEL;/');
END;

CREATE OR REPLACE VIEW Bevetelek AS 
        SELECT  T1.INCOME_LEVEL as INCOME_LEVEL, 
                to_char(T2.ORDER_DATE, 'MM') as ORDER_DATE_MONTH, 
                to_char(T2.ORDER_DATE, 'YYYY') as  ORDER_DATE_YEAR, 
                SUM(T2.ORDER_TOTAL) as ORDER_TOTAL
        from OE.CUSTOMERS T1
        FULL OUTER JOIN OE.ORDERS T2
        ON T1.CUSTOMER_ID = T2.CUSTOMER_ID
        GROUP BY T1.INCOME_LEVEL, to_char(T2.ORDER_DATE, 'MM') , to_char(T2.ORDER_DATE, 'YYYY')
        ORDER BY T1.INCOME_LEVEL;

109. "Hozzunk létre táblát raktar_reszlegek néven. A tábla oszlopai legyenek:
azonosito (szám típusú)
raktar_azonosito (külsõ kulcs, mutat a warehouses táblára),
alapitas_datuma (dátum típusú),
reszleg_neve (karaktersorozat, max 50 hosszú).
A tábla elsõdleges kulcsa összetett, az azonosito és a raktar_azonosito együtt."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(109, '
    CREATE TABLE raktar_reszlegek (
        azonosito number(3),
        raktar_azonosito number(3),
        alapitas_datuma date,
        reszleg_neve varchar2(50),
        CONSTRAINT raktar_reszlegek_fk FOREIGN KEY (raktar_azonosito) REFERENCES warehouses(warehouse_id),
        constraint raktar_reszlegek_pk PRIMARY KEY (azonosito, raktar_azonosito)
    );/');
END;



