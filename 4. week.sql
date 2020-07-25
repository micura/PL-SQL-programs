401 �rjunk blokkot, amelynek a deklar�ci�s r�sz�ben deklar�lunk egy f�ggv�nyt. A f�ggv�ny param�terk�nt kapott �gyf�ln�vhez megkeresi �s visszaadja az �gyf�l azonos�t�j�t.  
A blokkb�l h�vjuk meg a f�ggv�nyt olyan �gyf�lnevekkel, amelyekre: - nincs �gyf�l, - t�bb �gyf�l van. Futtassuk a blokkot. 
Ha kiv�telt kapunk, akkor kapjuk el, �s �rjuk ki a hiba k�dj�t �s �zenet�t (minden kiv�tel eset�n).
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(401,'
    DECLARE 
        cust_first_n varchar2(50);
        cust_last_n varchar2(50);
    function findCustAzon(
        cust_first_n varchar2,
        cust_last_n varchar2 
    ) return number is
        cust_azon number;
    BEGIN
        SELECT customer_id
        INTO cust_azon
        FROM OE.CUSTOMERS
        WHERE cust_first_name = cust_first_n and cust_last_name=cust_last_n;
        RETURN cust_azon;
    END;
    begin
        dopl(findCustAzon(''Constantin'', ''Welless''));
        
        EXCEPTION
        WHEN NO_DATA_FOUND
            THEN dopl(''No Data found for SELECT''); 
        WHEN TOO_MANY_ROWS THEN
            dopl(''Too many rows'');
        WHEN OTHERS 
            THEN dopl(''Unexpected error''); 
    end;/');
END;

402. �rjunk t�rolt elj�r�st, amely param�terk�nt kapott �gyf�l nev�hez visszaadja az �gyf�l sz�let�si d�tum�t �s a nem�t. (Itt nem kell kiv�telt kezelni.)
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(402,'
    CREATE OR REPLACE PROCEDURE findBirthAndSex(
        cust_first_n varchar2,
        cust_last_n varchar2
    ) IS
        cust_dateOfBirth date;
        cust_sex varchar2(1);
    BEGIN
        SELECT DATE_OF_BIRTH, GENDER
        INTO cust_dateOfBirth, cust_sex
        from customers
        WHERE cust_first_name = cust_first_n and cust_last_name = cust_last_n;
    END;/');
END;

403. �rjunk blokkot, amely megh�vja az el�z� t�rolt elj�r�st. H�vjuk meg �gy is, hogy kiv�telt dob, �s vizsg�ljuk meg, hogy mi t�rt�nik. B�v�ts�k a blokkunkat �gy, 
hogy a select into �ltal okozott kiv�teleket elkapja, majd �rja ki, hogy mi volt a hiba.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(403,'    
    BEGIN
        BEGIN
            --Megh�v�s j� adatokra
            findBirthAndSex(''Constantin'', ''Welles'');
        END;
        BEGIN
             --Amikor kiv�telt dob. (TOO MANY ROWS)
            findBirthAndSex(''Hello'', ''Kitti'');
        
            EXCEPTION
            WHEN TOO_MANY_ROWS
                THEN dopl(''T�l sok sor'');
        END;
        BEGIN
            --Amikor kiv�telt dob. (No Data Found)
            findBirthAndSex(''Constantin'', ''Wellessssssssssssss'');
    
            EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dopl(''Nincs adat'');
        END;
    END;/');
END;

404 Hozzunk l�tre t�bl�t csaladtagok n�ven. A t�bla oszlopaiban t�roljuk a customers t�bla azonos�t�j�t (k�ls� kulcsk�nt hivatkozzunk r�), �s a csal�dtag nev�t. 
A t�bla els�dleges kulcsa legyen a k�t oszlop egy�tt.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(404,'   
    CREATE TABLE CSALADTAGOK (
        CUSTOMER_ID NUMBER(6,0),
        F_NAME varchar2(50),
        
        FOREIGN KEY(CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID),
        CONSTRAINT PK_CSALADTAGOK PRIMARY KEY (CUSTOMER_ID, F_NAME)
    );/');
END;

405 �rjunk t�rolt f�ggv�nyt, amely az el�z� feladat t�bl�j�ba felvesz egy sort. A f�ggv�ny a k�vetkez� param�tereket kapja: az �gyf�l azonos�t�ja �s a csal�dtag neve.
Ha a f�ggv�ny rendben lefutott adja vissza a besz�rt sort. Ha kiv�telt kapunk amiatt, hogy egy �gyf�lhez k�t azonos nev� csal�dtagot vesz�nk fel, 
akkor a kapott kiv�telt kezelj�k: �rjuk ki a k�perny�re, hogy melyik �gyf�l (az �gyf�l neve) milyen nev� csal�dtagja m�r l�tezik. A f�ggv�ny NULL �rt�kekkel t�rjen vissza.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(405,'   
    create or replace FUNCTION insertIntoTable(cust_id IN csaladtagok.customer_id%type, family_member_name IN  csaladtagok.f_name%type)
    Return csaladtagok%ROWTYPE AS
        insertedRow csaladtagok%rowtype;
    BEGIN
        INSERT INTO csaladtagok (CUSTOMER_ID, F_NAME)
        VALUES (cust_id, family_member_name)
        RETURNING CUSTOMER_ID, F_NAME
        INTO insertedRow;
        Return insertedRow;
        
        exception WHEN DUP_VAL_ON_INDEX THEN
            DECLARE 
                cust_name varchar2(50);
            BEGIN
                      SELECT CUST_FIRST_NAME || '' '' || CUST_LAST_NAME
                      INTO cust_name 
                      FROM OE.customers
                      WHERE CUSTOMER_ID = cust_id;
                      dbms_output.put_line(''Ugyfel: '' || cust_name || '' nevu csaladtagja mar letezik'');
            END;
            RETURN null;
    END;/');
END;

406. �rjunk t�rolt elj�r�st, amely param�terk�nt kap egy �gyf�lnevet �s az �gyf�l egy csal�dtagj�nak a nev�t. 
Az el�z� t�rolt f�ggv�ny megh�v�s�val sz�rjuk be a megfelel� sort az els� feladat t�bl�j�ba. Az elj�r�s �rja k�perny�re a f�ggv�ny �ltal visszaadott �rt�keket. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(406,'       
    CREATE OR REPLACE PROCEDURE insertIntoTableByName(
        cust_fname IN CUSTOMERS.CUST_FIRST_NAME%type,
        cust_lname IN CUSTOMERS.CUST_LAST_NAME%type,
        family_member_name IN csaladtagok.f_name%type
    ) IS 
        CUST_ID CUSTOMERS.CUSTOMER_ID%type;
        a CSALADTAGOK%rowtype;
    BEGIN
        SELECT CUSTOMER_ID
        INTO CUST_ID
        FROM CUSTOMERS
        WHERE CUST_FIRST_NAME = cust_fname AND CUST_LAST_NAME = cust_lname;
        
        a := insertintotable(CUST_ID, family_member_name);
        dopl(a.CUSTOMER_ID || '' '' || a.F_NAME);
    END;/');
END;

407. �rjunk blokkot, amely megh�vja az el�z� feladat t�rolt elj�r�s�t �gy, hogy az �gyf�l csal�dtagj�nak a neve null �rt�k. 
A null �rt�k miatt bek�vetkez� kiv�telt kezelj�k, �rjuk ki a k�perny�re, hogy nincs megadva  a csal�dtag neve. 
Ugyanebben a blokkban h�vjuk meg az elj�r�st �gy is, hogy olyan �gyfelet adunk meg, amely nem l�tezik a customer t�bl�ban. 
Az emiatt kapott kiv�telt kezelj�k, �rjuk ki a k�perny�re, hogy nincs ilyen �gyf�l.
Azt is pr�b�ljuk ki, hogy olyan �gyf�lnevet adjunk meg, amelyb�l kett� van az adatb�zisban.
Az ennek megfelel� kiv�telt hasonl� m�don kezelj�k. A kiv�tek kezel�se mindig csak arra az egy elj�r�shiv�shoz tartozzon.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(407,'  
    BEGIN
        DECLARE
            insert_null_into_notnull EXCEPTION;
            PRAGMA EXCEPTION_INIT(insert_null_into_notnull, -1400);
        BEGIN
            insertIntoTableByName(''Harrison'', ''Sutherland'', null);
            EXCEPTION when insert_null_into_notnull 
            then dopl(''Nincs megadva  a csal�dtag neve'');
        END;
        BEGIN
            insertIntoTableByName(''HarrisonMMM'', ''Sutherland'', 103);
            EXCEPTION when NO_DATA_FOUND
            then dopl(''Nincs ilyen �gyf�l'');
        END;
            BEGIN
            insertIntoTableByName(''Hello'', ''Kitti'', 104);
            EXCEPTION when TOO_MANY_ROWS
            then dopl(''T�bb ugyanolyan nev� �gyf�l l�tezik'');
        END;
    END;/');
END;

408 Az el�z� blokk kiv�telei miatt alak�tsuk �t a 6. feladat elj�r�s�t �gy, hogy a 7. feladatban szerepl� kiv�teleket kapja el, kezelje az 
ott megadottak szerint. A kiv�telkezel� r�sz csak 7. feladat kiv�teleivel foglalkozzon.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(408,'  
   CREATE OR REPLACE PROCEDURE insertIntoTableByNameNew(
        cust_fname IN CUSTOMERS.CUST_FIRST_NAME%type,
        cust_lname IN CUSTOMERS.CUST_LAST_NAME%type,
        family_member_name IN csaladtagok.f_name%type
    ) IS 
        CUST_ID CUSTOMERS.CUSTOMER_ID%type;
        a CSALADTAGOK%rowtype;
    BEGIN
        SELECT CUSTOMER_ID
        INTO CUST_ID
        FROM CUSTOMERS
        WHERE CUST_FIRST_NAME = cust_fname AND CUST_LAST_NAME = cust_lname;
        
        a := insertintotable(CUST_ID, family_member_name);
        dopl(a.CUSTOMER_ID || '' '' || a.F_NAME);
    
        EXCEPTION when NO_DATA_FOUND
            then dopl(''Nincs ilyen �gyf�l'');
        when TOO_MANY_ROWS
            then dopl(''T�bb ugyan olyan nev� �gyf�l l�tezik'');
    END;/');
END;

409 �rjunk t�rolt elj�r�st, amely param�terk�nt kapott customer n�vhez a k�perny�re list�zza az �gyfelek megrendel�seinek azonos�t�j�t (order_id), 
idej�t (order_date) �s a megrendel�sek v�g�sszeg�t (order_total). A feladat megold�s�hoz haszn�ljon explicit kurzort. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(409,'      
    CREATE OR REPLACE PROCEDURE ordersWithCursor(
        c_fist_name in customers.CUST_FIRST_NAME%type, 
        c_last_name in customers.CUST_LAST_NAME%type
    ) IS
        CURSOR c1 IS
            SELECT d1.order_id, d1.order_date, d1.order_total
            FROM orders d1
            INNER JOIN customers d2
            ON d1.customer_id = d2.customer_id
            WHERE D2.CUST_FIRST_NAME = c_fist_name AND D2.CUST_LAST_NAME = c_last_name;
        v_orders c1%ROWTYPE;
    BEGIN
        open c1;
        loop
            fetch c1 into v_orders;
            exit when c1%notfound;
            dopl(v_orders.order_id || '' '' || v_orders.order_date || '' '' || v_orders.order_total);
        end loop;
        close c1;
    END;/');
END;
    
410 H�vjuk meg az el�z� feladat elj�r�s�t.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(410,'  
    BEGIN
        ordersWithCursor(''Constantin'', ''Welles'');
    END;/');
END;