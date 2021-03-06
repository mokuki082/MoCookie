/* Use mc_admin to run this file */

CREATE OR REPLACE FUNCTION Test.AUT_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    SELECT Blockchain.addAUT('aaa123') AND
           Blockchain.addAUT('bbb123') AND
           Blockchain.addAUT('ccc123') AND
           Blockchain.addAUT('ddd123') AND
           Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION Test.AUT_add_after_del() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT Blockchain.addRUT('aaa123') AND
           Blockchain.commitBlock() AND
           NOT Blockchain.addAUT('aaa123') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
