501 -�rjunk csomagot, amelyben deklar�lunk egy priv�t explicit kurzort, amely param�terk�nt 
egy customer azonos�t�j�t kapja, �s lek�rdezi, hogy az adott v�s�rl� mely warehouse-okban v�s�rolt eddig. 
A warehouse-ok nev�t �s id-j�t csak egyszer list�zza. 
- A csomag tartalmazzon egy publikus elj�r�st, amely a customer nev�hez visszaadja az azonos�t�j�t. 
    Ha ilyen �gyf�l nem l�tezik, akkor dobjon el egy 
    a csomagban publikusk�nt deklar�lt exc_no_cust nev� kiv�telt.  
    Ha t�bb ilyen �gyf�l l�tezik, akkor dobjon el egy 
    a csomagban publikusk�nt deklar�lt exc_too_many_cust nev� kiv�telt.
- A csomag tartalmazzon egy publikus elj�r�st, param�terk�nt  kapott v�s�rl� id-val megnyitja a kurzort. 
- A csomag tartalmazzon egy publikus elj�r�st, amely lez�rja a kurzort.
- A csomag tartalmazzon egy publikus f�ggv�nyt, amely felolvas 10 sort a kurzorb�l. 
    Ha m�r nincs 10 sor, akkor csak annyi sort olvasson fel, amennyit tal�lt. 
    Visszat�r�si �rt�ke a felolvasott sorok sz�ma legyen. 

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
        
502.�rjunk blokkot, amely az el�z� feladat csomagj�nak megfelel� eszk�zeit haszn�lja:
- adott customern�vhez kikeresi a customer id-j�t, 
- amelyre megnyitja a kurzort, 
- felolvassa a kurzor �sszes sor�t
- lez�rja a kurzort.
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

503 "�rjunk t�rolt elj�r�st, amely param�terk�nt kapott product_id �s 
quantity eset�n t�rli azokat a sorokat az order_items t�bl�b�l, 
amelyek ezt a term�ket ilyen mennyis�gben tartalmazz�k.
Adjuk vissza, hogy a t�bl�b�l h�ny sort t�r�lt.
Ha az adott order_id-n nincs t�bb line_item_id, akkor t�r�lj�k az orders t�bla megfelel� sor�t is. 
Az elj�r�s azt is adja vissza, hogy t�r�lt-e sort az orders t�bl�b�l. "

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


504 H�vjuk meg az el�z� feladat elj�r�s�t �gy, hogy a product neve alapj�n kikeress�k az id-j�t, �s azt adjuk az elj�r�snak param�terk�nt. 
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

505. �rjunk blokkot, amely k�t egym�sba �gyazott kurzorv�ltoz� seg�ts�g�vel k�perny�re �rja az egyes term�keknek milyen nyelv� term�kle�r�sa van �s mi az.
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


506 Az el�z� feladatot �rjuk meg egy explicit kurzorral �s kurzor kifejez�s seg�ts�g�vel. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(506,' --egy open van �s van egy CURSOR kulcsszo
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

