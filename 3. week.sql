301 Írjunk blokkot, amelyben deklarálunk egy függvényt, amely paraméterként egy ügyfél azonosítóját és dátumot kap, és visszaadja, hogy az ügyfélnek az adott dátum után hány megrendelése volt. 
A blokk minden 'T' betûvel kezdõdõ nevû ügyfélre hívja meg a függvényt, a dátum paraméterbe a függvény a 2005. 01.01-et kapjon
és írja ki az ügyfél nevét, és a darabszámot a képernyõre.
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

302 Írjunk blokkot, amelyben deklarálunk egy eljárást, amely paraméterként kap egy számot, 
és visszaadja (kimenõ paraméterben) annak a gyökét, a négyzetét és az abszolút értékét. 
A blokk meghívja az eljárást -100 és 100 között minden egész értékekre 
és kiírja a képernyõre a kapott eredményeket az eredeti számmal együtt. 
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

303. Írjunk tárolt eljárást, amely egy dolgozónak a fizetését emeli (hr schema), 
azaz paraméterként egy dolgozó azonosítóját kapja,
egy paraméterként kapott százalékkal megemeli a dolgozó fizetését, 
majd visszaadja a dolgozó nevét, és az új fizetésének értékét.
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

304 Hívjuk meg az elõzõ tárolt eljárást több dolgozóra úgy, hogy a meghívás elõtt keressük ki 
a dolgozó neve alapján a dolgozó azonosítóját. Próbáljuk ki a fizetés csökkentést is.
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

305 Írjunk tárolt függvényt, amely paraméterként kap egy hónapsorszámot, 
és visszaadja, hogy hány olyan megrendelés van, amelynek az adott hónap szerepel a megrendelésének a dátumában.
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
Hívjuk meg az elõzõ függvényt lekérdezés segítségével.
BEGIN
    SELECT * FROM orders(monthOrder(1));
END;

307
BEGIN
	dopl(monthOrder(5));
END;/"
	
308.  Írjunk tárolt eljárást, amely paraméterként egy customer nevét kapja és a képernyõre listázza az ügyfél által rendelt összes termék nevét (mindegyiket csak egyszer). 
Ha több azonos nevû ügyfél van, akkor a annyi listát készíten, ahány ilyen ügyfél van.
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

309. Hívjuk meg az elõzõ feladat eljárását.
BEGIN
    HDBMS19.megoldas_feltolt(309,'
        BEGIN
            allProductFromCust(''Constantin Welles'');
        END;/');
END;


