101. List�zzuk ki az �gyfelek (customers) nev�t �s sz�let�si d�tum�t sz�let�si d�tum szerint cs�kken�en, azon bel�l n�v szerint n�vekv�en.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(101,
    'SELECT (CUST_FIRST_NAME || '' '' || CUST_LAST_NAME) AS Nev, TO_CHAR(DATE_OF_BIRTH, ''YYYY-MM-DD'') AS Szuletesi_datum
    FROM OE.CUSTOMERS
    ORDER BY Szuletesi_datum DESC, CUST_FIRST_NAME, CUST_LAST_NAME;/
    ');
END;

102. List�zzuk ki, hogy az egyes �gyfelek (customers)  mikor rendeltek (orders) utolj�ra. A lista legyen d�tum szerint n�vekv�en rendezve. 
Azokat az �gyfeleket is list�zzuk, akik nem rendeltek.
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

103. List�zzuk ki, hogy a Bombay nev� rakt�rban (warehouse)  az egyes term�kekb�l (product_id �s product_name)  h�ny darab tal�lhat�. 
Azzal a term�kkel kezdj�k a list�t, amelyikb�l a legt�bb van.
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

104 Minden 20 �vn�l fiatalabb �gyf�l 10% kedvezm�nyt kap a rendel�s �r�b�l. Az �letkort viszony�tsuk a rendel�s d�tum�hoz. 
M�dos�tsuk ennek megfelel�en a megrendel�s (orders) t�bl�t.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(104,
        'UPDATE ORDERS O
        SET ORDER_TOTAL = ORDER_TOTAL*0.9
            WHERE customer_id IN (SELECT CUSTOMER_ID
                FROM OE.CUSTOMERS D1
                WHERE trunc(months_between(O.ORDER_DATE, D1.DATE_OF_BIRTH)/12) between 0 and 20);/
  ');
END;

105. List�zzuk ki azokat a megrendel�seket (az azonos�t�jukat �s a d�tumukat illetve a megrendel� nev�t), amelyeken 5-n�l t�bb
sor szerepel (azaz az order_items t�bl�ban 5-n�l t�bb line_item_id tartozik a megrendel�shez).
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

106. Melyek azok a term�kek, amelyekb�l m�g egy�ltal�n nem rendeltek?

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(106, '
    SELECT D1.PRODUCT_ID, D1.PRODUCT_NAME
    FROM OE.PRODUCT_INFORMATION D1
    WHERE D1.PRODUCT_ID NOT IN (SELECT PRODUCT_ID
                            FROM OE.ORDER_ITEMS);/');
END;

107. Hozzunk l�tre n�zetet, amely list�zza, az �gyfelek bev�teli szintjeik�nt (income level) �s �vente �s havonta a megrendel�sek �sszeg�t.
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

109. "Hozzunk l�tre t�bl�t raktar_reszlegek n�ven. A t�bla oszlopai legyenek:
azonosito (sz�m t�pus�)
raktar_azonosito (k�ls� kulcs, mutat a warehouses t�bl�ra),
alapitas_datuma (d�tum t�pus�),
reszleg_neve (karaktersorozat, max 50 hossz�).
A t�bla els�dleges kulcsa �sszetett, az azonosito �s a raktar_azonosito egy�tt."
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



