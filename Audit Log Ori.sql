-- Step 1 Table: Base Stage for NATION
CREATE OR REPLACE TABLE MYDESK.PUBLIC.STAGE_NATION (
    NATIONKEY   NUMBER,
    NAME        VARCHAR(25),
    REGIONKEY   NUMBER,
    COMMENT     VARCHAR(152)
);

-- Step 2 Table: Derived Stage with GMT Timestamp
CREATE OR REPLACE TABLE MYDESK.PUBLIC.STAGE_NATION_DERIVED (
    INSERT_GMT_TIMESTAMP  TIMESTAMP,
    NATIONKEY             NUMBER,
    NAME                  VARCHAR(25),
    REGIONKEY             NUMBER
);


select * from  MYDESK.PUBLIC.STAGE_NATION_DERIVED;
CREATE OR REPLACE TABLE MYDESK.PUBLIC.EDW_AUDIT_LOG (
    SOURCE_TABLE_NAME    VARCHAR(200),
    TARGET_TABLE_NAME    VARCHAR(200),
    SOURCE_RECORD_COUNT  NUMBER,
    TARGET_RECORD_COUNT  NUMBER,
    START_TIME           TIMESTAMP,
    END_TIME             TIMESTAMP
);



CREATE OR REPLACE PROCEDURE MYDESK.PUBLIC.SP_LOAD_NATION_TWO_STEP_AUDIT(
    TABLE_NAME VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
DECLARE
    V_START_TIME TIMESTAMP;
    V_END_TIME TIMESTAMP;
    V_SOURCE_TABLE_NAME VARCHAR;
    V_TARGET_TABLE_NAME VARCHAR;
    V_STAGE_SOURCE_TABLE_NAME VARCHAR;
    V_SOURCE_RECORD_COUNT NUMBER DEFAULT 0;
    V_TARGET_RECORD_COUNT NUMBER DEFAULT 0;
    Q_STAGE_INSERT VARCHAR;
    Q_DERIVED_DELETE VARCHAR;
    Q_DERIVED_INSERT VARCHAR;
BEGIN
    ---------------------------------------------------------------------------
    -- STEP 1: LOAD INTO STAGE_NATION
    ---------------------------------------------------------------------------
    V_START_TIME := CURRENT_TIMESTAMP();
    V_SOURCE_TABLE_NAME := 'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.' || :TABLE_NAME;
    V_TARGET_TABLE_NAME := 'MYDESK.PUBLIC.STAGE_' || :TABLE_NAME;

    -- Pre-load record count
    SELECT COUNT(1) INTO :V_SOURCE_RECORD_COUNT 
    FROM IDENTIFIER(:V_SOURCE_TABLE_NAME);

    -- Truncate base staging table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || :V_TARGET_TABLE_NAME;

    -- Dynamic insert into STAGE_NATION
    Q_STAGE_INSERT := 'INSERT INTO ' || :V_TARGET_TABLE_NAME || '
                       SELECT 
                           N_NATIONKEY AS NATIONKEY,
                           N_NAME AS NAME,
                           N_REGIONKEY AS REGIONKEY,
                           N_COMMENT AS COMMENT
                       FROM ' || :V_SOURCE_TABLE_NAME;
    EXECUTE IMMEDIATE :Q_STAGE_INSERT;

    -- Post-load record count
    SELECT COUNT(1) INTO :V_TARGET_RECORD_COUNT 
    FROM IDENTIFIER(:V_TARGET_TABLE_NAME);

    V_END_TIME := CURRENT_TIMESTAMP();

    -- Write Step 1 Audit Details
    INSERT INTO MYDESK.PUBLIC.EDW_AUDIT_LOG (
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        SOURCE_RECORD_COUNT,
        TARGET_RECORD_COUNT,
        START_TIME,
        END_TIME
    ) 
    VALUES (
        :V_SOURCE_TABLE_NAME,
        :V_TARGET_TABLE_NAME,
        :V_SOURCE_RECORD_COUNT,
        :V_TARGET_RECORD_COUNT,
        :V_START_TIME,
        :V_END_TIME
    );

    ---------------------------------------------------------------------------
    -- STEP 2: LOAD INTO STAGE_NATION_DERIVED
    ---------------------------------------------------------------------------
    V_START_TIME := CURRENT_TIMESTAMP();
    V_STAGE_SOURCE_TABLE_NAME := 'MYDESK.PUBLIC.STAGE_' || :TABLE_NAME;
    V_TARGET_TABLE_NAME       := 'MYDESK.PUBLIC.STAGE_' || :TABLE_NAME || '_DERIVED';

    -- Pre-load record count for step 2
    SELECT COUNT(1) INTO :V_SOURCE_RECORD_COUNT 
    FROM IDENTIFIER(:V_STAGE_SOURCE_TABLE_NAME);

    -- Truncate the derived table
    Q_DERIVED_DELETE := 'TRUNCATE TABLE ' || :V_TARGET_TABLE_NAME;
    EXECUTE IMMEDIATE :Q_DERIVED_DELETE;

    -- Load derived table with GMT timestamp
    Q_DERIVED_INSERT := 'INSERT INTO ' || :V_TARGET_TABLE_NAME || '
                         SELECT 
                             CURRENT_TIMESTAMP() AS INSERT_GMT_TIMESTAMP,
                             NATIONKEY,
                             NAME,
                             REGIONKEY
                         FROM ' || :V_STAGE_SOURCE_TABLE_NAME;
    EXECUTE IMMEDIATE :Q_DERIVED_INSERT;

    -- Post-load target count
    SELECT COUNT(1) INTO :V_TARGET_RECORD_COUNT 
    FROM IDENTIFIER(:V_TARGET_TABLE_NAME);

    V_END_TIME := CURRENT_TIMESTAMP();

    -- Write Step 2 Audit Details
    INSERT INTO MYDESK.PUBLIC.EDW_AUDIT_LOG (
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        SOURCE_RECORD_COUNT,
        TARGET_RECORD_COUNT,
        START_TIME,
        END_TIME
    ) 
    VALUES (
        :V_STAGE_SOURCE_TABLE_NAME,
        :V_TARGET_TABLE_NAME,
        :V_SOURCE_RECORD_COUNT,
        :V_TARGET_RECORD_COUNT,
        :V_START_TIME,
        :V_END_TIME
    );

    RETURN 'Completed two-step load and audit logging for table ' || :TABLE_NAME;
END;



CALL MYDESK.PUBLIC.SP_LOAD_NATION_TWO_STEP_AUDIT('NATION');


SELECT * FROM MYDESK.PUBLIC.EDW_AUDIT_LOG ORDER BY START_TIME DESC;