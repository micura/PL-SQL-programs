701 ""�rjunk t�rolt elj�r�st, amely param�terk�nt kapott rakt�r minden olyan term�ke eset�n, 
amely csak az adott rakt�rban tal�lhat�, megemeli a term�k �r�t 10%-kal. 
A megold�sban for update utas�t�sr�sszel z�roljuk a m�dos�tand� term�keket, 
�s a m�dos�t�shoz haszn�ljuk a current of utas�t�sr�szet.
A z�rol�s csak a term�kek t�bl�ra vonatkozzon 
(azaz be�gyazott selectet haszn�ljunk, �s a k�ls� select from r�sz�ben csak a term�kek t�bla szerepeljen.)""
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

702 �rjunk blokkot, amely megh�vja az el�z� feladat t�rolt elj�r�s�t, �s lez�rja a tranzakci�t.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(702,'
    BEGIN 
        increasePruductPrice(''Sydney'');
        commit;
    END;/');
END;

703. ""Hozzunk l�tre t�bl�t konyvek n�ven, amelyben k�nyveknek az ISBN sz�m�t, c�m�t, 
kiad�j�t �s a kiad�s �v�t t�roljuk. 
A t�bla els�dleges kulcsa az ISBN legyen. ""
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

704 ""Hozzunk l�tre csomagot, amelynek a seg�ts�g�vel az el�z� feladat t�bl�j�t haszn�lni tudjuk. 
A csomag tartalmazzon egy beszur_konyv nev� publikus elj�r�st, egy t�r�l k�nyv nev� publikus f�ggv�nyt, 
egy list�z nev� publikus elj�r�st, �s egy letezo_ISBN nev� kiv�telt �s egy nincs_ilyen_konyv kiv�telt. 

A beszur_konyv nev� elj�r�s param�terk�nt kapjon ISBN, c�m, kiad�, kiad�s �ve �rt�keket. 
Sz�rja be a k�nyv t�bl�ba az �rt�keket. Ha ott a k�nyv megtal�lhat�, �s az �rt�kek nem felelnek meg,  
akkor a letezo_ISBN kiv�telt dobjuk. 

A t�r�l k�nyv nev� f�ggv�ny param�terk�nt egy ISBN sz�mot kap, 
�s kit�r�li az adott k�nyvet, majd visszat�r�si �rt�kk�nt adja vissza, 
hogy mi volt a k�nyv c�me. 
Ha az ISBN sz�m nem l�tezik, akkor ne t�rt�njen semmi. 

A list�z nev� elj�r�shoz defini�ljunk egy priv�t kurzort, 
amely param�terk�nt kapott kiad�hoz list�zza az ISBN sz�mokat �s a k�nyvc�meket. 
Az elj�r�s megnyitja a kurzort, ha m�g nincs nyitva, 
egy sort felolvas, majd param�terk�nt visszaadja az eredm�nyeket. 
(Ezt egy publikus rekordt�pusban tegy�k meg.) 
Ha a kurzorban nem tal�lnuk t�bb sort, akkor null �rt�ket adjunk vissza. 
Ha nem tal�l ilyen ISBN sz�m� k�nyvet, akkor nincs ilyen k�nyv kiv�telt dob.""
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

705 ""Pr�b�ljuk ki az el�z� feladat csomagj�nak az esz�zeit. 
Vegy�nk fel a t�bl�ba sorokat, ugyanolyan ISBN sz�mmal rendelkez�eket is, pr�b�ljuk ki a lehets�ges kiv�teleket. 
T�r�lj�nk k�nyvet, n�zz�k meg a f�ggv�ny visszat�r�si �rt�k�t, pr�b�ljuk ki a lehets�ges kiv�telt, kapjuk el. 
A list�z elj�r�st pr�b�ljuk ki �gy, hogy adott kiad�hoz minden l�tez� k�nyvet list�zzunk ki. Pr�b�ljuk ki itt is a kiv�telt, kapjuk el.""
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

706. ""�rjunk t�rolt elj�r�st, amely param�terk�nt egy gyenge kurzorv�ltoz�t kap, 
ha a kurzorv�ltoz� nincs nyitva, akkor dob egy 'Nincs nyitva a kurzov�ltoz��' hiba�zenetet dob, 
ha nyitva van, akkor egy sz�m �s egy sz�veges rekordt�pus� sort olvas ki a kurzorv�ltoz�b�l, 
amely �rt�keket a t�rolt elj�r�s kimen� param�terben visszaadja. 
Ha a kurzorv�ltoz�ban m�r nincs t�bb sor, akkor dobjon 'nincs t�bb sor' �zenettel hib�t.""
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
            dopl(''Nincs nyitva a kurzov�ltoz��'');
        else 
            FETCH p_refc INTO p_szam, p_szoveg;
        END IF;
        IF p_refc%NOTFOUND THEN
                dbms_output.put_line(''nincs t�bb sor'');
        END IF;
    END;/');
END;


707 ""�rjunk blokkot, amely egy er�s kurzorv�ltoz�t deklar�l, 
amelyhez egy sz�m �s egy sz�veges t�pus� mez�ket tartalmaz� rekordot rendel�nk. 
A blokk nyissa meg a kurzort a hr s�ma department t�bl�j�nk id �s name oszlopaihoz, 
majd h�vja meg 3-szor az el�z� feladat f�ggv�ny�t. 
A kurzorv�ltoz� lez�r�sa n�lk�l rendelj�nk a kurzorv�ltoz�hoz egy lek�rdez�st, 
amely a hr s�ma employee t�bl�j�nak id �s name oszlopait adja vissza, 
majd erre is h�vjuk meg az el�z� feladat f�ggv�ny�t. 
Ha a lek�rdez�sben nincs t�bb sor, akkor a kapott kiv�telt kapjuk el. 
�rj�k el, hogy a 2. lek�rdez�shez tartoz� h�v�sok akkor is fussanak le, ha az els� r�sz hib�t dobott.
""
BEGIN --�rj�k el, hogy a 2. lek�rdez�shez tartoz� h�v�sok akkor is fussanak le, ha az els� r�sz hib�t dobott.
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
