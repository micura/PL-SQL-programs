201 Írj blokkot, amely kiírja a "képernyõre", hogy "Szép az élet".
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(201,'
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Szép az élet'');
    END;/');
END;

202. Írj blokkot, amely kiírja a "képernyõre" a rendszeridõt és a saját felhasználói nevünket. A feladathoz használjuk a sysdate és a user függvényeket.
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(202,' 
    BEGIN
        DBMS_OUTPUT.PUT_LINE(sysdate);
        DBMS_OUTPUT.PUT_LINE(user);
    END;/');
END;

203. Írjunk blokkot, amely kiírja az elsõ 10 négyzetszámot!
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(203,' 
    BEGIN
        FOR i IN 1..10 LOOP
            DBMS_OUTPUT.PUT_LINE(i);
        END LOOP;
    END;/');
END;

204. Írjunk blokkot, amely egy tetszõlegesen választott számot megvizsgál, és kiírja azt a tényt, hogy 6-tal osztható-e. Ha nem osztható 6-tal, 
akkor kiírja, hogy 2-vel osztható-e, illetve, hogy 3-mal osztható-e. A blokkot próbáljuk ki több számmal is 
helyettesítési változó segítségével (a helyettesítési változót nem lehet feltölteni, helyette konkrét szám legyen feltöltve). 
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(204,' 
    DECLARE
        szam NUMBER := 15;
    BEGIN
       IF MOD(szam, 6) != 0 THEN
           IF MOD(szam, 2) = 0 THEN
              dbms_output.put_line(''Osztható 2-vel''); 
           ELSIF (MOD(szam, 3) = 0) THEN
              dbms_output.put_line(''Osztható 3-al'');
           ELSE
              dbms_output.put_line(''Nem osztható 6-al, 3-al és 2-vel sem.'');
           END IF;
       ELSE
          dbms_output.put_line(''Osztható 6-al''); 
       END IF;
    END;/');
END;
    
DECLARE
    szam NUMBER := 15;
BEGIN
   IF MOD(szam, 6) != 0 THEN
       IF MOD(szam, 2) = 0 THEN
          dbms_output.put_line('Osztható 2-vel'); 
       ELSIF (MOD(szam, 3) = 0) THEN
          dbms_output.put_line('Osztható 3-al');
       ELSE
          dbms_output.put_line('Nem osztható 6-al, 3-al és 2-vel sem.');
       END IF;
   ELSE
      dbms_output.put_line('Osztható 6-al'); 
   END IF;
END;


205. Írjunk blokkot, amely két tetszõlegesen választott egész szám esetén megkeresi a két szám legnagyobb közös osztóját és legkisebb közös többszörösét. 
A blokkot próbáljuk ki több számra is, helyettesítési változó használatával (a helyettesítési változót nem lehet feltölteni, helyette konkrét szám legyen feltöltve).
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(205,'
    declare
        firstNumber NUMBER := 70;
        secondNumber NUMBER := 130;
        minMultiple NUMBER;
        firstInGcd NUMBER := firstNumber;
        secondInGcd NUMBER := secondNumber;
    begin
        WHILE firstInGcd != secondInGcd
        LOOP
            if(firstInGcd > secondInGcd) THEN
                firstInGcd := firstInGcd - secondInGcd;
            ELSE 
                secondInGcd := secondInGcd - firstInGcd;
            END IF;
        END LOOP;
        dbms_output.put_line(''Legnagyobb kozos osztó: '');
        dbms_output.put_line(firstInGcd);
        
        IF(firstNumber > secondNumber) THEN
            minMultiple := firstNumber;
        ELSE
            minMultiple := secondNumber;
        END IF;
        WHILE true
        LOOP
            IF(MOD(minMultiple,firstNumber) = 0) AND (MOD(minMultiple,secondNumber) = 0)  THEN
                dbms_output.put_line(''Legkisebb kozos tobbszoros: '');
                dbms_output.put_line(minMultiple);
                exit;
            END IF;
            minMultiple := minMultiple + 1;
        END LOOP;
    end;/');
END;


206. Írjunk blokkot, amely képernyõre írja a legidõsebb ügyfél nevét.

SELECT (CUST_FIRST_NAME || ' ' || CUST_LAST_NAME), MIN(to_char(date_of_birth, 'YYYY-MM-DD'))
from customers;


207. Leégett a Beijingben lévõ raktár egyrésze. Írjunk blokkot, amely 10 darabbal csökkent minden ott lévõ raktármennyiséget. 
Ha nincs 10 darab raktárelem a táblában, akkor töröljük a sort, egyébként módosítsuk a megfelelõ tábla tartalmát.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(207,'
    BEGIN
        DELETE INVENTORIES
            WHERE WAREHOUSE_ID IN (
                SELECT WAREHOUSE_ID 
                FROM WAREHOUSES
                WHERE WAREHOUSE_NAME = ''Beijing'' AND QUANTITY_ON_HAND < 10);
    UPDATE INVENTORIES
        SET QUANTITY_ON_HAND = QUANTITY_ON_HAND-10
            WHERE WAREHOUSE_ID IN (
                SELECT WAREHOUSE_ID 
                FROM WAREHOUSES
                WHERE WAREHOUSE_NAME = ''Beijing'' AND QUANTITY_ON_HAND >= 10);
    END;/');
END;

Írjunk blokkot, amely a képernyõre írja, hogy az egyes warehouse-okban összesen hány darab terméket tárolnak. Ha egy termékbõl többet is tárolnak, 
akkor azt többször számoljuk meg. A lista legyen a termékek száma szerint csökkenõen rendezett. 

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(2001,'
    BEGIN
        SELECT D1.WAREHOUSE_NAME, SUM(D2.QUANTITY_ON_HAND)
        FROM WAREHOUSES D1
        INNER JOIN INVENTORIES D2
        ON D1.WAREHOUSE_ID = D2.WAREHOUSE_ID
        GROUP BY D1.WAREHOUSE_NAME
        ORDER BY SUM(D2.QUANTITY_ON_HAND) DESC;
    END;/');
END;

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(2001,'
    BEGIN 
        FOR v IN 
            (SELECT D1.WAREHOUSE_NAME, SUM(D2.QUANTITY_ON_HAND) AS QUANTITY
            FROM WAREHOUSES D1
            INNER JOIN INVENTORIES D2
            ON D1.WAREHOUSE_ID = D2.WAREHOUSE_ID
            GROUP BY D1.WAREHOUSE_NAME
            ORDER BY SUM(D2.QUANTITY_ON_HAND) DESC)
        LOOP  
            DBMS_OUTPUT.PUT_LINE(v.WAREHOUSE_NAME || '' '' || v.QUANTITY);    
        END LOOP; 
    END;/');
END;

