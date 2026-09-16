use database ashish;
create or replace table dim_customers(
 CUSTOMER_SK	NUMBER(38,0)
,CUSTOMER_ID	VARCHAR(16)
,CURRENT_CDEMO_SK	NUMBER(38,0)
,CURRENT_HDEMO_SK	NUMBER(38,0)
,CURRENT_ADDR_SK	NUMBER(38,0)
,FIRST_SHIPTO_DATE_SK	NUMBER(38,0)
,FIRST_SALES_DATE_SK	NUMBER(38,0)
,SALUTATION	VARCHAR(10)
,FIRST_NAME	VARCHAR(20)
,LAST_NAME	VARCHAR(30)
,PREFERRED_CUST_FLAG	VARCHAR(1)
,BIRTH_DAY	NUMBER(38,0)
,BIRTH_MONTH	NUMBER(38,0)
,BIRTH_YEAR	NUMBER(38,0)
,BIRTH_COUNTRY	VARCHAR(20)
,LOGIN	VARCHAR(13)
,EMAIL_ADDRESS	VARCHAR(50)
,LAST_REVIEW_DATE	VARCHAR(10)
,load_start_time       TIMESTAMP_NTZ
,load_end_time         TIMESTAMP_NTZ
);
DESC TABLE CUSTOMER;


desc table SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER;

CREATE OR REPLACE PROCEDURE ashish.public.sp_load_customers_with_timestamps(row_limit INT)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    v_start_time TIMESTAMP_NTZ;
    v_end_time   TIMESTAMP_NTZ;
    v_rows_count INT DEFAULT 0;
BEGIN
    -- 1. Capture the start time
    v_start_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    -- 2. Insert with column renaming and the captured start time
    INSERT INTO ashish.public.dim_customers(
CUSTOMER_SK
,CUSTOMER_ID
,CURRENT_CDEMO_SK
,CURRENT_HDEMO_SK
,CURRENT_ADDR_SK
,FIRST_SHIPTO_DATE_SK
,FIRST_SALES_DATE_SK
,SALUTATION
,FIRST_NAME
,LAST_NAME
,PREFERRED_CUST_FLAG
,BIRTH_DAY
,BIRTH_MONTH
,BIRTH_YEAR
,BIRTH_COUNTRY
,LOGIN
,EMAIL_ADDRESS
,LAST_REVIEW_DATE
,load_start_time
,load_end_time
    )
    SELECT 
    C_CUSTOMER_SK AS CUSTOMER_SK
,C_CUSTOMER_ID AS CUSTOMER_ID
,C_CURRENT_CDEMO_SK AS  CURRENT_CDEMO_SK
,C_CURRENT_HDEMO_SK AS CURRENT_HDEMO_SK
,C_CURRENT_ADDR_SK AS CURRENT_ADDR_SK
,C_FIRST_SHIPTO_DATE_SK AS FIRST_SHIPTO_DATE_SK
,C_FIRST_SALES_DATE_SK AS FIRST_SALES_DATE_SK
,C_SALUTATION AS SALUTATION
,C_FIRST_NAME AS FIRST_NAME
,C_LAST_NAME AS LAST_NAME
,C_PREFERRED_CUST_FLAG AS PREFERRED_CUST_FLAG
,C_BIRTH_DAY AS BIRTH_DAY
,C_BIRTH_MONTH AS BIRTH_MONTH
,C_BIRTH_YEAR AS BIRTH_YEAR
,C_BIRTH_COUNTRY AS BIRTH_COUNTRY
,C_LOGIN AS LOGIN
,C_EMAIL_ADDRESS AS EMAIL_ADDRESS
,C_LAST_REVIEW_DATE AS LAST_REVIEW_DATE
,:v_start_time  AS load_start_time
, NULL                    AS load_end_time
    FROM snowflake_sample_data.tpcds_sf10tcl.customer
    LIMIT :row_limit;

    -- Get row count from the insert
    SELECT "number of rows inserted" INTO :v_rows_count 
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 3. Capture the end time after load completes
    v_end_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    -- 4. Update the batch with the finalized completion timestamp
    UPDATE ashish.public.dim_customers
    SET load_end_time = :v_end_time
    WHERE load_start_time = :v_start_time 
      AND load_end_time IS NULL;

    RETURN 'Successfully loaded ' || :v_rows_count || ' rows. Start: ' || :v_start_time || ' | End: ' || :v_end_time;
END;


CALL ashish.public.sp_load_customers_with_timestamps(10);


select * from dim_customers;





CREATE OR REPLACE PROCEDURE ashish.public.sp_load_all_customers()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    v_start_time TIMESTAMP_NTZ;
    v_end_time   TIMESTAMP_NTZ;
    v_rows_count INT DEFAULT 0;
BEGIN
    -- 1. Track start time
    v_start_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    -- 2. Bulk insert all rows (No LIMIT clause)
    INSERT INTO ashish.public.dim_customers (
        customer_sk,
        customer_id,
        current_cdemo_sk,
        current_hdemo_sk,
        current_addr_sk,
        first_shipto_date_sk,
        first_sales_date_sk,
        salutation,
        first_name,
        last_name,
        preferred_cust_flag,
        birth_day,
        birth_month,
        birth_year,
        birth_country,
        login,
        email_address,
        last_review_date,
        load_start_time,
        load_end_time
    )
    SELECT 
        c_customer_sk,
        c_customer_id,
        c_current_cdemo_sk,
        c_current_hdemo_sk,
        c_current_addr_sk,
        c_first_shipto_date_sk,
        c_first_sales_date_sk,
        c_salutation,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_birth_country,
        c_login,
        c_email_address,
        c_last_review_date,
        :v_start_time,
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
    FROM snowflake_sample_data.tpcds_sf10tcl.customer;

    -- 3. Capture row count
    SELECT "number of rows inserted" INTO :v_rows_count 
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 4. Track completion time
    v_end_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    RETURN 'Full load complete: ' || :v_rows_count || ' rows inserted. ' ||
           'Started at: ' || :v_start_time || ' | Completed at: ' || :v_end_time;
END;



CALL ashish.public.sp_load_all_customers();


select * from dim_customers;