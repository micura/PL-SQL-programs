501 -Írjunk csomagot, amelyben deklarálunk egy privát explicit kurzort, amely paraméterként 
egy customer azonosítóját kapja, és lekérdezi, hogy az adott vásárló mely warehouse-okban vásárolt eddig. 
A warehouse-ok nevét és id-ját csak egyszer listázza. 
- A csomag tartalmazzon egy publikus eljárást, amely a customer nevéhez visszaadja az azonosítóját. 
    Ha ilyen ügyfél nem létezik, akkor dobjon el egy 
    a csomagban publikusként deklarált exc_no_cust nevû kivételt.  
    Ha több ilyen ügyfél létezik, akkor dobjon el egy 
    a csomagban publikusként deklarált exc_too_many_cust nevû kivételt.
- A csomag tartalmazzon egy publikus eljárást, paraméterként  kapott vásárló id-val megnyitja a kurzort. 
- A csomag tartalmazzon egy publikus eljárást, amely lezárja a kurzort.
- A csomag tartalmazzon egy publikus függvényt, amely felolvas 10 sort a kurzorból. 
    Ha már nincs 10 sor, akkor csak annyi sort olvasson fel, amennyit talált. 
    Visszatérési értéke a felolvasott sorok száma legyen. 

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(501,'
    CREATE OR REPLACE PACKAGE warehouse_Package AS
        
        exc_no_cust EXCEPTION; 
        exc_too_many_cust EXCEPTION;
        
        PROCEDURE nev_to_azon(
            v_first_name customers.CUST_FIRST_NAME%TYPE, 
            v_last_name customers.CUST_LAST_NAME%TYPE,
            cust_id OUT customers.customer_id%type
        ); 
    
        PROCEDURE cursor_nyit(
            v_cust_id customers.CUSTOMER_ID%TYPE
        );
    
        PROCEDURE cursor_zar;
        FUNCTION felolvas RETURN number;
    end warehouse_Package;
    /
    
    create or replace PACKAGE BODY warehouse_Package AS
        CURSOR c1(v_cust_id customers.customer_id%TYPE) RETURN  OE.warehouses%rowtype IS
            SELECT d1.* FROM oe.warehouses d1
            JOIN oe.inventories d2
            on  d1.warehouse_id = d2.warehouse_id
            JOIN oe.product_information d3
            on  d2.product_id = d3.product_id
            JOIN oe.order_items d4
            on  d3.product_id = d4.product_id
            JOIN oe.orders d5
            on  d4.order_id = d5.order_id
            JOIN oe.customers d6
            on  d5.customer_id = d6.customer_id
            WHERE d5.customer_id = v_cust_id;
            
        PROCEDURE nev_to_azon(
            v_first_name customers.CUST_FIRST_NAME%TYPE, 
            v_last_name customers.CUST_LAST_NAME%TYPE,
            cust_id OUT customers.customer_id%type
        ) IS
        BEGIN
            SELECT customer_id
            INTO cust_id
            FROM customers
            WHERE CUST_FIRST_NAME = v_first_name and CUST_LAST_NAME = CUST_LAST_NAME;
            
            EXCEPTION WHEN TOO_MANY_ROWS
                THEN RAISE exc_too_many_cust;
            WHEN NO_DATA_FOUND
                THEN RAISE exc_no_cust;
        END;
        
        PROCEDURE cursor_nyit(
            v_cust_id customers.CUSTOMER_ID%TYPE
        ) IS
        BEGIN
            open c1(v_cust_id);
        END;
        
        PROCEDURE cursor_zar 
        IS
        BEGIN
            close c1;
        END;
        
        FUNCTION felolvas RETURN number
        IS
            warehouse_row oe.warehouses%rowtype;
            counter number := 1;
        BEGIN
            while counter < 11
            LOOP
                IF c1%NOTFOUND THEN
                    EXIT;
                ELSE
                    fetch c1 into warehouse_row;
                    dopl(warehouse_row.warehouse_name);
                end if;
                counter := counter + 1;
            end loop;
            return counter;
        END;
    end warehouse_Package;/');
END;
        
502.Írjunk blokkot, amely az elõzõ feladat csomagjának megfelelõ eszközeit használja:
- adott customernévhez kikeresi a customer id-ját, 
- amelyre megnyitja a kurzort, 
- felolvassa a kurzor összes sorát
- lezárja a kurzort.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(502,'
    DECLARE
        v_cust_id customers.customer_id%type;
    BEGIN
        warehouse_Package.nev_to_azon(''Constantin'', ''Welles'', v_cust_id);
        warehouse_Package.cursor_nyit(v_cust_id);
        dopl(warehouse_Package.felolvas());
        warehouse_Package.cursor_zar();
    END;/');
END;

503 "Írjunk tárolt eljárást, amely paraméterként kapott product_id és 
quantity esetén törli azokat a sorokat az order_items táblából, 
amelyek ezt a terméket ilyen mennyiségben tartalmazzák.
Adjuk vissza, hogy a táblából hány sort törölt.
Ha az adott order_id-n nincs több line_item_id, akkor töröljük az orders tábla megfelelõ sorát is. 
Az eljárás azt is adja vissza, hogy törölt-e sort az orders táblából. "

BEGIN
HDBMS19.MEGOLDAS_FELTOLT(503,'
CREATE OR REPLACE PROCEDURE deleteWhere(prid IN number, qtty IN number, toroltsor OUT number, toroltorder OUT number) IS
BEGIN
	DECLARE
		temp NUMBER;
	BEGIN
		toroltsor := 0;
		toroltorder := 0;
		DELETE from ORDIT WHERE QUANTITY = qtty AND PRODUCT_ID = prid;
		toroltsor := SQL%ROWCOUNT;
		DELETE FROM orders WHERE ORDER_ID in (SELECT orders.ORDER_ID FROM orders LEFT JOIN order_items on orders.ORDER_ID=order_items.ORDER_ID WHERE order_items.ORDER_ID is null);
		toroltorder := SQL%ROWCOUNT;
		END;
	END;/');
END;


HDBMS19.MEGOLDAS_FELTOLT(503,'
CREATE OR REPLACE PROCEDURE otszazharom(prid IN number, qtty IN number, toroltsor OUT number, toroltorder OUT number) IS
BEGIN
	DECLARE
		temp NUMBER;
	BEGIN
		toroltsor := 0;
		toroltorder := 0;
		DELETE from ORDIT WHERE QUANTITY = qtty AND PRODUCT_ID = prid;
		toroltsor := SQL%ROWCOUNT;
		DELETE FROM ORD WHERE ORDER_ID in (SELECT ORD.ORDER_ID FROM ORD LEFT JOIN ORDIT on ORD.ORDER_ID=ORDIT.ORDER_ID WHERE ORDIT.ORDER_ID is null);
		toroltorder := SQL%ROWCOUNT;
		END;
	END;/');
END;


504 Hívjuk meg az elõzõ feladat eljárását úgy, hogy a product neve alapján kikeressük az id-ját, és azt adjuk az eljárásnak paraméterként. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(504,'
    DECLARE
        v_prod_id product_information.product_id%type;
    BEGIN
        SELECT distinct d1.product_id
        into v_prod_id
        from order_items d1
        join product_information d2
        on d1.product_id = d2.product_id
        where product_name = ''LCD Monitor 9/PM'';
        
        deleteWhere(v_prod_id, 77);
    END;/');
END;

505. Írjunk blokkot, amely két egymásba ágyazott kurzorváltozó segítségével képernyõre írja az egyes termékeknek milyen nyelvû termékleírása van és mi az.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(505,'
    DECLARE
        v_termek SYS_REFCURSOR;
        v_nyelv SYS_REFCURSOR;
        r_termek oe.product_information.product_id%TYPE;
        r_nyelv oe.product_descriptions.language_id%TYPE;
    BEGIN
        OPEN v_termek FOR SELECT distinct product_id FROM OE.product_information;
        --OPEN r_termek FOR SELECT distinct language_id FROM oe.product_descriptions WHERE product_id=finded_prod;
        LOOP
            FETCH v_termek INTO r_termek;
            EXIT WHEN v_termek%NOTFOUND;
                dopl(r_termek);
                OPEN v_nyelv FOR SELECT language_id FROM oe.product_descriptions WHERE product_id=r_termek;
                LOOP
                    FETCH v_nyelv INTO r_nyelv;
                    EXIT WHEN v_nyelv%NOTFOUND;
                    --dopl(CHR(9) || r_nyelv);
                END LOOP;
                CLOSE v_nyelv;
        END LOOP;
        CLOSE v_termek;
    END;/');
END;


506 Az elõzõ feladatot írjuk meg egy explicit kurzorral és kurzor kifejezés segítségével. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(506,' --egy open van és van egy CURSOR kulcsszo
    DECLARE
        CURSOR c_nyelv IS SELECT distinct language_id FROM oe.product_descriptions WHERE product_id=1726;
        CURSOR c_leiras(v_lang_id oe.product_descriptions.language_id%TYPE)
                IS SELECT * FROM oe.product_descriptions WHERE language_id=v_lang_id AND product_id=1726;
                
        r_nyelv oe.product_descriptions.language_id%TYPE;
        r_leiras oe.product_descriptions%ROWTYPE;
    BEGIN
        --finded_prod := 1726;
        OPEN c_nyelv;
        LOOP
            FETCH c_nyelv INTO r_nyelv;
                EXIT WHEN c_nyelv%NOTFOUND;
                dopl(r_nyelv);
                OPEN c_leiras(r_nyelv);
                LOOP
                    FETCH c_leiras INTO r_leiras;
                    EXIT WHEN c_leiras%NOTFOUND;
                    dopl(CHR(9) || r_leiras.translated_description);
                END LOOP;
                CLOSE c_leiras;
        END LOOP;
        CLOSE c_nyelv;
    END;
    /');
END;

