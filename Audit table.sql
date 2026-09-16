/*Step 1: Create the Dedicated Audit Table */

CREATE OR REPLACE TABLE ashish.public.etl_audit_log (
    log_id          NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    pipeline_name   VARCHAR(100),
    source_table    VARCHAR(150),
    target_table    VARCHAR(150),
    rows_inserted   NUMBER,
    status          VARCHAR(20),
    error_message   VARCHAR,
    start_time      TIMESTAMP_NTZ,
    end_time        TIMESTAMP_NTZ,
    executed_by     VARCHAR(50)
);

/*   Step 2: Stored Procedure with TRY...CATCH Audit Logging   */

CREATE OR REPLACE PROCEDURE ashish.public.sp_load_customers_with_audit()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    v_start_time    TIMESTAMP_NTZ;
    v_end_time      TIMESTAMP_NTZ;
    v_rows_inserted INT DEFAULT 0;
    v_status        VARCHAR(20);
    v_error         VARCHAR DEFAULT NULL;
BEGIN
    -- 1. Initialize execution metadata
    v_start_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    -- 2. Execute target table load
    INSERT INTO ashish.public.dim_customers (
        customer_sk,
        customer_id,
        first_name,
        last_name,
        email_address,
        load_start_time,
        load_end_time
    )
    SELECT 
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address,
        :v_start_time,
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
    FROM snowflake_sample_data.tpcds_sf10tcl.customer
    LIMIT 1000;

    -- 3. Capture row metrics
    SELECT "number of rows inserted" INTO :v_rows_inserted 
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    v_status   := 'SUCCESS';
    v_end_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;

    -- 4. Record success to audit table
    INSERT INTO ashish.public.etl_audit_log (
        pipeline_name,
        source_table,
        target_table,
        rows_inserted,
        status,
        error_message,
        start_time,
        end_time,
        executed_by
    )
    VALUES (
        'sp_load_customers_with_audit',
        'SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER',
        'ASHISH.PUBLIC.DIM_CUSTOMERS',
        :v_rows_inserted,
        :v_status,
        NULL,
        :v_start_time,
        :v_end_time,
        CURRENT_USER()
    );

    RETURN 'Loaded ' || :v_rows_inserted || ' rows successfully. Audit logged.';

EXCEPTION
    WHEN OTHER THEN
        v_end_time := CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ;
        v_status   := 'FAILED';
        v_error    := SQLERRM;

        -- 5. Record failure to audit table
        INSERT INTO ashish.public.etl_audit_log (
            pipeline_name,
            source_table,
            target_table,
            rows_inserted,
            status,
            error_message,
            start_time,
            end_time,
            executed_by
        )
        VALUES (
            'sp_load_customers_with_audit',
            'SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER',
            'ASHISH.PUBLIC.DIM_CUSTOMERS',
            0,
            :v_status,
            :v_error,
            :v_start_time,
            :v_end_time,
            CURRENT_USER()
        );

        -- Re-raise error to alert callers
        RAISE;
END;
