CREATE OR REPLACE FUNCTION Test.AUT_duplicate_user() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    SELECT Blockchain.addAUT('aaa123') AND
           NOT Blockchain.addAUT('aaa123') AND
           Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
