401 Írjunk blokkot, amelynek a deklarációs részében deklarálunk egy függvényt. A függvény paraméterként kapott ügyfélnévhez megkeresi és visszaadja az ügyfél azonosítóját.  
A blokkból hívjuk meg a függvényt olyan ügyfélnevekkel, amelyekre: - nincs ügyfél, - több ügyfél van. Futtassuk a blokkot. 
Ha kivételt kapunk, akkor kapjuk el, és írjuk ki a hiba kódját és üzenetét (minden kivétel esetén).
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

402. Írjunk tárolt eljárást, amely paraméterként kapott ügyfél nevéhez visszaadja az ügyfél születési dátumát és a nemét. (Itt nem kell kivételt kezelni.)
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

403. Írjunk blokkot, amely meghívja az elõzõ tárolt eljárást. Hívjuk meg úgy is, hogy kivételt dob, és vizsgáljuk meg, hogy mi történik. Bõvítsük a blokkunkat úgy, 
hogy a select into által okozott kivételeket elkapja, majd írja ki, hogy mi volt a hiba.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(403,'    
    BEGIN
        BEGIN
            --Meghívás jó adatokra
            findBirthAndSex(''Constantin'', ''Welles'');
        END;
        BEGIN
             --Amikor kivételt dob. (TOO MANY ROWS)
            findBirthAndSex(''Hello'', ''Kitti'');
        
            EXCEPTION
            WHEN TOO_MANY_ROWS
                THEN dopl(''Túl sok sor'');
        END;
        BEGIN
            --Amikor kivételt dob. (No Data Found)
            findBirthAndSex(''Constantin'', ''Wellessssssssssssss'');
    
            EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dopl(''Nincs adat'');
        END;
    END;/');
END;

404 Hozzunk létre táblát csaladtagok néven. A tábla oszlopaiban tároljuk a customers tábla azonosítóját (külsõ kulcsként hivatkozzunk rá), és a családtag nevét. 
A tábla elsõdleges kulcsa legyen a két oszlop együtt.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(404,'   
    CREATE TABLE CSALADTAGOK (
        CUSTOMER_ID NUMBER(6,0),
        F_NAME varchar2(50),
        
        FOREIGN KEY(CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID),
        CONSTRAINT PK_CSALADTAGOK PRIMARY KEY (CUSTOMER_ID, F_NAME)
    );/');
END;

405 Írjunk tárolt függvényt, amely az elõzõ feladat táblájába felvesz egy sort. A függvény a következõ paramétereket kapja: az ügyfél azonosítója és a családtag neve.
Ha a függvény rendben lefutott adja vissza a beszúrt sort. Ha kivételt kapunk amiatt, hogy egy ügyfélhez két azonos nevû családtagot veszünk fel, 
akkor a kapott kivételt kezeljük: írjuk ki a képernyõre, hogy melyik ügyfél (az ügyfél neve) milyen nevû családtagja már létezik. A függvény NULL értékekkel térjen vissza.
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

406. Írjunk tárolt eljárást, amely paraméterként kap egy ügyfélnevet és az ügyfél egy családtagjának a nevét. 
Az elõzõ tárolt függvény meghívásával szúrjuk be a megfelelõ sort az elsõ feladat táblájába. Az eljárás írja képernyõre a függvény által visszaadott értékeket. 
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

407. Írjunk blokkot, amely meghívja az elõzõ feladat tárolt eljárását úgy, hogy az ügyfél családtagjának a neve null érték. 
A null érték miatt bekövetkezõ kivételt kezeljük, írjuk ki a képernyõre, hogy nincs megadva  a családtag neve. 
Ugyanebben a blokkban hívjuk meg az eljárást úgy is, hogy olyan ügyfelet adunk meg, amely nem létezik a customer táblában. 
Az emiatt kapott kivételt kezeljük, írjuk ki a képernyõre, hogy nincs ilyen ügyfél.
Azt is próbáljuk ki, hogy olyan ügyfélnevet adjunk meg, amelybõl kettõ van az adatbázisban.
Az ennek megfelelõ kivételt hasonló módon kezeljük. A kivétek kezelése mindig csak arra az egy eljáráshiváshoz tartozzon.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(407,'  
    BEGIN
        DECLARE
            insert_null_into_notnull EXCEPTION;
            PRAGMA EXCEPTION_INIT(insert_null_into_notnull, -1400);
        BEGIN
            insertIntoTableByName(''Harrison'', ''Sutherland'', null);
            EXCEPTION when insert_null_into_notnull 
            then dopl(''Nincs megadva  a családtag neve'');
        END;
        BEGIN
            insertIntoTableByName(''HarrisonMMM'', ''Sutherland'', 103);
            EXCEPTION when NO_DATA_FOUND
            then dopl(''Nincs ilyen ügyfél'');
        END;
            BEGIN
            insertIntoTableByName(''Hello'', ''Kitti'', 104);
            EXCEPTION when TOO_MANY_ROWS
            then dopl(''Több ugyanolyan nevû ügyfél létezik'');
        END;
    END;/');
END;

408 Az elõzõ blokk kivételei miatt alakítsuk át a 6. feladat eljárását úgy, hogy a 7. feladatban szereplõ kivételeket kapja el, kezelje az 
ott megadottak szerint. A kivételkezelõ rész csak 7. feladat kivételeivel foglalkozzon.
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
            then dopl(''Nincs ilyen ügyfél'');
        when TOO_MANY_ROWS
            then dopl(''Több ugyan olyan nevû ügyfél létezik'');
    END;/');
END;

409 Írjunk tárolt eljárást, amely paraméterként kapott customer névhez a képernyõre listázza az ügyfelek megrendeléseinek azonosítóját (order_id), 
idejét (order_date) és a megrendelések végösszegét (order_total). A feladat megoldásához használjon explicit kurzort. 
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
    
410 Hívjuk meg az elõzõ feladat eljárását.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(410,'  
    BEGIN
        ordersWithCursor(''Constantin'', ''Welles'');
    END;/');
END;