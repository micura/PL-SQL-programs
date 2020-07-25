201 �rj blokkot, amely ki�rja a "k�perny�re", hogy "Sz�p az �let".
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(201,'
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Sz�p az �let'');
    END;/');
END;

202. �rj blokkot, amely ki�rja a "k�perny�re" a rendszerid�t �s a saj�t felhaszn�l�i nev�nket. A feladathoz haszn�ljuk a sysdate �s a user f�ggv�nyeket.
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(202,' 
    BEGIN
        DBMS_OUTPUT.PUT_LINE(sysdate);
        DBMS_OUTPUT.PUT_LINE(user);
    END;/');
END;

203. �rjunk blokkot, amely ki�rja az els� 10 n�gyzetsz�mot!
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(203,' 
    BEGIN
        FOR i IN 1..10 LOOP
            DBMS_OUTPUT.PUT_LINE(i);
        END LOOP;
    END;/');
END;

204. �rjunk blokkot, amely egy tetsz�legesen v�lasztott sz�mot megvizsg�l, �s ki�rja azt a t�nyt, hogy 6-tal oszthat�-e. Ha nem oszthat� 6-tal, 
akkor ki�rja, hogy 2-vel oszthat�-e, illetve, hogy 3-mal oszthat�-e. A blokkot pr�b�ljuk ki t�bb sz�mmal is 
helyettes�t�si v�ltoz� seg�ts�g�vel (a helyettes�t�si v�ltoz�t nem lehet felt�lteni, helyette konkr�t sz�m legyen felt�ltve). 
BEGIN
    HDBMS19.MEGOLDAS_FELTOLT(204,' 
    DECLARE
        szam NUMBER := 15;
    BEGIN
       IF MOD(szam, 6) != 0 THEN
           IF MOD(szam, 2) = 0 THEN
              dbms_output.put_line(''Oszthat� 2-vel''); 
           ELSIF (MOD(szam, 3) = 0) THEN
              dbms_output.put_line(''Oszthat� 3-al'');
           ELSE
              dbms_output.put_line(''Nem oszthat� 6-al, 3-al �s 2-vel sem.'');
           END IF;
       ELSE
          dbms_output.put_line(''Oszthat� 6-al''); 
       END IF;
    END;/');
END;
    
DECLARE
    szam NUMBER := 15;
BEGIN
   IF MOD(szam, 6) != 0 THEN
       IF MOD(szam, 2) = 0 THEN
          dbms_output.put_line('Oszthat� 2-vel'); 
       ELSIF (MOD(szam, 3) = 0) THEN
          dbms_output.put_line('Oszthat� 3-al');
       ELSE
          dbms_output.put_line('Nem oszthat� 6-al, 3-al �s 2-vel sem.');
       END IF;
   ELSE
      dbms_output.put_line('Oszthat� 6-al'); 
   END IF;
END;


205. �rjunk blokkot, amely k�t tetsz�legesen v�lasztott eg�sz sz�m eset�n megkeresi a k�t sz�m legnagyobb k�z�s oszt�j�t �s legkisebb k�z�s t�bbsz�r�s�t. 
A blokkot pr�b�ljuk ki t�bb sz�mra is, helyettes�t�si v�ltoz� haszn�lat�val (a helyettes�t�si v�ltoz�t nem lehet felt�lteni, helyette konkr�t sz�m legyen felt�ltve).
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
        dbms_output.put_line(''Legnagyobb kozos oszt�: '');
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


206. �rjunk blokkot, amely k�perny�re �rja a legid�sebb �gyf�l nev�t.

SELECT (CUST_FIRST_NAME || ' ' || CUST_LAST_NAME), MIN(to_char(date_of_birth, 'YYYY-MM-DD'))
from customers;


207. Le�gett a Beijingben l�v� rakt�r egyr�sze. �rjunk blokkot, amely 10 darabbal cs�kkent minden ott l�v� rakt�rmennyis�get. 
Ha nincs 10 darab rakt�relem a t�bl�ban, akkor t�r�lj�k a sort, egy�bk�nt m�dos�tsuk a megfelel� t�bla tartalm�t.
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

�rjunk blokkot, amely a k�perny�re �rja, hogy az egyes warehouse-okban �sszesen h�ny darab term�ket t�rolnak. Ha egy term�kb�l t�bbet is t�rolnak, 
akkor azt t�bbsz�r sz�moljuk meg. A lista legyen a term�kek sz�ma szerint cs�kken�en rendezett. 

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

