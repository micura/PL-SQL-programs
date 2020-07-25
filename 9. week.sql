901 K�sz�ts�nk csomagot, amelyben egy priv�t kurzort deklar�lunk, 
amely azoknak a dolgoz�knak a nev�t �s az azonos�t�j�t list�zza, akiknek a fizet�se 
kevesebb mint egy param�terben kapott �rt�k.
A csomag tartalmazzon egy elj�r�st, amely kinyitja a kurzort, 
ha az nincs nyitva, majd kiolvas a kurzorb�l 10 sort, 
amelyet egy publikus dinamikus t�mbben t�rol. 
Ha a kurzorban nincs t�bb sor, akkor lez�rja a kurzort, �s �jra megnyitja.
--bulk collect into-val (mert 10es�vel)
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
    
902. �rjunk blokkot, amelyben megh�vjuk az el�z� feladat csomagj�nak az elj�r�s�t, 
majd k�perny�re �rja a kollekci� elemeit. Majd m�g k�tszer h�vjuk meg a blokkot.
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
        
903. �rjunk blokkot, amelyben deklar�lunk h�rom be�gyazott t�bl�t, amelynek az elemei rendre job_title-k, min_salary-k �s max_salary-k lesznek. 
Olvassuk fel a kollekci�kba a jobs t�bla minden sor�t. Majd t�r�lj�k ki azokat a job_title-ket, amelyek eset�n a min_salary t�bb, mint a max_salary fele. 
List�zzuk a megmaradt job_title-ket a k�perny�re. Majd minden olyan dolgoz�nak, akik ebben a kollekci�ban maradt munkak�rben dolgozik, 
emelj�k meg a fizet�s�t a max_salary 10%-�val. A feladatban haszn�ljuk az egy�ttes hozz�rendel�st (BULK COLLECT, FORALL). 
V�gleges�ts�k a tranzakci�t.
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

904 Hozzunk l�tre egy be�gyazott t�bla t�pust keresztnevekhez, az elemeinek a t�pusa varchar2(30) legyen.

BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(904,'
    CREATE OR REPLACE TYPE egy_beagyaott_tabla_tipus IS TABLE OF varchar2(30);/');
END;

    
905 "�runkj t�rolt elj�r�st, amely param�terk�nt az el�z� feladat be�gyazott t�blat�pus�t kapja, 
majd a k�perny�re list�zza abc sorrendben, hogy melyik karaktersorozatb�l (keresztn�vb�) h�ny darab van a be�gyazott t�bl�ban. 
A feladat megold�s�hoz asszociat�v t�mb�t haszn�ljunk."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(905,'    
        CREATE OR REPLACE PROCEDURE list_caracter_of_surname(p_keresztnevek  egy_beagyaott_tabla_tipus) IS
        TYPE t_gyakorisag IS TABLE OF number INDEX BY varchar2(30);
        v_Elofordulasok t_gyakorisag;
        i VARCHAR2(30);
    BEGIN
        IF p_keresztnevek IS NULL
            THEN dopl(''NULL �rt�k? kollekci�'');
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

906 "T�lts�k fel egy�ttes hozz�rendel�ssel egy v�ltoz�t, amelynek a t�pusa az 2-es feladat be�gyazott t�bl�ja
a customers t�bla keresztneveivel, majd h�vjuk meg az el�z� t�rolt elj�r�st. "
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

907. "�rjunk t�rolt f�ggv�nyt, amely param�terk�nt kap egy warehouse nevet, �s visszaad egy be�gyazott t�bl�t, 
amely az adott warehouse-ban l�v� �sszes term�k nev�t (product_name a product_descriptionb�l) tartalmazza (mindegyiket csak egyszer). 
A feladatot egy�ttes hozz�rendel�ssel oldjuk meg."
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

908 H�vjuk meg az el�z� t�rolt f�ggv�nyt, �s �rjuk ki a k�perny�re a kapott kollekci� tartalm�t.
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

909 Hozzunk l�tre csomagot, amely az oe schema customer t�bl�j�nak telefonsz�m oszlop�t kezeli. Tartalmazzon
- elj�r�st, amely felvesz egy param�terk�nt kapott telefonsz�mot egy customerhez, amelynek az azonos�t�j�t az elj�r�s param�terk�nt kapja
- elj�r�st, amely t�r�l egy param�terk�nt kapott telefonsz�mot egy customer eset�n, amelynek az azonos�t�j�t az elj�r�s param�terk�nt kapja
- elj�r�st, amely egy customer param�terk�nt kapott telefonsz�m�t egy m�sik, param�terk�nt kapott telefonsz�mra cser�l. A customer id-j�t az elj�r�s param�terk�nt kapja.
- elj�r�st, amely besz�r egy sort a customer t�bl�ba, (nem kell felt�tlen�l minden oszlopot kit�lteni, de a telefonsz�mot t�ltse ki. Maximum egy telefonsz�mot kapjon az elj�r�s param�terk�nt)

CREATE OR REPLACE PACKAGE phone_manager AS
    procedure felvesz (p_phone_number varchar, p_cust_id customers.customer_id%type);
    procedure torol (p_phone_number varchar, p_cust_id customers.customer_id%type);
    procedure cserel (p_mit varchar, p_mire varchar,p_cust_id customers.customer_id%type );
    procedure beszur (p_phone_number varchar);
END phone_manager;

CREATE OR REPLACE PACKAGE BODY phone_manager AS

END phone_manager;

select * from customers;