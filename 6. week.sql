601 �rjunk triggert, amely akkor indul el,  
amikor a customer t�bl�ba �j sor ker�l be vagy a customer t�bla marital_status vagy gender oszlop m�dosul.  
Ha a gender nem 'M' vagy 'F' �rt�ket kapott, akkor a trigger dobjon felhaszn�l�i kiv�telt -20010-es k�ddal �s "Nem megfelel� nem" �zenettelvizsg�lja meg.   
Ha a marital_status nem 'single' vagy 'married' �rt�ket kapott, akkor dobjunk felhaszn�l�i kiv�telt -20011-es k�ddal �s "Nem megfelel� csal�di �llapot" �zenettel.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(601,'
    CREATE OR REPLACE TRIGGER tr_insert_update_customers
        BEFORE INSERT OR UPDATE OF gender, marital_status ON CUSTOMERS
        FOR EACH ROW
    BEGIN
        IF :NEW.gender != ''M'' and NOT :NEW.gender != ''F'' then
            RAISE_APPLICATION_ERROR(-20010, ''Nem megfelel� nem'');
        END IF;
        IF :NEW.marital_status != ''single'' and :NEW.marital_status != ''married'' then
            RAISE_APPLICATION_ERROR(-20011, ''Nem megfelel� csal�di �llapot'');
        END IF;
    END tr_insert_update_customers;/');
END;

602 Az el�z� feladat trigger�t pr�b�ljuk ki besz�r�ssal �s m�dos�t�ssal is. A kapott kiv�teleket (csak azokat) kapjuk el �s kezelj�k.
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

603 �rjunk triggert, amely akkor indul el, amikor �j �gyfelet vagy term�ket vesz�nk fel vagy �gyfelet vagy term�ket t�rl�nk. 
A trigger egy �j, napl� nev� t�bl�ba �rja be, hogy melyik felhaszn�l�, mikor melyik t�bl�b�t m�dos�totta �s milyen m�veletet hajtott v�gre. 
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
604 Az el�z� feladat trigger�t pr�b�ljuk ki t�bb m�velet seg�ts�g�vel.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(604,'    
    BEGIN
        insert into customers
        values (9998, ''Hello'', ''Steve'', null, null, null, null, null, null, null, null, null, null, null, null);
    END;/');
END;


605 Hozzunk l�tre t�bl�t hallgatok n�ven. A t�bl�nak k�t oszlop legyen, az egyikben a hallgat� nev�t, a m�sikban a hallgat� neptunk�dj�t t�roljuk. 
Ez ut�bbi legyen a t�bla els�dleges kulcsa. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(605,'  
    CREATE TABLE hallgatok (
          hallgato_neve varchar2(50),
          hallgato_neptun_kod varchar2(6),
          constraint hallgatok_pk PRIMARY KEY (hallgato_neptun_kod)
    );/');
END;


606. �rjunk triggereket, amelyek a hallgat� t�bl�b�l val� t�rl�sre indul el, rendre utas�t�s el�tt,   sor el�tt, utas�t�s ut�n, sor ut�n.   
A triggerek �rj�k ki a k�perny�re, hogy �k �ppen melyik triggerek, azaz utas�t�s el�tt/ut�n, sor el�tt/ut�n
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

607. T�r�lj�nk egyszerre 5 sort a hallgatok t�bl�b�l, amivel kipr�b�ljuk az el�z� triggert. 
Majd �rjunk olyan t�rl�st, amely egyetlen sort sem t�r�l. N�zz�k meg a triggerek �ltal ki�rt eredm�nyt.
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

608. �rjunk triggert, amely megakad�lyozza, hogy a napl� t�bl�t (amit most hozunk l�tre) m�dos�ts�k vagy t�r�lj�k (besz�rni lehessen bele), 
azaz a trigger egy felhaszn�l� kiv�telt dob -20003-as k�ddal �s "�rv�nytelen m�velet" �zenettel.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(608,'     
    CREATE OR REPLACE TRIGGER warningNaplo 
        BEFORE UPDATE or DELETE ON naplo
    BEGIN
        RAISE_APPLICATION_ERROR(-20003, ''�rv�nytelen muvelet'');
    END;/');
END;

609. �rjunk blokkot, amely el�sz�r besz�r egy sort a napl� t�bl�ba, v�gleges�ti azt a m�veletet, majd t�r�li a sort a napl� t�bl�b�l, 
�s v�gleges�ti a m�veletet.  A kapott kiv�telt a blokk kapja el (csak azt a kiv�telt), �s �rja ki a hiba �zenet�t a k�perny�re.
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

610 �rjunk triggert, amely a customer �s a product t�bl�kon t�rt�n� b�rmely DML m�veletet napl�zza, azaz besz�r egy megfelel� sort a napl� t�bl�ba.
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



