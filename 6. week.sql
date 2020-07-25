601 Írjunk triggert, amely akkor indul el,  
amikor a customer táblába új sor kerül be vagy a customer tábla marital_status vagy gender oszlop módosul.  
Ha a gender nem 'M' vagy 'F' értéket kapott, akkor a trigger dobjon felhasználói kivételt -20010-es kóddal és "Nem megfelelõ nem" üzenettelvizsgálja meg.   
Ha a marital_status nem 'single' vagy 'married' értéket kapott, akkor dobjunk felhasználói kivételt -20011-es kóddal és "Nem megfelelõ családi állapot" üzenettel.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(601,'
    CREATE OR REPLACE TRIGGER tr_insert_update_customers
        BEFORE INSERT OR UPDATE OF gender, marital_status ON CUSTOMERS
        FOR EACH ROW
    BEGIN
        IF :NEW.gender != ''M'' and NOT :NEW.gender != ''F'' then
            RAISE_APPLICATION_ERROR(-20010, ''Nem megfelelõ nem'');
        END IF;
        IF :NEW.marital_status != ''single'' and :NEW.marital_status != ''married'' then
            RAISE_APPLICATION_ERROR(-20011, ''Nem megfelelõ családi állapot'');
        END IF;
    END tr_insert_update_customers;/');
END;

602 Az elõzõ feladat triggerét próbáljuk ki beszúrással és módosítással is. A kapott kivételeket (csak azokat) kapjuk el és kezeljük.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(602,'
    DECLARE
        gender_err EXCEPTION;
        PRAGMA EXCEPTION_INIT( gender_err, -20010);
        marital_status_err EXCEPTION;
        PRAGMA EXCEPTION_INIT( marital_status_err, -20011);
    BEGIN
        INSERT INTO CUSTOMERS (CUSTOMER_ID ,CUST_FIRST_NAME, CUST_LAST_NAME)
            VALUES (997, ''Hello'', ''Kitti'');
            
        UPDATE CUSTOMERS
        SET gender = ''M''
        where CUSTOMER_ID=997;
        
        UPDATE CUSTOMERS
        SET marital_status = ''singlee''
        where CUSTOMER_ID=997;
        
        EXCEPTION WHEN gender_err THEN
            DOPL(''Rossz nem'');
        WHEN marital_status_err then
            dopl(''Rosszul csaladi allapotot...'');
    END;/');
END;

603 Írjunk triggert, amely akkor indul el, amikor új ügyfelet vagy terméket veszünk fel vagy ügyfelet vagy terméket törlünk. 
A trigger egy új, napló nevû táblába írja be, hogy melyik felhasználó, mikor melyik táblábát módosította és milyen mûveletet hajtott végre. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(603,'    
    CREATE OR REPLACE TRIGGER new_customer
        AFTER INSERT OR DELETE ON CUSTOMERS
            FOR EACH ROW
    BEGIN
        IF INSERTING THEN
            INSERT INTO naplo
            values(user, sysdate, ''customers'', ''insert'');
        ELSIF DELETING THEN
            INSERT INTO naplo
            values(user, sysdate, ''customers'', ''delete'');
        END IF;
    END;
    /
    create or replace TRIGGER new_product_information
        BEFORE INSERT OR DELETE ON product_information
            FOR EACH ROW
    BEGIN
        IF INSERTING THEN
            INSERT INTO naplo
            values(user, sysdate, ''product_information'', ''insert'');
        ELSIF DELETING THEN
            INSERT INTO naplo
            values(user, sysdate, ''product_information'', ''delete'');
        END IF;
    END;/');
END;

            CREATE TABLE naplo(
                user_name varchar2(20) NOT NULL,
                n_date date NOT NULL,
                table_name varchar2(20) NOT NULL,
                action varchar2(10) NOT NULL
            );
604 Az elõzõ feladat triggerét próbáljuk ki több mûvelet segítségével.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(604,'    
    BEGIN
        insert into customers
        values (9998, ''Hello'', ''Steve'', null, null, null, null, null, null, null, null, null, null, null, null);
    END;/');
END;


605 Hozzunk létre táblát hallgatok néven. A táblának két oszlop legyen, az egyikben a hallgató nevét, a másikban a hallgató neptunkódját tároljuk. 
Ez utóbbi legyen a tábla elsõdleges kulcsa. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(605,'  
    CREATE TABLE hallgatok (
          hallgato_neve varchar2(50),
          hallgato_neptun_kod varchar2(6),
          constraint hallgatok_pk PRIMARY KEY (hallgato_neptun_kod)
    );/');
END;


606. Írjunk triggereket, amelyek a hallgató táblából való törlésre indul el, rendre utasítás elõtt,   sor elõtt, utasítás után, sor után.   
A triggerek írják ki a képernyõre, hogy õk éppen melyik triggerek, azaz utasítás elõtt/után, sor elõtt/után
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(606,'  
    CREATE OR REPLACE TRIGGER deleting_before_statement
    BEFORE DELETE ON hallgatok
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Utasitas elotti trigger'');
    END deleting_before_statement;
    /
    CREATE OR REPLACE TRIGGER deleting_after_statement
    AFTER DELETE ON hallgatok
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Utasitas utani trigger'');
    END deleting_after_statement;
    /
    CREATE OR REPLACE TRIGGER deleting_before_row
    BEFORE DELETE ON hallgatok
    FOR EACH ROW
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Sor elotti trigger'');
    END deleting_before_row;
    /
    CREATE OR REPLACE TRIGGER deleting_after_row
    AFTER DELETE ON hallgatok
    FOR EACH ROW
    BEGIN
        DBMS_OUTPUT.PUT_LINE(''Sor utani trigger'');
    END deleting_after_row;/');
END;

607. Töröljünk egyszerre 5 sort a hallgatok táblából, amivel kipróbáljuk az elõzõ triggert. 
Majd írjunk olyan törlést, amely egyetlen sort sem töröl. Nézzük meg a triggerek által kiírt eredményt.
INSERT INTO hallgatok 
values('Adam', 123456);
INSERT INTO hallgatok 
values('Feri', 234567);
INSERT INTO hallgatok 
values('Dani', 345678);
INSERT INTO hallgatok 
values('Jani', 456789);
INSERT INTO hallgatok 
values('Vili', 567890);

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(607,'  
    BEGIN
        DELETE FROM hallgatok
        where hallgato_neve in (''Adam'', ''Feri'', ''Dani'', ''Jani'', ''Vili'');
        
        DELETE FROM hallgatok
        where hallgato_neve like ''aaaaaasdwdwadasd'';
    END;/');
END;

608. Írjunk triggert, amely megakadályozza, hogy a napló táblát (amit most hozunk létre) módosítsák vagy töröljék (beszúrni lehessen bele), 
azaz a trigger egy felhasználó kivételt dob -20003-as kóddal és "Érvénytelen mûvelet" üzenettel.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(608,'     
    CREATE OR REPLACE TRIGGER warningNaplo 
        BEFORE UPDATE or DELETE ON naplo
    BEGIN
        RAISE_APPLICATION_ERROR(-20003, ''Érvénytelen muvelet'');
    END;/');
END;

609. Írjunk blokkot, amely elõször beszúr egy sort a napló táblába, véglegesíti azt a mûveletet, majd töröli a sort a napló táblából, 
és véglegesíti a mûveletet.  A kapott kivételt a blokk kapja el (csak azt a kivételt), és írja ki a hiba üzenetét a képernyõre.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(609,'      
    DECLARE
        ervenytelen EXCEPTION;
        PRAGMA EXCEPTION_INIT(ervenytelen, -20003);
    BEGIN
        INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
        VALUES (''Adam'', sysdate, ''naplo'', ''INSERTING'');
        COMMIT;
        
        DELETE FROM NAPLO
        WHERE USER_NAME=''Adam'';
        COMMIT;
        
        EXCEPTION 
            WHEN ervenytelen THEN
                DBMS_OUTPUT.PUT_LINE(''Ervenytelen muvelet'');
    END;/');
END;

610 Írjunk triggert, amely a customer és a product táblákon történõ bármely DML mûveletet naplózza, azaz beszúr egy megfelelõ sort a napló táblába.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(610,'     
    CREATE OR REPLACE TRIGGER del_ins_upd_on_customer
        BEFORE DELETE OR INSERT OR UPDATE on CUSTOMERS
    begin
        IF deleting THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''customers'', ''delete'');
        ELSIF inserting THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''customers'', ''insert'');
        ELSIF updating THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''customers'', ''update'');
        END IF;
    end del_ins_upd_on_customer;
    /
    CREATE OR REPLACE TRIGGER del_ins_upd_on_product
        BEFORE DELETE OR INSERT OR UPDATE on PRODUCT_INFORMATION
    begin
        IF deleting THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''product_information'', ''delete'');
        ELSIF inserting THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''product_information'', ''insert'');
        ELSIF updating THEN 
            INSERT INTO NAPLO(USER_NAME, N_DATE, TABLE_NAME, ACTION)
            VALUES (user, sysdate, ''product_information'', ''update'');
        END IF;
    end del_ins_upd_on_product;/');
END;



