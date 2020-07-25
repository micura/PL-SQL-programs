301 �rjunk blokkot, amelyben deklar�lunk egy f�ggv�nyt, amely param�terk�nt egy �gyf�l azonos�t�j�t �s d�tumot kap, �s visszaadja, hogy az �gyf�lnek az adott d�tum ut�n h�ny megrendel�se volt. 
A blokk minden 'T' bet�vel kezd�d� nev� �gyf�lre h�vja meg a f�ggv�nyt, a d�tum param�terbe a f�ggv�ny a 2005. 01.01-et kapjon
�s �rja ki az �gyf�l nev�t, �s a darabsz�mot a k�perny�re.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(301,'
    DECLARE
        cust_id customers.customer_id%type;
        ord_date DATE;
    FUNCTION orderAfterDate(cust_id IN customers.customer_id%type, ord_date IN DATE)
    RETURN NUMBER IS
        b number;
    BEGIN
        SELECT COUNT(T2.ORDER_DATE)
                INTO b
                FROM CUSTOMERS T1
                LEFT JOIN ORDERS T2
                ON T1.CUSTOMER_ID = T2.CUSTOMER_ID
                WHERE T2.order_date > ord_date;
        RETURN b;
    END;
    BEGIN
        FOR item IN (SELECT T1.CUSTOMER_ID, T1.CUST_FIRST_NAME,  T1.CUST_LAST_NAME
                    FROM CUSTOMERS T1
                    WHERE lower(CUST_LAST_NAME) like ''t%'')
        LOOP
            dopl(item.CUST_FIRST_NAME || '' '' || item.CUST_LAST_NAME || '' '' || orderAfterDate(item.CUSTOMER_ID, TO_DATE(''2005.01.01'', ''YYYY.MM.DD'')));
        END LOOP;
    END;/');
END;

302 �rjunk blokkot, amelyben deklar�lunk egy elj�r�st, amely param�terk�nt kap egy sz�mot, 
�s visszaadja (kimen� param�terben) annak a gy�k�t, a n�gyzet�t �s az abszol�t �rt�k�t. 
A blokk megh�vja az elj�r�st -100 �s 100 k�z�tt minden eg�sz �rt�kekre 
�s ki�rja a k�perny�re a kapott eredm�nyeket az eredeti sz�mmal egy�tt. 
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(302,'
    DECLARE 
        rootNumber Number;
        powerNumber Number;
        absoluteNumber Number;
    PROCEDURE counter(szam IN NUMBER, rootNum OUT number, powerNum OUT number, absoluteNum OUT number) IS
    BEGIN
        rootNum := sqrt(abs(szam));
        powerNum := szam*szam;
        absoluteNum := abs(szam);
    END counter;
    BEGIN
        for i in -100..100
        loop
            counter(i, rootNumber, powerNumber, absoluteNumber);
            dbms_output.put_line(i || '' '' || rootNumber || '' '' || powerNumber || '' '' || absoluteNumber);
        end loop;
    END;/');
END;

303. �rjunk t�rolt elj�r�st, amely egy dolgoz�nak a fizet�s�t emeli (hr schema), 
azaz param�terk�nt egy dolgoz� azonos�t�j�t kapja,
egy param�terk�nt kapott sz�zal�kkal megemeli a dolgoz� fizet�s�t, 
majd visszaadja a dolgoz� nev�t, �s az �j fizet�s�nek �rt�k�t.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(303,'
    create or replace PROCEDURE RAISESALARY(
        emp_id HR.employees.EMPLOYEE_ID%type,
        inc_value number,
        giveMeName out varchar2,
        newSalary out varchar2
    ) IS
    BEGIN
        UPDATE employees
        SET salary = salary + salary*(inc_value/100)
        where EMPLOYEE_ID = emp_id
        RETURN employees.first_name,salary INTO giveMeName, newSalary;
    END;/');
END;

304 H�vjuk meg az el�z� t�rolt elj�r�st t�bb dolgoz�ra �gy, hogy a megh�v�s el�tt keress�k ki 
a dolgoz� neve alapj�n a dolgoz� azonos�t�j�t. Pr�b�ljuk ki a fizet�s cs�kkent�st is.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(304,'
    DECLARE
        emp_id number;
        emp_name varchar2(50);
        newSalary number;
    BEGIN
        select employee_id 
        into emp_id 
        from HR.employees
        where first_name = ''Steven'' 
        and last_name = ''King'' ;
        
        RAISESALARY(emp_id, 10, emp_name, newSalary);
        dopl(emp_name || '' '' || newSalary);
    END;/');
END;

305 �rjunk t�rolt f�ggv�nyt, amely param�terk�nt kap egy h�napsorsz�mot, 
�s visszaadja, hogy h�ny olyan megrendel�s van, amelynek az adott h�nap szerepel a megrendel�s�nek a d�tum�ban.
BEGIN
   HDBMS19.MEGOLDAS_FELTOLT(305,'
    CREATE OR REPLACE FUNCTION monthOrder (
        monthNumber out number
    ) RETURN NUMBER IS 
        v_number number;
    BEGIN
        SELECT COUNT(order_id)
        INTO v_number
        FROM orders
        WHERE TO_CHAR(order_date, ''MM'') = monthNumber;
    END;/');
END;

306
H�vjuk meg az el�z� f�ggv�nyt lek�rdez�s seg�ts�g�vel.
BEGIN
    SELECT * FROM orders(monthOrder(1));
END;

307
BEGIN
	dopl(monthOrder(5));
END;/"
	
308.  �rjunk t�rolt elj�r�st, amely param�terk�nt egy customer nev�t kapja �s a k�perny�re list�zza az �gyf�l �ltal rendelt �sszes term�k nev�t (mindegyiket csak egyszer). 
Ha t�bb azonos nev� �gyf�l van, akkor a annyi list�t k�sz�ten, ah�ny ilyen �gyf�l van.
BEGIN
    HDBMS19.megoldas_feltolt(308,
        'CREATE OR REPLACE PROCEDURE allProductFromCust(
            customer_name VARCHAR2
        ) IS
        BEGIN
            FOR i IN
                (SELECT DISTINCT d4.product_name , d1.customer_id
                FROM OE.customers d1
                INNER JOIN OE.orders d2
                ON d1.customer_id = d2.customer_id
                INNER JOIN OE.order_items d3
                ON d2.order_id = d3.order_id
                INNER JOIN OE.product_information d4
                ON d3.product_id = d4.product_id
                WHERE (d1.cust_first_name || '' '' || d1.cust_last_name) = customer_name
                ORDER BY d1.customer_id)
            LOOP
                DOPL(i.customer_id || '' '' || i.product_name);
            END LOOP;
        END;/');
END;

309. H�vjuk meg az el�z� feladat elj�r�s�t.
BEGIN
    HDBMS19.megoldas_feltolt(309,'
        BEGIN
            allProductFromCust(''Constantin Welles'');
        END;/');
END;


