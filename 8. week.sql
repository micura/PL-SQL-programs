801 "Hozzunk létre autonom triggert, amely akkor indul el, amikor egy gyümölcsök táblába (név és db oszloppal) 
egy sort szúrnak be, módosítanak, vagy törölnek. 
A trigger beszúr egy sort a napló táblába 
(amelynek az oszlopai a tábla neve, amelyet módosítanak, a felhasználó neve, 
aki módosít, az idõpont, amikor elvégzi a mûveletet, a mûvelet, és az, hogy mûvelet hány sort érint)."
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

802 "Írjunk blokkot, amely több utasítással módosítja a gyümölcsök táblát, 
majd visszavonja a tranzakciót, végül listázza a napló tábla tartalmát."
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(802,'
    declare
        cursor c1 is select * from newnaplo;
        c_row newnaplo%rowtype;
    BEGIN
        insert into gyumolcsok values (''banán'', 30);
        insert into gyumolcsok values (''ananász'', 25);
        delete from gyumolcsok where gyumolcs_neve = ''banán'';
        ROLLBACK;
        
        open c1;
        LOOP
            FETCH c1 INTO c_row;
            EXIT WHEN c1%NOTFOUND;
            dopl(c_row.USER_NAME || '' '' || c_row.N_DATE || '' '' ||c_row.TABLE_NAME || '' '' || c_row.ACTION || '' '' || c_row.counter);
        END LOOP;
    END;/');
 END;

803 "Írjunk blokkot, amely a gyümölcsök tábla név oszlopainak tartalmán végigmegy és statisztikát készít 
a benne szereplõ betûk darabszámáról. A feladatot asszociatív tömb segítségével oldjuk meg. 
A statisztikában minden betû csak egyszer szerepeljen."
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

804"	Hozzunk létre csomagot, amely egy olyan privát asszociatív tömböt menedzsel, 
amelynek az indextípusa karaktersorozat, az elemeinek a típusa szám. 
A csomag a következõ publikus elemeket tartalmazza: 
- eljárás, amely felvesz egy elemet a tömbbe 
(ha az elem létezik, akkor eldobja a létezõ elem publikus kivételt)
- eljárás, amely egy elemet módosít 
(ha az elem nem létezik, akkor egy nem létezõ elem publikus kivételt dob)
- eljárás, amely töröl egy elemet, 
- eljárás, amely két index között összes elemet törli, 
- eljárás, amely bejárja és képernyõre írja a tartalmát, 
- függvény, amely visszaadja a kollekció elemeinek számát, 
- függvény, amely visszaadja egy adott indexû elem értékét (ha nincs ilyen elem, akkor null értéket ad vissza)."
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
                dopl(''Nem létezõ elem'');
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


805 Írjunk blokkot, amely kipróbálja az elõzõ feladat összes eszközét.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(805,'
    begin
        assoc_array_manager.addElement(''Debrecen'', 1);
        assoc_array_manager.addElement(''Bumm'', 1);
        assoc_array_manager.addElement(''Cegléd'', 9999);
        assoc_array_manager.addElement(''Anglia'', 1122);
        assoc_array_manager.addElement(''Dánia'', 2321);
        --assoc_array_manager.addElement(''Debrecen'', 1); --Létezõ elem
        assoc_array_manager.modifyElement(''Debrecen'', 50);
        
        assoc_array_manager.addElement(''Budapest'', 100);
        assoc_array_manager.deleteElement(''Budapest'');
        assoc_array_manager.deletebetweenIndexes(''Anglia'', ''Cegléd'');
        dopl(assoc_array_manager.getElementNumber());
        dopl(assoc_array_manager.getElementValueByIndex(''Dánia''));
        assoc_array_manager.iterator();
    end;/');
END;
