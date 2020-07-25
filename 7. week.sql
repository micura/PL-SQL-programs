701 ""Írjunk tárolt eljárást, amely paraméterként kapott raktár minden olyan terméke esetén, 
amely csak az adott raktárban található, megemeli a termék árát 10%-kal. 
A megoldásban for update utasításrésszel zároljuk a módosítandó termékeket, 
és a módosításhoz használjuk a current of utasításrészet.
A zárolás csak a termékek táblára vonatkozzon 
(azaz beágyazott selectet használjunk, és a külsõ select from részében csak a termékek tábla szerepeljen.)""
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(701,'
        CREATE OR REPLACE PROCEDURE increasePruductPrice(
        p_warehouse_name oe.warehouses.warehouse_name%type
    ) IS
        CURSOR c1 IS
            SELECT *
            FROM product_information
            WHERE product_id IN (SELECT D2.product_id
                                 FROM INVENTORIES D2
                                 JOIN WAREHOUSES D3
                                 ON D2.warehouse_id = D3.warehouse_id
                                 WHERE D3.WAREHOUSE_NAME=p_warehouse_name
                                            AND D2.product_id NOT IN (SELECT D2.product_id
                                                                     FROM INVENTORIES D2
                                                                     JOIN WAREHOUSES D3
                                                                     ON D2.warehouse_id = D3.warehouse_id
                                                                     WHERE D3.WAREHOUSE_NAME != p_warehouse_name))
            FOR UPDATE;
        v_c1 c1%rowtype;
    BEGIN
        OPEN c1;
        LOOP
            FETCH c1 INTO v_c1;
            EXIT WHEN c1%notfound;
            UPDATE PRODUCT_INFORMATION
            set list_price = list_price + list_price * 0.1
            WHERE CURRENT OF c1;
        END LOOP;
        CLOSE c1;
    END;/');
END;

702 Írjunk blokkot, amely meghívja az elõzõ feladat tárolt eljárását, és lezárja a tranzakciót.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(702,'
    BEGIN 
        increasePruductPrice(''Sydney'');
        commit;
    END;/');
END;

703. ""Hozzunk létre táblát konyvek néven, amelyben könyveknek az ISBN számát, címét, 
kiadóját és a kiadás évét tároljuk. 
A tábla elsõdleges kulcsa az ISBN legyen. ""
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(703,'
    CREATE TABLE konyvek (
        isbn_szam number(10),
        cim varchar(20),
        kiado varchar(15),
        kiadas_eve number(4),
        constraint konyvek_pk primary key (isbn_szam)
    );/');
END;

704 ""Hozzunk létre csomagot, amelynek a segítségével az elõzõ feladat tábláját használni tudjuk. 
A csomag tartalmazzon egy beszur_konyv nevû publikus eljárást, egy töröl könyv nevû publikus függvényt, 
egy listáz nevû publikus eljárást, és egy letezo_ISBN nevû kivételt és egy nincs_ilyen_konyv kivételt. 

A beszur_konyv nevû eljárás paraméterként kapjon ISBN, cím, kiadó, kiadás éve értékeket. 
Szúrja be a könyv táblába az értékeket. Ha ott a könyv megtalálható, és az értékek nem felelnek meg,  
akkor a letezo_ISBN kivételt dobjuk. 

A töröl könyv nevû függvény paraméterként egy ISBN számot kap, 
és kitöröli az adott könyvet, majd visszatérési értékként adja vissza, 
hogy mi volt a könyv címe. 
Ha az ISBN szám nem létezik, akkor ne történjen semmi. 

A listáz nevû eljáráshoz definiáljunk egy privát kurzort, 
amely paraméterként kapott kiadóhoz listázza az ISBN számokat és a könyvcímeket. 
Az eljárás megnyitja a kurzort, ha még nincs nyitva, 
egy sort felolvas, majd paraméterként visszaadja az eredményeket. 
(Ezt egy publikus rekordtípusban tegyük meg.) 
Ha a kurzorban nem találnuk több sort, akkor null értéket adjunk vissza. 
Ha nem talál ilyen ISBN számú könyvet, akkor nincs ilyen könyv kivételt dob.""
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(704,'
        CREATE OR REPLACE PACKAGE book_maganger AS
        TYPE c1_record IS RECORD (
            r_isbn_szam konyvek.isbn_szam%type,
            r_konyv_cim konyvek.cim%type
        );
        
        letezo_ISBN EXCEPTION;
        PRAGMA EXCEPTION_INIT(letezo_ISBN, -00001);
        nincs_ilyen_konyv EXCEPTION;
    
        PROCEDURE beszur_konyv(
            p_isbn_szam konyvek.isbn_szam%type,
            p_konyv_cim konyvek.cim%type,
            p_konyv_kiado konyvek.kiado%type,
            p_kiadas_erteke konyvek.kiadas_eve%type
        );
        
        FUNCTION torol_konyv(
            f_isbn_szam konyvek.isbn_szam%type
        ) RETURN konyvek.cim%type;
        
        PROCEDURE listaz(
            p_konyv_kiado konyvek.kiado%type
        );
    end book_maganger;
    /
    create or replace PACKAGE BODY book_maganger AS
        CURSOR c1(c_konyv_kiado konyvek.kiado%type) 
        RETURN c1_record IS 
            SELECT isbn_szam, cim
            FROM konyvek
            WHERE kiado = c_konyv_kiado;
        
        PROCEDURE beszur_konyv(
            p_isbn_szam konyvek.isbn_szam%type,
            p_konyv_cim konyvek.cim%type,
            p_konyv_kiado konyvek.kiado%type,
            p_kiadas_erteke konyvek.kiadas_eve%type
        ) IS
            v_isbn_szam konyvek.isbn_szam%type;
        BEGIN
            select isbn_szam into v_isbn_szam
            from konyvek where isbn_szam = p_isbn_szam;
            
            if (v_isbn_szam = p_isbn_szam) then
                RAISE letezo_ISBN;
            end if;
            
            EXCEPTION WHEN NO_DATA_FOUND THEN
                INSERT INTO konyvek
                values (p_isbn_szam, p_konyv_cim, p_konyv_kiado, p_kiadas_erteke);
            WHEN letezo_ISBN THEN
                dopl(''letezo ISBN'');
        END;
        
        FUNCTION torol_konyv(
            f_isbn_szam konyvek.isbn_szam%type
        ) RETURN konyvek.cim%type IS
            rf_cim konyvek.cim%type;
        BEGIN
            DELETE konyvek 
            WHERE isbn_szam = f_isbn_szam
            RETURNING cim into rf_cim;
            
            RETURN rf_cim;
        END;
        
        
        PROCEDURE listaz(
            p_konyv_kiado konyvek.kiado%type
        ) IS
            v_konyv_kiado c1%rowtype;
        BEGIN
            OPEN c1(p_konyv_kiado);
            LOOP
                FETCH c1 into v_konyv_kiado;
                EXIT WHEN c1%notfound;
                dopl(v_konyv_kiado.isbn_szam || '' '' || v_konyv_kiado.cim);
            END LOOP;
            close c1;
            
            EXCEPTION WHEN nincs_ilyen_konyv THEN
                dopl(''Nincs ilyen konyv'');
        END;
    END book_maganger;/');
END;

BEGIN
    --book_maganger.beszur_konyv(12345, 'Elso konyv', 'Masodik kiado', 2019);
    --book_maganger.beszur_konyv(22222, 'Oroszlankiraly', 'Dc', 2019);
    book_maganger.beszur_konyv(12321, 'Oroszlankiraly', 'Dc', 2019);
    dopl(book_maganger.torol_konyv(12345));
    book_maganger.listaz('Dc');
    
    exception when others then
        dopl(sqlerrm);
END;

    select * from konyvek;

705 ""Próbáljuk ki az elõzõ feladat csomagjának az eszözeit. 
Vegyünk fel a táblába sorokat, ugyanolyan ISBN számmal rendelkezõeket is, próbáljuk ki a lehetséges kivételeket. 
Töröljünk könyvet, nézzük meg a függvény visszatérési értékét, próbáljuk ki a lehetséges kivételt, kapjuk el. 
A listáz eljárást próbáljuk ki úgy, hogy adott kiadóhoz minden létezõ könyvet listázzunk ki. Próbáljuk ki itt is a kivételt, kapjuk el.""
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(705,'
    BEGIN
        book_maganger.beszur_konyv(12345, ''Elso konyv'', ''Elso kiado'', 2019);
        book_maganger.beszur_konyv(123456, ''Masodik konyv'', ''Elso kiado'', 2018);
        book_maganger.beszur_konyv(123456, ''Harmadik konyv'', ''Masodik kiado'', 2018); --Ugyan azzal az ISBN szammal torteno beszuras
        dopl(book_maganger.torol_konyv(123456));
        dopl(book_maganger.torol_konyv(99999999999));
        book_maganger.listaz(''Elso kiado'');
        book_maganger.listaz(''heasd kiado'');
        
        EXCEPTION WHEN others THEN
            dbms_output.put_line(sqlerrm);
    END;/');
END;

706. ""Írjunk tárolt eljárást, amely paraméterként egy gyenge kurzorváltozót kap, 
ha a kurzorváltozó nincs nyitva, akkor dob egy 'Nincs nyitva a kurzováltozóó' hibaüzenetet dob, 
ha nyitva van, akkor egy szám és egy szöveges rekordtípusú sort olvas ki a kurzorváltozóból, 
amely értékeket a tárolt eljárás kimenõ paraméterben visszaadja. 
Ha a kurzorváltozóban már nincs több sor, akkor dobjon 'nincs több sor' üzenettel hibát.""
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(706,'
    CREATE OR REPLACE PROCEDURE readCursor (
       p_refc SYS_REFCURSOR,
       p_szam OUT number,
       p_szoveg OUT varchar
    ) is
        TYPE t_record IS RECORD (
        id NUMBER,
        leiras VARCHAR2(100));
    BEGIN
        if p_refc%ISOPEN = false THEN
            dopl(''Nincs nyitva a kurzováltozóó'');
        else 
            FETCH p_refc INTO p_szam, p_szoveg;
        END IF;
        IF p_refc%NOTFOUND THEN
                dbms_output.put_line(''nincs több sor'');
        END IF;
    END;/');
END;


707 ""Írjunk blokkot, amely egy erõs kurzorváltozót deklarál, 
amelyhez egy szám és egy szöveges típusú mezõket tartalmazó rekordot rendelünk. 
A blokk nyissa meg a kurzort a hr séma department táblájánk id és name oszlopaihoz, 
majd hívja meg 3-szor az elõzõ feladat függvényét. 
A kurzorváltozó lezárása nélkül rendeljünk a kurzorváltozóhoz egy lekérdezést, 
amely a hr séma employee táblájának id és name oszlopait adja vissza, 
majd erre is hívjuk meg az elõzõ feladat függvényét. 
Ha a lekérdezésben nincs több sor, akkor a kapott kivételt kapjuk el. 
Érjük el, hogy a 2. lekérdezéshez tartozó hívások akkor is fussanak le, ha az elsõ rész hibát dobott.
""
BEGIN --Érjük el, hogy a 2. lekérdezéshez tartozó hívások akkor is fussanak le, ha az elsõ rész hibát dobott.
   HDBMS19.MEGOLDAS_FELTOLT(707,'
    DECLARE
        TYPE t_egyed IS RECORD (
                id NUMBER,
                leiras VARCHAR2(100));
        TYPE t_eros_dept IS REF CURSOR
            RETURN t_egyed;
        RETURN t_egyed;
        v_eros t_eros_dept;
        v_Egyedek1 t_egyed;
    BEGIN
        OPEN v_eros FOR SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM HR.DEPARTMENTS;
        FOR i IN 1..3
        LOOP
            FETCH v_eros INTO v_Egyedek1;
            gyenge_kurzor(v_eros, v_Egyedek1.id, v_Egyedek1.leiras);
            DBMS_OUTPUT.PUT_LINE(v_Egyedek1.id || '' '' || v_Egyedek1.leiras);
        END LOOP;
    
        OPEN v_eros FOR SELECT EMPLOYEE_ID, (FIRST_NAME || '' '' || LAST_NAME) FROM HR.EMPLOYEES;
        FETCH v_eros INTO v_Egyedek1;
        gyenge_kurzor(v_eros, v_Egyedek1.id, v_Egyedek1.leiras);
        DBMS_OUTPUT.PUT_LINE(v_Egyedek1.id || '' '' || v_Egyedek1.leiras);
            
        EXCEPTION WHEN invalid_cursor THEN
            DBMS_OUTPUT.PUT_LINE(''Nincs nyitva a kurzorvaltozo.'');
        WHEN others THEN
            DBMS_OUTPUT.PUT_LINE(''Nincs tobb sor'');
    END;/');
 END;
