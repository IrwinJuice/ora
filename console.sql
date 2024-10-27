CREATE TYPE t_tf_row AS OBJECT
(
    id          NUMBER,
    description VARCHAR2(50)
);

CREATE TYPE t_tf_tab IS TABLE OF t_tf_row;

CREATE table Some
(
    line NUMBER
);


CREATE OR REPLACE FUNCTION get_tab_ptf(p_rows IN NUMBER) RETURN t_tf_tab PIPELINED AS
BEGIN
    FOR i IN 1 .. p_rows
        LOOP
            PIPE ROW (t_tf_row(i, 'Description for ' || i));
        END LOOP;

    RETURN;
END;



SELECT *
FROM TABLE (get_tab_ptf(1000000))
ORDER BY id DESC;

----------------------------

create table PROD_TABLE
(
    IDI  number,
    NAME VARCHAR2(20 CHAR)
);

create table DEV_TABLE
(
    IDI  number,
    NAME VARCHAR2(20 CHAR)
);

-- TRUNCATE TABLE PROD_TABLE;
TRUNCATE TABLE DEV_TABLE;

insert into PROD_TABLE (IDI, NAME)
VALUES (1, 'Max');
insert into PROD_TABLE (IDI, NAME)
VALUES (2, 'Hellen_PROD');
insert into PROD_TABLE (IDI, NAME)
VALUES (4, 'Bublik');

insert into DEV_TABLE (IDI, NAME)
VALUES (1, 'Max');
insert into DEV_TABLE (IDI, NAME)
VALUES (2, 'Hellen_DEV');
insert into DEV_TABLE (IDI, NAME)
VALUES (3, 'Irwin');

create or replace PROCEDURE testProc
AS
BEGIN
    MERGE INTO PROD_TABLE pt
    USING (with dev as
                    (select *
                     from DEV_TABLE)
           select COALESCE(dev.idi, t.idi) as idi,
                  dev.name,
                  CASE
                      WHEN dev.idi IS NULL THEN 'Y'
                      ELSE 'N'
                      END                     match_flag
           FROM dev
                    FULL JOIN PROD_TABLE t ON t.idi = dev.idi) tmp
    ON (pt.idi = tmp.idi)
    WHEN MATCHED THEN
        UPDATE SET pt.name = tmp.name
        DELETE WHERE match_flag = 'Y'
    WHEN NOT MATCHED THEN
        INSERT (idi, name)
        VALUES (tmp.idi, tmp.name);
END testProc;

select *
from PROD_TABLE;
select *
from DEV_TABLE;

DECLARE

BEGIN
    testProc();
END;
/

create global temporary table tmp_id_table
(
    id number
)
    on commit delete rows;

create or replace PROCEDURE testProc2(idi_list in varchar2) AS
BEGIN
    insert into tmp_id_table
    select to_number(trim(n)) id
    from (SELECT REGEXP_SUBSTR(idi_list, '[^,]+', 1, level) n
          FROM dual
          CONNECT BY REGEXP_SUBSTR(idi_list, '[^,]+', 1, level) IS NOT NULL);


    update DEV_TABLE
    set name='TEST_NAME'
    where idi in (select * from tmp_id_table);

    --     update DEV_TABLE
--     set name='TEST_NAME'
--     where idi in (SELECT to_number(REGEXP_SUBSTR(idi_list, '[^,]+', 1, level))
--                   FROM dual
--                   CONNECT BY REGEXP_SUBSTR(idi_list, '[^,]+', 1, level) IS NOT NULL);
END testProc2;

DECLARE
BEGIN
    testProc2('1,2,3');
END;
/

select *
from user_objects
where object_name = 'testProc2';
select *
from user_objects
where object_name = 'MyType';
select *
from all_errors
where upper(name) = upper('testProc2');
select *
from all_errors
where upper(name) = upper('MyType');