901 Készítsünk csomagot, amelyben egy privát kurzort deklarálunk, 
amely azoknak a dolgozóknak a nevét és az azonosítóját listázza, akiknek a fizetése 
kevesebb mint egy paraméterben kapott érték.
A csomag tartalmazzon egy eljárást, amely kinyitja a kurzort, 
ha az nincs nyitva, majd kiolvas a kurzorból 10 sort, 
amelyet egy publikus dinamikus tömbben tárol. 
Ha a kurzorban nincs több sor, akkor lezárja a kurzort, és újra megnyitja.
--bulk collect into-val (mert 10esével)
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(901,'
    CREATE OR REPLACE PACKAGE play_with_cursor AS        
        PROCEDURE fetch_cursor(
            p_salary number
        );
    END play_with_cursor;/
    
       CREATE OR REPLACE PACKAGE BODY play_with_cursor AS
        CURSOR kurzor(p_salary number) is
            (SELECT CUST_FIRST_NAME, CUST_LAST_NAME, CUSTOMER_ID
            FROM CUSTOMERS
            WHERE CREDIT_LIMIT < p_salary);
            
        TYPE dinamikus_tomb_tipusa IS VARRAY(10) OF kurzor%rowtype;
        dinamikus_tomb dinamikus_tomb_tipusa := dinamikus_tomb_tipusa();
    
        PROCEDURE fetch_cursor(p_salary number) IS
        BEGIN
            IF kurzor%isopen then
                open kurzor(p_salary);
            else
                fetch kurzor bulk collect into dinamikus_tomb limit 10;
                
                if kurzor%NOTFOUND then
                    close kurzor;
                    open kurzor(p_salary);
                end if;
            end if;
            
            FOR j IN dinamikus_tomb.FIRST .. dinamikus_tomb.LAST LOOP 
                dopl(j);
                dopl(dinamikus_tomb(j).CUST_FIRST_NAME || ''  '' || dinamikus_tomb(j).CUST_LAST_NAME);
            END LOOP;
        END;
    END play_with_cursor;/');
END;
    
902. Írjunk blokkot, amelyben meghívjuk az elõzõ feladat csomagjának az eljárását, 
majd képernyõre írja a kollekció elemeit. Majd még kétszer hívjuk meg a blokkot.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(902,'
    BEGIN
        play_with_cursor.fetch_cursor(101);
        play_with_cursor.fetch_cursor(101);
        play_with_cursor.fetch_cursor(101);
    END;/');
END;

SELECT CUST_FIRST_NAME, CUST_LAST_NAME, CUSTOMER_ID, CREDIT_LIMIT
        FROM CUSTOMERS
        WHERE CREDIT_LIMIT < 1;
        
903. Írjunk blokkot, amelyben deklarálunk három beágyazott táblát, amelynek az elemei rendre job_title-k, min_salary-k és max_salary-k lesznek. 
Olvassuk fel a kollekciókba a jobs tábla minden sorát. Majd töröljük ki azokat a job_title-ket, amelyek esetén a min_salary több, mint a max_salary fele. 
Listázzuk a megmaradt job_title-ket a képernyõre. Majd minden olyan dolgozónak, akik ebben a kollekcióban maradt munkakörben dolgozik, 
emeljük meg a fizetését a max_salary 10%-ával. A feladatban használjuk az együttes hozzárendelést (BULK COLLECT, FORALL). 
Véglegesítsük a tranzakciót.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(903,'
    DECLARE
        TYPE beagyazott_job_title IS TABLE OF jobs.job_title%type;
        TYPE beagyazott_min_salary IS TABLE OF jobs.min_salary%type;
        TYPE beagyazott_max_salary IS TABLE OF jobs.max_salary%type;
        
        job_titles beagyazott_job_title;
        min_salaries beagyazott_min_salary ;
        max_salaries  beagyazott_max_salary ;
        
        counter number := 0;
    BEGIN
        select job_title, min_salary, max_salary bulk collect into job_titles, min_salaries, max_salaries FROM jobs;
        
        FOR i in job_titles.FIRST .. job_titles.LAST LOOP 
            if min_salaries(i) > max_salaries(i)/2 then
                job_titles.delete(i);
            end if;
        end loop;
        
        FORALL k IN INDICES OF job_titles
                UPDATE jobs SET max_salary = max_salary*1.1
                WHERE job_title = job_titles(k); 
        
        COMMIT;
    END;/');
END;

904 Hozzunk létre egy beágyazott tábla típust keresztnevekhez, az elemeinek a típusa varchar2(30) legyen.

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(904,'
    CREATE OR REPLACE TYPE egy_beagyaott_tabla_tipus IS TABLE OF varchar2(30);/');
END;

    
905 "Írunkj tárolt eljárást, amely paraméterként az elõzõ feladat beágyazott táblatípusát kapja, 
majd a képernyõre listázza abc sorrendben, hogy melyik karaktersorozatból (keresztnévbõ) hány darab van a beágyazott táblában. 
A feladat megoldásához asszociatív tömböt használjunk."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(905,'    
        CREATE OR REPLACE PROCEDURE list_caracter_of_surname(p_keresztnevek  egy_beagyaott_tabla_tipus) IS
        TYPE t_gyakorisag IS TABLE OF number INDEX BY varchar2(30);
        v_Elofordulasok t_gyakorisag;
        i VARCHAR2(30);
    BEGIN
        IF p_keresztnevek IS NULL
            THEN dopl(''NULL érték? kollekció'');
         ELSE
            FOR k IN p_keresztnevek.FIRST..p_keresztnevek.LAST
            LOOP
                IF v_Elofordulasok.EXISTS(k) then
                    v_Elofordulasok(p_keresztnevek(k)) := v_Elofordulasok(k)+1;
                end if;
            END LOOP;
        END IF;
        
        i := v_Elofordulasok.FIRST;
        WHILE i IS NOT NULL
        LOOP
            dopl(v_Elofordulasok(i));
            i := v_Elofordulasok.NEXT(i);
        END LOOP;
    END list_caracter_of_surname;
    /');
END;

906 "Töltsük fel együttes hozzárendeléssel egy változót, amelynek a típusa az 2-es feladat beágyazott táblája
a customers tábla keresztneveivel, majd hívjuk meg az elõzõ tárolt eljárást. "
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(906,'    
    DECLARE
        valtozo egy_beagyaott_tabla_tipus;
    BEGIN
        SELECT CUST_FIRST_NAME 
        BULK COLLECT INTO valtozo
        FROM CUSTOMERS;
        
        list_caracter_of_surname(valtozo);
    END;/');
END;

907. "Írjunk tárolt függvényt, amely paraméterként kap egy warehouse nevet, és visszaad egy beágyazott táblát, 
amely az adott warehouse-ban lévõ összes termék nevét (product_name a product_descriptionból) tartalmazza (mindegyiket csak egyszer). 
A feladatot együttes hozzárendeléssel oldjuk meg."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(907,'
    CREATE OR REPLACE TYPE products IS TABLE OF varchar(150);
    /
    CREATE OR REPLACE FUNCTION warehouseToTable(p_warehouse_name warehouses.warehouse_name%type) RETURN products AS
        v_prod products; 
    BEGIN
        select distinct product_name
        bulk collect into v_prod
        from oe.product_information d1
        JOIN oe.inventories d2
        on d1.product_id = d2.product_id
        JOIN oe.warehouses d3
        on d2.warehouse_id = d3.warehouse_id
        where d3.warehouse_name = p_warehouse_name;
        
        return v_prod;
    END;/');
END;

908 Hívjuk meg az elõzõ tárolt függvényt, és írjuk ki a képernyõre a kapott kollekció tartalmát.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(908,'
    declare
        v_prod products;
    begin
        v_prod := products();
        v_prod := warehouseToTable(''Sydney'');
        
        FOR k IN v_prod.FIRST..v_prod.LAST
        LOOP
            dopl(v_prod(k));
        END LOOP;
    end;/');
END;

909 Hozzunk létre csomagot, amely az oe schema customer táblájának telefonszám oszlopát kezeli. Tartalmazzon
- eljárást, amely felvesz egy paraméterként kapott telefonszámot egy customerhez, amelynek az azonosítóját az eljárás paraméterként kapja
- eljárást, amely töröl egy paraméterként kapott telefonszámot egy customer esetén, amelynek az azonosítóját az eljárás paraméterként kapja
- eljárást, amely egy customer paraméterként kapott telefonszámát egy másik, paraméterként kapott telefonszámra cserél. A customer id-ját az eljárás paraméterként kapja.
- eljárást, amely beszúr egy sort a customer táblába, (nem kell feltétlenül minden oszlopot kitölteni, de a telefonszámot töltse ki. Maximum egy telefonszámot kapjon az eljárás paraméterként)

CREATE OR REPLACE PACKAGE phone_manager AS
    procedure felvesz (p_phone_number varchar, p_cust_id customers.customer_id%type);
    procedure torol (p_phone_number varchar, p_cust_id customers.customer_id%type);
    procedure cserel (p_mit varchar, p_mire varchar,p_cust_id customers.customer_id%type );
    procedure beszur (p_phone_number varchar);
END phone_manager;

CREATE OR REPLACE PACKAGE BODY phone_manager AS

END phone_manager;

select * from customers;