/*
Test files should be named with the format: "test_[name].sql".

For each test case, create a function like below:

CREATE OR REPLACE FUNCTION Test.[TESTCASE_NAME]() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    [... STATEMENTS ...]
    [STORE YOUR ASSERTION RESULT AS A BOOLEAN INTO result]
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
*/

BEGIN TRANSACTION;
DROP SCHEMA IF EXISTS Test CASCADE;
CREATE SCHEMA IF NOT EXISTS Test;
