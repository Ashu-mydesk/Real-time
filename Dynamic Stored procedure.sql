CREATE OR REPLACE PROCEDURE ashish.public.dynamic_data_load_sp(input_table_name VARCHAR(100))
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
DECLARE
    v_query VARCHAR(500);
BEGIN
    -- Construct dynamic CTAS query
    v_query := 'CREATE OR REPLACE TABLE ashish.public.' || :input_table_name || 
               ' AS SELECT * FROM snowflake_sample_data.tpcds_sf10tcl.' || :input_table_name;

    -- Execute dynamically
    EXECUTE IMMEDIATE :v_query;

    RETURN 'Data copy has been successfully done for table: ' || :input_table_name;
END;


CALL ashish.public.dynamic_data_load_sp('CUSTOMER');

SELECT * FROM ashish.public.customer;