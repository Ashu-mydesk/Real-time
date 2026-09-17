CREATE OR REPLACE TABLE ASHISH.PUBLIC.STAGE_CUSTOMER (
    CUSTOMER_SK           NUMBER,
    CUSTOMER_ID           VARCHAR,
    CURRENT_CDEMO_SK      NUMBER,
    CURRENT_HDEMO_SK      NUMBER,
    CURRENT_ADDR_SK       NUMBER,
    FIRST_SHIPTO_DATE_SK  NUMBER,
    FIRST_SALES_DATE_SK   NUMBER,
    SALUTATION            VARCHAR,
    FIRST_NAME            VARCHAR,
    LAST_NAME             VARCHAR,
    PREFERRED_CUST_FLAG   VARCHAR,
    BIRTH_DAY             NUMBER,
    BIRTH_MONTH           NUMBER,
    BIRTH_YEAR            NUMBER,
    BIRTH_COUNTRY         VARCHAR,
    LOGIN                 VARCHAR,
    EMAIL_ADDRESS         VARCHAR,
    LAST_REVIEW_DATE      VARCHAR,
    LOAD_START_TIME       TIMESTAMP,
    LOAD_END_TIME         TIMESTAMP
);



CREATE OR REPLACE PROCEDURE ASHISH.PUBLIC.SP_LOAD_STAGE_CUSTOMER()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
DECLARE
    START_TIME TIMESTAMP;
    END_TIME TIMESTAMP;
    SOURCE_TABLE_NAME VARCHAR(100);
    TARGET_TABLE_NAME VARCHAR(100);
    Q_DELETE VARCHAR; -- Added explicit declaration here
    /* DIM CUSTOMER STORED PROCEDURE */
    /* CREATED BY : ASHISH */
    /* CREATED DATE : 16-09-2026 */
BEGIN
    /* Capture pipeline execution start time */
    START_TIME := CURRENT_TIMESTAMP();
    SOURCE_TABLE_NAME := 'SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER';
    TARGET_TABLE_NAME := 'ASHISH.PUBLIC.STAGE_CUSTOMER';

    /* Truncate target table before load */
    Q_DELETE := 'TRUNCATE TABLE ' || TARGET_TABLE_NAME;
    EXECUTE IMMEDIATE :Q_DELETE;

    /* Insert data from source */
    INSERT INTO ASHISH.PUBLIC.STAGE_CUSTOMER (
        CUSTOMER_SK,
        CUSTOMER_ID,
        CURRENT_CDEMO_SK,
        CURRENT_HDEMO_SK,
        CURRENT_ADDR_SK,
        FIRST_SHIPTO_DATE_SK,
        FIRST_SALES_DATE_SK,
        SALUTATION,
        FIRST_NAME,
        LAST_NAME,
        PREFERRED_CUST_FLAG,
        BIRTH_DAY,
        BIRTH_MONTH,
        BIRTH_YEAR,
        BIRTH_COUNTRY,
        LOGIN,
        EMAIL_ADDRESS,
        LAST_REVIEW_DATE,
        LOAD_START_TIME,
        LOAD_END_TIME
    )
    SELECT 
        C_CUSTOMER_SK           AS CUSTOMER_SK,
        C_CUSTOMER_ID           AS CUSTOMER_ID,
        C_CURRENT_CDEMO_SK      AS CURRENT_CDEMO_SK,
        C_CURRENT_HDEMO_SK      AS CURRENT_HDEMO_SK,
        C_CURRENT_ADDR_SK       AS CURRENT_ADDR_SK,
        C_FIRST_SHIPTO_DATE_SK  AS FIRST_SHIPTO_DATE_SK,
        C_FIRST_SALES_DATE_SK   AS FIRST_SALES_DATE_SK,
        C_SALUTATION            AS SALUTATION,
        C_FIRST_NAME            AS FIRST_NAME,
        C_LAST_NAME             AS LAST_NAME,
        C_PREFERRED_CUST_FLAG   AS PREFERRED_CUST_FLAG,
        C_BIRTH_DAY             AS BIRTH_DAY,
        C_BIRTH_MONTH           AS BIRTH_MONTH,
        C_BIRTH_YEAR            AS BIRTH_YEAR,
        C_BIRTH_COUNTRY         AS BIRTH_COUNTRY,
        C_LOGIN                 AS LOGIN,
        C_EMAIL_ADDRESS         AS EMAIL_ADDRESS,
        C_LAST_REVIEW_DATE      AS LAST_REVIEW_DATE,
        :START_TIME             AS LOAD_START_TIME,
        CURRENT_TIMESTAMP()     AS LOAD_END_TIME
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
    LIMIT 1000;

    /* Capture completion timestamp */
    END_TIME := CURRENT_TIMESTAMP();

    RETURN 'Data copy has been successfully done!! Start Time: ' || :START_TIME || ' | End Time: ' || :END_TIME;
END;

CALL ASHISH.PUBLIC.SP_LOAD_STAGE_CUSTOMER();

SELECT 
    CUSTOMER_SK,
    FIRST_NAME,
    LAST_NAME,
    LOAD_START_TIME,
    LOAD_END_TIME
FROM ASHISH.PUBLIC.STAGE_CUSTOMER 
LIMIT 10;


=================================================================================


create or replace procedure ASHISH.PUBLIC.SP_LOAD_STAGE_income_band()
returns varchar
language sql
execute as owner
as
declare
start_time timestamp;
end_time timestamp;
source_table varchar;
target_table varchar;
q_delete varchar;
begin
start_time := current_timestamp();
source_table := 'SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.INCOME_BAND';
target_table := 'MYDESK.PUBLIC.INCOME';
q_delete := 'truncate table '  || target_table;
execute immediate :q_delete;
insert into MYDESK.PUBLIC.INCOME
select
IB_INCOME_BAND_SK as INCOME_BAND_SK
,IB_LOWER_BOUND as LOWER_BOUND
,IB_UPPER_BOUND as UPPER_BOUND
,:start_time as start_time
,current_timestamp() as end_time
from SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.INCOME_BAND;

end_time := current_timestamp();

return 'Query executed successfully' || 'start_time ' || :start_time || 'end_time ' || :end_time;
end;


call ASHISH.PUBLIC.SP_LOAD_STAGE_income_band();

select * from MYDESK.PUBLIC.INCOME;
