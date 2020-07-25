801 "Hozzunk l�tre autonom triggert, amely akkor indul el, amikor egy gy�m�lcs�k t�bl�ba (n�v �s db oszloppal) 
egy sort sz�rnak be, m�dos�tanak, vagy t�r�lnek. 
A trigger besz�r egy sort a napl� t�bl�ba 
(amelynek az oszlopai a t�bla neve, amelyet m�dos�tanak, a felhaszn�l� neve, 
aki m�dos�t, az id�pont, amikor elv�gzi a m�veletet, a m�velet, �s az, hogy m�velet h�ny sort �rint)."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(801,'
   CREATE OR REPLACE PROCEDURE insert_naplo(v_username VARCHAR2, actual_date DATE, table_name VARCHAR2, v_operation VARCHAR2, row_number NUMBER) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO NewNaplo
        VALUES(v_username, table_name, actual_date, v_operation, row_number);
        COMMIT;
    END;/
    create or replace TRIGGER forFruitsTable
        FOR INSERT OR UPDATE OR DELETE ON GYUMOLCSOK COMPOUND TRIGGER
            szamlalo number := 0;
        BEFORE STATEMENT IS
        BEGIN
            szamlalo := szamlalo+1;
        END BEFORE STATEMENT;
                
        AFTER EACH ROW IS 
        BEGIN
            IF INSERTING THEN
                insert_naplo(USER, sysdate, ''GYUMOLCSOK'', ''INSERT'' ,szamlalo);
            END IF;
            IF UPDATING THEN
                insert_naplo(USER, sysdate, ''GYUMOLCSOK'', ''UPDATE'' ,szamlalo);
            END IF;
            iF DELETING THEN
                insert_naplo(USER, sysdate, ''GYUMOLCSOK'', ''DELETE'' ,szamlalo);
            END IF;
         END AFTER EACH ROW;
    END forFruitsTable;/');
 END;

802 "�rjunk blokkot, amely t�bb utas�t�ssal m�dos�tja a gy�m�lcs�k t�bl�t, 
majd visszavonja a tranzakci�t, v�g�l list�zza a napl� t�bla tartalm�t."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(802,'
    declare
        cursor c1 is select * from newnaplo;
        c_row newnaplo%rowtype;
    BEGIN
        insert into gyumolcsok values (''ban�n'', 30);
        insert into gyumolcsok values (''anan�sz'', 25);
        delete from gyumolcsok where gyumolcs_neve = ''ban�n'';
        ROLLBACK;
        
        open c1;
        LOOP
            FETCH c1 INTO c_row;
            EXIT WHEN c1%NOTFOUND;
            dopl(c_row.USER_NAME || '' '' || c_row.N_DATE || '' '' ||c_row.TABLE_NAME || '' '' || c_row.ACTION || '' '' || c_row.counter);
        END LOOP;
    END;/');
 END;

803 "�rjunk blokkot, amely a gy�m�lcs�k t�bla n�v oszlopainak tartalm�n v�gigmegy �s statisztik�t k�sz�t 
a benne szerepl� bet�k darabsz�m�r�l. A feladatot asszociat�v t�mb seg�ts�g�vel oldjuk meg. 
A statisztik�ban minden bet� csak egyszer szerepeljen."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(803,'
    DECLARE 
        CURSOR c1 is 
        SELECT gyumolcs_neve from gyumolcsok;
        v_gyum_nev gyumolcsok.gyumolcs_neve%type;
        
        c VARCHAR2(1 CHAR);
        TYPE t_gyakorisag IS TABLE OF NUMBER INDEX BY c%TYPE;
        v_Elofordulasok t_gyakorisag;
    BEGIN
        OPEN C1;
        loop
            fetch c1 into v_gyum_nev;
            EXIT WHEN c1%NOTFOUND;
            dopl(v_gyum_nev);
                FOR i IN 1..LENGTH(v_gyum_nev)
                    LOOP
                    c := LOWER(SUBSTR(v_gyum_nev, i, 1));
                        IF v_Elofordulasok.EXISTS(c) THEN
                            v_Elofordulasok(c) := v_Elofordulasok(c)+1;
                        ELSE 
                            v_Elofordulasok(c) := 1;
                        END IF;
                    END LOOP;
        END LOOP;
        c := v_Elofordulasok.FIRST;
        WHILE c IS NOT NULL LOOP
            dopl('' " '' || c || '' " '' || v_Elofordulasok(c));
            c := v_Elofordulasok.NEXT(c);
        end loop;
    END;/');
 END;

804"	Hozzunk l�tre csomagot, amely egy olyan priv�t asszociat�v t�mb�t menedzsel, 
amelynek az indext�pusa karaktersorozat, az elemeinek a t�pusa sz�m. 
A csomag a k�vetkez� publikus elemeket tartalmazza: 
- elj�r�s, amely felvesz egy elemet a t�mbbe 
(ha az elem l�tezik, akkor eldobja a l�tez� elem publikus kiv�telt)
- elj�r�s, amely egy elemet m�dos�t 
(ha az elem nem l�tezik, akkor egy nem l�tez� elem publikus kiv�telt dob)
- elj�r�s, amely t�r�l egy elemet, 
- elj�r�s, amely k�t index k�z�tt �sszes elemet t�rli, 
- elj�r�s, amely bej�rja �s k�perny�re �rja a tartalm�t, 
- f�ggv�ny, amely visszaadja a kollekci� elemeinek sz�m�t, 
- f�ggv�ny, amely visszaadja egy adott index� elem �rt�k�t (ha nincs ilyen elem, akkor null �rt�ket ad vissza)."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(804,'
    CREATE OR REPLACE PACKAGE assoc_array_manager AS
        TYPE private_Assoc_Array IS TABLE OF number
        INDEX BY varchar2(20);
        managed_array private_Assoc_Array;
    
        letezo_elem EXCEPTION;
        nem_letezo_elem EXCEPTION;
    
        PROCEDURE addElement(p_index varchar2, p_value number);
        
        PROCEDURE modifyElement(p_index varchar2,p_value number);
        
        PROCEDURE deleteElement(p_index varchar2);
        
        PROCEDURE deletebetweenIndexes(p_first varchar2,p_last varchar2);
        
        PROCEDURE iterator;
        FUNCTION getElementNumber RETURN number;
        FUNCTION getElementValueByIndex(p_index varchar2) RETURN number;
    end assoc_array_manager;/
    CREATE OR REPLACE PACKAGE body assoc_array_manager AS
        PROCEDURE addElement(p_index varchar2, p_value number) IS
        BEGIN
            IF managed_array.EXISTS(p_index) THEN
                RAISE letezo_elem;
            ELSE
                managed_array(p_index) := p_value;
            END IF;
            
            EXCEPTION WHEN letezo_elem THEN
                dopl(''Letezo elem'');
        END;
        
        PROCEDURE modifyElement(p_index varchar2, p_value number) IS
        BEGIN
            IF managed_array.exists(p_index) = true THEN
                managed_array(p_index) := p_value;
            ELSE
                RAISE nem_letezo_elem;
            END IF;
            
            EXCEPTION WHEN nem_letezo_elem THEN
                dopl(''Nem l�tez� elem'');
        END;
        
        PROCEDURE deleteElement(p_index varchar2) IS
        BEGIN
            managed_array.delete(p_index);
        END;
        
        PROCEDURE deletebetweenIndexes(p_first varchar2, p_last varchar2)
        IS
        BEGIN
            managed_array.delete(p_first, p_first);
        END;
        
        PROCEDURE iterator IS
            i VARCHAR2(64); 
        BEGIN
            i := managed_array.FIRST;
            WHILE i IS NOT NULL
            LOOP
                dopl(''Index of Associative array: '' || i || '' value: '' || managed_array(i));
                i := managed_array.NEXT(i);
            END LOOP; 
        END;
        
        FUNCTION getElementNumber RETURN number is
            counter number(3);
        BEGIN
            counter := managed_array.count;
            RETURN counter;
        END;
        
        FUNCTION getElementValueByIndex(p_index varchar2) RETURN number is
            f_value number(10);
        BEGIN
            f_value := managed_array(p_index);
            RETURN f_value;
            
            EXCEPTION WHEN NO_DATA_FOUND THEN
                RETURN null;
        END;
    end assoc_array_manager;/');
 END;


805 �rjunk blokkot, amely kipr�b�lja az el�z� feladat �sszes eszk�z�t.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(805,'
    begin
        assoc_array_manager.addElement(''Debrecen'', 1);
        assoc_array_manager.addElement(''Bumm'', 1);
        assoc_array_manager.addElement(''Cegl�d'', 9999);
        assoc_array_manager.addElement(''Anglia'', 1122);
        assoc_array_manager.addElement(''D�nia'', 2321);
        --assoc_array_manager.addElement(''Debrecen'', 1); --L�tez� elem
        assoc_array_manager.modifyElement(''Debrecen'', 50);
        
        assoc_array_manager.addElement(''Budapest'', 100);
        assoc_array_manager.deleteElement(''Budapest'');
        assoc_array_manager.deletebetweenIndexes(''Anglia'', ''Cegl�d'');
        dopl(assoc_array_manager.getElementNumber());
        dopl(assoc_array_manager.getElementValueByIndex(''D�nia''));
        assoc_array_manager.iterator();
    end;/');
END;
